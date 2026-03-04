package commands

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/kombifyio/stackkits/internal/config"
	"github.com/kombifyio/stackkits/internal/cue"
	"github.com/kombifyio/stackkits/internal/docker"
	"github.com/kombifyio/stackkits/internal/ssh"
	"github.com/kombifyio/stackkits/internal/tofu"
	"github.com/kombifyio/stackkits/pkg/models"
	"github.com/spf13/cobra"
)

var (
	prepareHost       string
	prepareUser       string
	prepareKey        string
	prepareDryRun     bool
	prepareSkipDocker bool
	prepareSkipTofu   bool
	prepareAutoFix    bool
)

var prepareCmd = &cobra.Command{
	Use:     "prepare",
	Aliases: []string{"prep"},
	Short:   "Prepare a system for StackKit deployment",
	Long: `Prepare a bare system for StackKit deployment AND validate/adjust the spec file.

This command:
  1. Checks/installs Docker
  2. Checks/installs OpenTofu
  3. Validates the spec file against CUE schemas
  4. Checks hardware requirements
  5. Applies auto-fixes for common issues

Examples:
  stackkit prepare                      Prepare local system
  stackkit prepare --spec ./spec.yaml   Prepare and validate spec
  stackkit prepare --host 192.168.1.100 Prepare remote system
  stackkit prepare --dry-run            Show what would be done`,
	RunE: runPrepare,
}

func init() {
	prepareCmd.Flags().StringVar(&prepareHost, "host", "localhost", "Target host IP/hostname")
	prepareCmd.Flags().StringVar(&prepareUser, "user", "", "SSH username")
	prepareCmd.Flags().StringVar(&prepareKey, "key", "", "SSH private key path")
	prepareCmd.Flags().BoolVar(&prepareDryRun, "dry-run", false, "Show what would be done")
	prepareCmd.Flags().BoolVar(&prepareSkipDocker, "skip-docker", false, "Skip Docker installation check")
	prepareCmd.Flags().BoolVar(&prepareSkipTofu, "skip-tofu", false, "Skip OpenTofu installation check")
	prepareCmd.Flags().BoolVar(&prepareAutoFix, "auto-fix", true, "Auto-correct fixable issues")
}

func runPrepare(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	wd := getWorkDir()
	isRemote := prepareHost != "localhost" && prepareHost != ""

	printInfo("Preparing system for StackKit deployment")

	// Load spec if provided
	loader := config.NewLoader(wd)
	spec, err := loader.LoadStackSpec(specFile)
	if err != nil && !os.IsNotExist(err) {
		printWarning("Could not load spec file: %v", err)
	}

	// Validate spec if loaded
	if spec != nil {
		printInfo("Validating spec file...")
		validator := cue.NewValidator(wd)
		result, err := validator.ValidateSpec(spec)
		if err != nil {
			return fmt.Errorf("validation error: %w", err)
		}

		if !result.Valid {
			printError("Spec validation failed:")
			for _, e := range result.Errors {
				fmt.Printf("  • %s: %s\n", red(e.Path), e.Message)
			}
			return fmt.Errorf("spec validation failed with %d errors", len(result.Errors))
		}

		printSuccess("Spec file is valid")

		for _, w := range result.Warnings {
			printWarning("%s: %s", w.Path, w.Message)
		}
	}

	if isRemote {
		return prepareRemoteSystem(ctx, spec)
	}

	return prepareLocalSystem(ctx, spec)
}

func prepareLocalSystem(ctx context.Context, spec *models.StackSpec) error {
	// Check Docker
	if !prepareSkipDocker {
		printInfo("Checking Docker installation...")
		dockerClient := docker.NewClient()

		if !dockerClient.IsInstalled() {
			if prepareDryRun {
				printWarning("Docker not installed - would install")
			} else {
				printInfo("Installing Docker...")
				if err := installDockerLocal(ctx); err != nil {
					return fmt.Errorf("failed to install Docker: %w", err)
				}
				printSuccess("Docker installed successfully")
			}
		} else {
			version, err := dockerClient.Version(ctx)
			if err != nil {
				printWarning("Could not get Docker version: %v", err)
			} else {
				printSuccess("Docker %s installed", version)
			}

			if !dockerClient.IsRunning(ctx) {
				if prepareDryRun {
					printWarning("Docker daemon is not running - would attempt to start")
				} else {
					printInfo("Docker daemon is not running, starting...")
					if err := startDockerDaemon(ctx); err != nil {
						return fmt.Errorf("Docker is installed but won't start: %w", err)
					}
					printSuccess("Docker daemon started")
				}
			} else {
				printSuccess("Docker daemon is running")
			}
		}
	}

	// Check OpenTofu
	if !prepareSkipTofu {
		printInfo("Checking OpenTofu installation...")
		tofuExec := tofu.NewExecutor()

		if !tofuExec.IsInstalled() {
			if prepareDryRun {
				printWarning("OpenTofu not installed - would install")
			} else {
				printInfo("Installing OpenTofu...")
				if err := installTofuLocal(ctx); err != nil {
					return fmt.Errorf("failed to install OpenTofu: %w", err)
				}
				// Verify installation actually worked
				tofuExec = tofu.NewExecutor()
				if !tofuExec.IsInstalled() {
					return fmt.Errorf("OpenTofu installation completed but binary not found in PATH")
				}
				version, err := tofuExec.Version(ctx)
				if err != nil {
					printSuccess("OpenTofu installed successfully")
				} else {
					printSuccess("OpenTofu %s installed successfully", version)
				}
			}
		} else {
			version, err := tofuExec.Version(ctx)
			if err != nil {
				printWarning("Could not get OpenTofu version: %v", err)
			} else {
				printSuccess("OpenTofu %s installed", version)
			}
		}
	}

	// Check system resources
	printInfo("Checking system resources...")
	checkLocalResources(spec)

	if prepareDryRun {
		printInfo("Dry run complete - no changes made")
	} else {
		printSuccess("System is ready for StackKit deployment")
	}

	return nil
}

func prepareRemoteSystem(ctx context.Context, spec *models.StackSpec) error {
	printInfo("Preparing remote host: %s", prepareHost)

	// Set SSH options
	opts := []ssh.ClientOption{
		ssh.WithHost(prepareHost),
	}
	if prepareUser != "" {
		opts = append(opts, ssh.WithUser(prepareUser))
	}
	if prepareKey != "" {
		opts = append(opts, ssh.WithKeyPath(prepareKey))
	}

	// Connect
	sshClient := ssh.NewClient(opts...)
	if err := sshClient.Connect(); err != nil {
		return fmt.Errorf("failed to connect to %s: %w", prepareHost, err)
	}
	defer func() { _ = sshClient.Close() }()

	printSuccess("Connected to %s", prepareHost)

	// Get system info
	printInfo("Gathering system information...")
	sysInfo, err := sshClient.GetSystemInfo(ctx)
	if err != nil {
		printWarning("Could not get full system info: %v", err)
	} else {
		printSuccess("OS: %s %s (%s)", sysInfo.OS, sysInfo.OSVersion, sysInfo.Arch)
		printSuccess("CPU: %d cores, RAM: %d MB, Disk: %d GB free",
			sysInfo.CPUCores, sysInfo.MemoryMB, sysInfo.DiskGB)
	}

	// Check Docker
	if err := checkRemoteDocker(ctx, sshClient, sysInfo); err != nil {
		return err
	}

	// Check OpenTofu
	if err := checkRemoteTofu(ctx, sshClient, sysInfo); err != nil {
		return err
	}

	// Check ports
	if spec != nil {
		printInfo("Checking required ports...")
		requiredPorts := []int{80, 443}
		for _, port := range requiredPorts {
			if sshClient.CheckPort(ctx, port) {
				printSuccess("Port %d is available", port)
			} else {
				printWarning("Port %d is in use", port)
			}
		}
	}

	if prepareDryRun {
		printInfo("Dry run complete - no changes made")
	} else {
		printSuccess("Remote system is ready for StackKit deployment")
	}

	return nil
}

func checkRemoteDocker(ctx context.Context, sshClient *ssh.Client, sysInfo *models.SystemInfo) error {
	if prepareSkipDocker {
		return nil
	}
	if sysInfo.DockerVersion != "" {
		printSuccess("Docker %s installed", sysInfo.DockerVersion)
		return nil
	}
	if prepareDryRun {
		printWarning("Docker not installed - would install")
		return nil
	}
	printInfo("Installing Docker...")
	if err := installDockerRemote(ctx, sshClient, sysInfo.OS); err != nil {
		return fmt.Errorf("failed to install Docker: %w", err)
	}
	printSuccess("Docker installed successfully")
	return nil
}

func checkRemoteTofu(ctx context.Context, sshClient *ssh.Client, sysInfo *models.SystemInfo) error {
	if prepareSkipTofu {
		return nil
	}
	if sysInfo.TofuVersion != "" {
		printSuccess("OpenTofu %s installed", sysInfo.TofuVersion)
		return nil
	}
	if prepareDryRun {
		printWarning("OpenTofu not installed - would install")
		return nil
	}
	printInfo("Installing OpenTofu...")
	if err := installTofuRemote(ctx, sshClient); err != nil {
		return fmt.Errorf("failed to install OpenTofu: %w", err)
	}
	printSuccess("OpenTofu installed successfully")
	return nil
}

func checkLocalResources(spec *models.StackSpec) {
	// CPU check
	numCPU := runtime.NumCPU()
	printSuccess("CPU: %d cores", numCPU)

	// Memory check — use runtime.MemStats for Go-accessible info,
	// then read system total from OS-specific /proc/meminfo on Linux.
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	sysMB := m.Sys / 1024 / 1024
	if sysMB > 0 {
		printSuccess("Go runtime memory: %d MB allocated", sysMB)
	}

	// Try reading system total memory (Linux)
	if data, err := os.ReadFile("/proc/meminfo"); err == nil {
		var totalKB uint64
		for _, line := range strings.Split(string(data), "\n") {
			if strings.HasPrefix(line, "MemTotal:") {
				_, _ = fmt.Sscanf(line, "MemTotal: %d kB", &totalKB)
				break
			}
		}
		if totalKB > 0 {
			totalGB := float64(totalKB) / 1024 / 1024
			printSuccess("System memory: %.1f GB", totalGB)
			if totalGB < 2.0 {
				printWarning("Low memory — some services may not start")
			}
		} else {
			printInfo("System memory: could not parse /proc/meminfo")
		}
	} else {
		// Windows/macOS — no /proc/meminfo available
		printInfo("System memory: auto-detection not available on this OS (check manually)")
	}
}

func startDockerDaemon(ctx context.Context) error {
	isSystemd := false
	if _, err := os.Stat("/run/systemd/system"); err == nil {
		isSystemd = true
	}

	if isSystemd {
		// Ensure containerd is running (Docker depends on it)
		containerdEnable := exec.Command("systemctl", "enable", "containerd")
		containerdEnable.Run() //nolint:errcheck // best-effort
		containerdStart := exec.Command("systemctl", "start", "containerd")
		containerdStart.Stdout = os.Stdout
		containerdStart.Stderr = os.Stderr
		containerdStart.Run() //nolint:errcheck // Docker may bundle containerd

		// Enable Docker so it starts on reboot
		enableCmd := exec.Command("systemctl", "enable", "docker")
		enableCmd.Run() //nolint:errcheck // best-effort, start is what matters

		// Start Docker
		startCmd := exec.Command("systemctl", "start", "docker")
		startCmd.Stdout = os.Stdout
		startCmd.Stderr = os.Stderr
		if err := startCmd.Run(); err != nil {
			return fmt.Errorf("systemctl start docker failed: %w", err)
		}
	} else {
		cmd := exec.Command("service", "docker", "start")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("service docker start failed: %w", err)
		}
	}

	// Wait for Docker to become ready (up to 60 seconds — fresh installs can be slow)
	dockerClient := docker.NewClient()
	maxWait := 60
	for i := 0; i < maxWait/2; i++ {
		if dockerClient.IsRunning(ctx) {
			return nil
		}
		time.Sleep(2 * time.Second)
	}

	// If still not ready, check journald for clues
	if isSystemd {
		printWarning("Docker not ready after %ds — checking logs...", maxWait)
		logCmd := exec.Command("journalctl", "-u", "docker", "--no-pager", "-n", "10")
		logCmd.Stdout = os.Stdout
		logCmd.Stderr = os.Stderr
		logCmd.Run() //nolint:errcheck
	}

	return fmt.Errorf("Docker daemon did not become ready within %d seconds", maxWait)
}

func installDockerLocal(ctx context.Context) error {
	cmd := exec.Command("sh", "-c", "curl -fsSL https://get.docker.com | sh")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return err
	}
	// Enable and start Docker daemon — this must succeed for deployment to work
	if err := startDockerDaemon(ctx); err != nil {
		return fmt.Errorf("Docker installed but failed to start: %w", err)
	}
	return nil
}

func installTofuLocal(ctx context.Context) error {
	// Try the official installer first (deb → rpm → standalone binary fallback)
	script := `
set -e
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
chmod +x /tmp/install-opentofu.sh
/tmp/install-opentofu.sh --install-method deb 2>/dev/null || \
  /tmp/install-opentofu.sh --install-method rpm 2>/dev/null || \
  /tmp/install-opentofu.sh --install-method standalone 2>/dev/null
rm -f /tmp/install-opentofu.sh
`
	cmd := exec.Command("sh", "-c", script)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		// Fallback: direct binary download
		printWarning("Package install failed, trying direct binary download...")
		return installTofuBinary(ctx)
	}
	return nil
}

func installTofuBinary(ctx context.Context) error {
	arch := runtime.GOARCH
	goos := runtime.GOOS
	script := fmt.Sprintf(`
set -e
TOFU_VERSION=$(curl -sSL https://api.github.com/repos/opentofu/opentofu/releases/latest | grep '"tag_name"' | head -1 | sed -E 's/.*"v([^"]+)".*/\1/')
curl -sSL "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_%s_%s.tar.gz" -o /tmp/tofu.tar.gz
tar xzf /tmp/tofu.tar.gz -C /tmp tofu
install -m 755 /tmp/tofu /usr/local/bin/tofu
rm -f /tmp/tofu.tar.gz /tmp/tofu
`, goos, arch)
	cmd := exec.Command("sh", "-c", script)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func installDockerRemote(ctx context.Context, client *ssh.Client, osType string) error {
	var installCmd string

	switch osType {
	case "ubuntu", "debian":
		installCmd = `
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
`
	case "rocky", "centos", "rhel", "fedora":
		installCmd = `
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker
`
	default:
		return fmt.Errorf("unsupported OS for automatic Docker installation: %s", osType)
	}

	_, stderr, err := client.RunWithSudo(ctx, installCmd)
	if err != nil {
		return fmt.Errorf("install failed: %w: %s", err, stderr)
	}

	return nil
}

func installTofuRemote(ctx context.Context, client *ssh.Client) error {
	installCmd := `
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method deb 2>/dev/null || ./install-opentofu.sh --install-method rpm
rm install-opentofu.sh
`
	_, stderr, err := client.RunWithSudo(ctx, installCmd)
	if err != nil {
		return fmt.Errorf("install failed: %w: %s", err, stderr)
	}

	return nil
}

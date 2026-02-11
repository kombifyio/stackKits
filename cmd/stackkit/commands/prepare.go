package commands

import (
	"context"
	"fmt"
	"os"
	"runtime"
	"strings"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/cue"
	"github.com/kombihq/stackkits/internal/docker"
	"github.com/kombihq/stackkits/internal/ssh"
	"github.com/kombihq/stackkits/internal/tofu"
	"github.com/kombihq/stackkits/pkg/models"
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
				return fmt.Errorf("Docker is not installed. Please install Docker first:\n  https://docs.docker.com/engine/install/")
			}
		} else {
			version, err := dockerClient.Version(ctx)
			if err != nil {
				printWarning("Could not get Docker version: %v", err)
			} else {
				printSuccess("Docker %s installed", version)
			}

			if !dockerClient.IsRunning(ctx) {
				printWarning("Docker daemon is not running")
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
				return fmt.Errorf("OpenTofu is not installed. Please install OpenTofu first:\n  https://opentofu.org/docs/intro/install/")
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
	defer sshClient.Close()

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
	if !prepareSkipDocker {
		if sysInfo.DockerVersion != "" {
			printSuccess("Docker %s installed", sysInfo.DockerVersion)
		} else {
			if prepareDryRun {
				printWarning("Docker not installed - would install")
			} else {
				printInfo("Installing Docker...")
				if err := installDockerRemote(ctx, sshClient, sysInfo.OS); err != nil {
					return fmt.Errorf("failed to install Docker: %w", err)
				}
				printSuccess("Docker installed successfully")
			}
		}
	}

	// Check OpenTofu
	if !prepareSkipTofu {
		if sysInfo.TofuVersion != "" {
			printSuccess("OpenTofu %s installed", sysInfo.TofuVersion)
		} else {
			if prepareDryRun {
				printWarning("OpenTofu not installed - would install")
			} else {
				printInfo("Installing OpenTofu...")
				if err := installTofuRemote(ctx, sshClient); err != nil {
					return fmt.Errorf("failed to install OpenTofu: %w", err)
				}
				printSuccess("OpenTofu installed successfully")
			}
		}
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
				fmt.Sscanf(line, "MemTotal: %d kB", &totalKB)
				break
			}
		}
		if totalKB > 0 {
			totalGB := float64(totalKB) / 1024 / 1024
			printSuccess("System memory: %.1f GB", totalGB)
			if totalGB < 2.0 {
				printWarning("Low memory — some services may not start. Consider using compute tier 'low'.")
			}
		} else {
			printInfo("System memory: could not parse /proc/meminfo")
		}
	} else {
		// Windows/macOS — no /proc/meminfo available
		printInfo("System memory: auto-detection not available on this OS (check manually)")
	}
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

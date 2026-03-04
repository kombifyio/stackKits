package commands

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
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
					caps, err := startDockerDaemon(ctx)
					if err != nil {
						return fmt.Errorf("Docker is installed but won't start: %w", err)
					}
					printSuccess("Docker daemon started")
					writeDockerCapabilities(caps)
				}
			} else {
				printSuccess("Docker daemon is running")
				// Detect capabilities even when Docker is already running.
				// This ensures capabilities.json exists for generate to read,
				// e.g. when the installer is re-run on a restricted VPS.
				caps := detectCapabilities()
				writeDockerCapabilities(caps)
			}
		}
	}

	// DNS test + image pre-pull (after Docker, before OpenTofu)
	if !prepareSkipDocker && !prepareDryRun {
		caps := loadDockerCapabilities()
		if caps == nil {
			caps = detectCapabilities()
		}
		caps = testDockerDNS(ctx, caps)
		prePullImages(ctx, caps)
		writeDockerCapabilities(caps)
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

func startDockerDaemon(ctx context.Context) (*models.DockerCapabilities, error) {
	isSystemd := false
	if _, err := os.Stat("/run/systemd/system"); err == nil {
		isSystemd = true
	}

	// Phase 1: Clean up stale state
	os.Remove("/var/run/docker.pid") //nolint:errcheck

	// Phase 2: Load required kernel modules
	loadDockerKernelModules()

	// Phase 3: Detect iptables capability and fix if possible
	iptablesAvailable := ensureIptables()

	// Phase 4: Detect best storage driver
	storageDriver := detectStorageDriver()

	// Phase 5: Detect bridge network capability
	bridgeAvailable := detectBridgeSupport()

	// Phase 6: Write adaptive daemon.json based on system capabilities
	ensureDaemonConfig(iptablesAvailable, storageDriver, bridgeAvailable)

	// Phase 7: Ensure containerd is ready (Docker depends on it)
	ensureContainerd(isSystemd)

	// Phase 8: Enable Docker service
	if isSystemd {
		exec.Command("systemctl", "enable", "docker").Run()        //nolint:errcheck
		exec.Command("systemctl", "enable", "docker.socket").Run() //nolint:errcheck
	}

	caps := &models.DockerCapabilities{
		BridgeNetworking: bridgeAvailable,
		Iptables:         iptablesAvailable,
		StorageDriver:    storageDriver,
	}

	// Phase 9: Start Docker
	if err := tryStartDocker(ctx, isSystemd); err == nil {
		return caps, nil
	}

	// Phase 10: First start failed — read logs, attempt targeted fixes, retry
	logOutput := getDockerLogs(isSystemd)
	needsRestart := false

	// Auto-fix: bridge creation blocked
	if strings.Contains(logOutput, "Failed to create bridge") ||
		strings.Contains(logOutput, "error creating default \"bridge\" network") {
		if bridgeAvailable {
			printWarning("Bridge network creation failed — disabling default bridge...")
			bridgeAvailable = false
			caps.BridgeNetworking = false
			needsRestart = true
		}
	}

	// Auto-fix: iptables/ip6tables failure in Docker logs
	if strings.Contains(logOutput, "iptables") && strings.Contains(logOutput, "Permission denied") {
		if iptablesAvailable {
			printWarning("Docker failed due to iptables — disabling...")
			iptablesAvailable = false
			caps.Iptables = false
			needsRestart = true
		}
	}

	// Auto-fix: storage driver failure (only match actual driver init errors)
	if strings.Contains(logOutput, "error initializing graphdriver") ||
		strings.Contains(logOutput, "driver not supported") {
		if storageDriver != "vfs" {
			fallbackDriver := "fuse-overlayfs"
			if _, err := exec.LookPath("fuse-overlayfs"); err != nil {
				fallbackDriver = "vfs"
			}
			printWarning("Storage driver %q failed — switching to %q...", storageDriver, fallbackDriver)
			storageDriver = fallbackDriver
			caps.StorageDriver = storageDriver
			os.RemoveAll("/var/lib/docker/overlay2") //nolint:errcheck
			os.RemoveAll("/var/lib/docker/network")  //nolint:errcheck
			needsRestart = true
		}
	}

	// Apply fixes and retry
	if needsRestart {
		writeDaemonJSON(iptablesAvailable, storageDriver, bridgeAvailable)
		stopDocker(isSystemd)
		if err := tryStartDocker(ctx, isSystemd); err == nil {
			printSuccess("Docker started after auto-fix")
			return caps, nil
		}
		logOutput = getDockerLogs(isSystemd)
	}

	// All auto-fixes exhausted — report clearly
	printWarning("Docker failed to start — diagnostics:")
	fmt.Println(logOutput)
	if _, err := os.Stat("/var/run/docker.sock"); os.IsNotExist(err) {
		printWarning("Docker socket /var/run/docker.sock does not exist")
	}
	return nil, fmt.Errorf("Docker daemon failed to start — see diagnostics above")
}

// detectCapabilities probes the system for Docker-relevant capabilities
// without restarting the daemon. Used when Docker is already running.
func detectCapabilities() *models.DockerCapabilities {
	return &models.DockerCapabilities{
		BridgeNetworking: detectBridgeSupport(),
		Iptables:         testIptablesNAT(),
		StorageDriver:    detectStorageDriver(),
	}
}

// writeDockerCapabilities persists detected Docker capabilities for use by generate.
func writeDockerCapabilities(caps *models.DockerCapabilities) {
	if caps == nil {
		return
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return
	}
	dir := filepath.Join(home, ".stackkits")
	os.MkdirAll(dir, 0755) //nolint:errcheck

	data, err := json.MarshalIndent(caps, "", "  ")
	if err != nil {
		return
	}
	os.WriteFile(filepath.Join(dir, "capabilities.json"), data, 0644) //nolint:errcheck
}

// testDockerDNS verifies DNS resolution works inside Docker containers.
// On restricted VPS (OpenVZ/LXC), Docker's internal DNS resolver depends on
// netfilter/conntrack. When iptables is disabled, container DNS breaks even
// though the host OS DNS works fine.
func testDockerDNS(ctx context.Context, caps *models.DockerCapabilities) *models.DockerCapabilities {
	if caps == nil {
		caps = &models.DockerCapabilities{}
	}

	printInfo("Testing Docker DNS resolution...")

	// Test: DNS lookup inside a container with explicit DNS server
	testCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(testCtx, "docker", "run", "--rm", "--dns", "1.1.1.1",
		"alpine:3.19", "nslookup", "registry-1.docker.io")
	output, err := cmd.CombinedOutput()

	if err == nil {
		printSuccess("Docker DNS is working")
		caps.DNSWorking = true
		caps.DNSFix = "none"
		return caps
	}

	printWarning("Docker DNS is not working: %s", strings.TrimSpace(string(output)))

	// Fix 1: Inject DNS servers into daemon.json and restart
	printInfo("Configuring explicit DNS servers (1.1.1.1, 8.8.8.8)...")
	applyDNSToDaemonJSON()
	restartDockerForDNS(ctx)

	// Re-test
	testCtx2, cancel2 := context.WithTimeout(ctx, 30*time.Second)
	defer cancel2()
	cmd2 := exec.CommandContext(testCtx2, "docker", "run", "--rm",
		"alpine:3.19", "nslookup", "registry-1.docker.io")
	if cmd2.Run() == nil {
		printSuccess("Docker DNS fixed (configured explicit DNS servers)")
		caps.DNSWorking = true
		caps.DNSFix = "daemon-json"
		return caps
	}

	// DNS still broken — we'll rely on pre-pulling from the host
	printWarning("Docker DNS remains unavailable (restricted VPS)")
	printInfo("Images will be pre-pulled from the host network")
	caps.DNSWorking = false
	caps.DNSFix = "host-prepull"
	return caps
}

// applyDNSToDaemonJSON injects explicit DNS servers into /etc/docker/daemon.json.
func applyDNSToDaemonJSON() {
	daemonCfg, err := os.ReadFile("/etc/docker/daemon.json")
	if err != nil {
		return
	}

	var cfg map[string]interface{}
	if json.Unmarshal(daemonCfg, &cfg) != nil {
		return
	}

	if _, hasDNS := cfg["dns"]; hasDNS {
		return // DNS already configured
	}

	cfg["dns"] = []string{"1.1.1.1", "8.8.8.8"}
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return
	}
	os.WriteFile("/etc/docker/daemon.json", data, 0644) //nolint:errcheck
}

// restartDockerForDNS restarts Docker daemon to apply DNS config changes.
func restartDockerForDNS(ctx context.Context) {
	isSystemd := false
	if _, err := os.Stat("/run/systemd/system"); err == nil {
		isSystemd = true
	}
	stopDocker(isSystemd)
	tryStartDocker(ctx, isSystemd) //nolint:errcheck
}

// baseKitImages returns the canonical list of Docker images used by the base-kit.
func baseKitImages() []string {
	return []string{
		"traefik:v3",
		"ghcr.io/steveiliop56/tinyauth:v4",
		"ghcr.io/pocket-id/pocket-id:v2",
		"postgres:16-alpine",
		"redis:7-alpine",
		"dokploy/dokploy:latest",
		"curlimages/curl:latest",
		"nginx:alpine",
		"louislam/uptime-kuma:1",
		"python:3.11-alpine",
		"traefik/whoami:latest",
	}
}

// prePullImages pulls all base-kit Docker images from the host network.
// This is critical on restricted VPS where container DNS is broken — the host
// network has working DNS, so `docker pull` from the host succeeds.
func prePullImages(ctx context.Context, caps *models.DockerCapabilities) {
	images := baseKitImages()
	printInfo("Pre-pulling %d Docker images...", len(images))

	pulled := []string{}
	failed := []string{}

	for i, image := range images {
		fmt.Printf("  [%d/%d] %s ", i+1, len(images), image)

		pullCtx, cancel := context.WithTimeout(ctx, 10*time.Minute)
		cmd := exec.CommandContext(pullCtx, "docker", "pull", image) // #nosec G204
		var stderr bytes.Buffer
		cmd.Stderr = &stderr
		if err := cmd.Run(); err != nil {
			cancel()
			fmt.Printf("✗\n")
			printWarning("    Failed: %s", strings.TrimSpace(stderr.String()))
			failed = append(failed, image)
		} else {
			cancel()
			fmt.Printf("✓\n")
			pulled = append(pulled, image)
		}
	}

	caps.PrePulledImages = pulled
	caps.PrePullFailed = failed

	if len(failed) == 0 {
		printSuccess("All %d images pre-pulled", len(pulled))
	} else {
		printWarning("%d images pulled, %d failed", len(pulled), len(failed))
	}
}

// loadDockerKernelModules loads kernel modules required by Docker networking and storage.
func loadDockerKernelModules() {
	modules := []string{
		"ip_tables",     // base iptables
		"iptable_nat",   // NAT table (port mapping)
		"iptable_filter", // filter table
		"nf_nat",        // netfilter NAT core
		"br_netfilter",  // bridge netfilter (container traffic)
		"overlay",       // overlay2 storage driver
		"bridge",        // bridge networking
	}
	for _, mod := range modules {
		exec.Command("modprobe", mod).Run() //nolint:errcheck
	}

	// Enable IPv4 forwarding (required for container networking)
	os.WriteFile("/proc/sys/net/ipv4/ip_forward", []byte("1"), 0644) //nolint:errcheck
}

// ensureIptables tests iptables NAT support, switching backends if needed.
// Returns true if iptables NAT works, false if Docker must run without it.
func ensureIptables() bool {
	// Test 1: Does iptables NAT work with the current backend?
	if testIptablesNAT() {
		return true
	}

	// Test 2: Try switching to iptables-legacy
	printWarning("iptables NAT failed — trying iptables-legacy...")
	if switchToIptablesLegacy() {
		if testIptablesNAT() {
			printSuccess("iptables-legacy works")
			return true
		}
		printWarning("iptables-legacy also failed")
	}

	// Test 3: iptables is completely broken on this system
	printWarning("iptables NAT unavailable — Docker will run without iptables management")
	return false
}

// testIptablesNAT checks if iptables can access the NAT table.
func testIptablesNAT() bool {
	cmd := exec.Command("iptables", "--wait", "-t", "nat", "-L", "-n")
	return cmd.Run() == nil
}

// switchToIptablesLegacy switches iptables from nf_tables to legacy backend.
func switchToIptablesLegacy() bool {
	cmds := []struct{ name, link string }{
		{"iptables", "/usr/sbin/iptables-legacy"},
		{"ip6tables", "/usr/sbin/ip6tables-legacy"},
	}
	success := false
	for _, c := range cmds {
		if _, err := os.Stat(c.link); err == nil {
			cmd := exec.Command("update-alternatives", "--set", c.name, c.link)
			if err := cmd.Run(); err == nil {
				success = true
			}
		}
	}
	return success
}

// detectStorageDriver tests which Docker storage driver the system supports.
func detectStorageDriver() string {
	// Test overlay2: try mounting an overlay filesystem
	testDir := "/tmp/stackkit-overlay-test"
	os.MkdirAll(testDir+"/lower", 0755)  //nolint:errcheck
	os.MkdirAll(testDir+"/upper", 0755)  //nolint:errcheck
	os.MkdirAll(testDir+"/work", 0755)   //nolint:errcheck
	os.MkdirAll(testDir+"/merged", 0755) //nolint:errcheck
	defer os.RemoveAll(testDir)          //nolint:errcheck

	mountCmd := exec.Command("mount", "-t", "overlay", "overlay",
		"-o", fmt.Sprintf("lowerdir=%s/lower,upperdir=%s/upper,workdir=%s/work", testDir, testDir, testDir),
		testDir+"/merged")
	if mountCmd.Run() == nil {
		exec.Command("umount", testDir+"/merged").Run() //nolint:errcheck
		return "overlay2"
	}

	// overlay2 not supported — try fuse-overlayfs
	if _, err := exec.LookPath("fuse-overlayfs"); err == nil {
		printInfo("overlay2 not available — using fuse-overlayfs")
		return "fuse-overlayfs"
	}

	// Last resort: vfs (no copy-on-write, uses more disk, but works everywhere)
	printWarning("overlay2 not available — using vfs storage driver (slower, uses more disk)")
	return "vfs"
}

// detectBridgeSupport tests if the kernel allows creating bridge network interfaces.
func detectBridgeSupport() bool {
	testBridge := "sk-br-test"
	createCmd := exec.Command("ip", "link", "add", "name", testBridge, "type", "bridge")
	if err := createCmd.Run(); err != nil {
		printWarning("Bridge networking not available — Docker will use host networking")
		return false
	}
	exec.Command("ip", "link", "delete", testBridge).Run() //nolint:errcheck
	return true
}

// ensureDaemonConfig writes /etc/docker/daemon.json adapted to system capabilities.
func ensureDaemonConfig(iptablesAvailable bool, storageDriver string, bridgeAvailable bool) {
	// Only preserve existing config if it wasn't written by stackkit
	if _, err := os.Stat("/etc/docker/daemon.json"); err == nil {
		existing, readErr := os.ReadFile("/etc/docker/daemon.json")
		if readErr == nil && len(existing) > 5 && !strings.Contains(string(existing), "max-concurrent-downloads") {
			// User has a custom config (not ours) — respect it
			return
		}
	}
	writeDaemonJSON(iptablesAvailable, storageDriver, bridgeAvailable)
}

// writeDaemonJSON writes an adaptive daemon.json based on system capabilities.
func writeDaemonJSON(iptablesAvailable bool, storageDriver string, bridgeAvailable bool) {
	os.MkdirAll("/etc/docker", 0755) //nolint:errcheck

	iptablesStr := "true"
	ip6tablesStr := "true"
	if !iptablesAvailable {
		iptablesStr = "false"
		ip6tablesStr = "false"
	}

	// Detect DNS: systemd-resolved uses 127.0.0.53 which doesn't work in containers
	dnsLine := ""
	if resolv, err := os.ReadFile("/etc/resolv.conf"); err == nil {
		if strings.Contains(string(resolv), "127.0.0.53") {
			dnsLine = `  "dns": ["1.1.1.1", "8.8.8.8"],` + "\n"
		}
	}

	// Bridge config: disable default bridge if kernel blocks it
	bridgeLine := ""
	if !bridgeAvailable {
		bridgeLine = `  "bridge": "none",` + "\n"
	}

	config := fmt.Sprintf(`{
  "storage-driver": "%s",
  "iptables": %s,
  "ip6tables": %s,
%s%s  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "max-concurrent-downloads": 3
}`, storageDriver, iptablesStr, ip6tablesStr, bridgeLine, dnsLine)

	os.WriteFile("/etc/docker/daemon.json", []byte(config), 0644) //nolint:errcheck

	details := fmt.Sprintf("storage=%s, iptables=%s", storageDriver, iptablesStr)
	if !bridgeAvailable {
		details += ", bridge=none"
	}
	printInfo("Configured /etc/docker/daemon.json (%s)", details)
}

// ensureContainerd starts containerd and waits for its socket to be ready.
func ensureContainerd(isSystemd bool) {
	if isSystemd {
		exec.Command("systemctl", "enable", "containerd").Run() //nolint:errcheck
		exec.Command("systemctl", "start", "containerd").Run()  //nolint:errcheck
	} else {
		exec.Command("service", "containerd", "start").Run() //nolint:errcheck
	}

	// Wait for containerd socket (up to 10s)
	for i := 0; i < 10; i++ {
		if _, err := os.Stat("/run/containerd/containerd.sock"); err == nil {
			return
		}
		time.Sleep(1 * time.Second)
	}
}

// tryStartDocker starts the Docker service and waits up to 30s for it to respond.
func tryStartDocker(ctx context.Context, isSystemd bool) error {
	os.Remove("/var/run/docker.pid") //nolint:errcheck

	if isSystemd {
		cmd := exec.Command("systemctl", "start", "docker")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}
	} else {
		cmd := exec.Command("service", "docker", "start")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}
	}

	dockerClient := docker.NewClient()
	for i := 0; i < 30; i++ {
		if dockerClient.IsRunning(ctx) {
			return nil
		}
		time.Sleep(1 * time.Second)
	}
	return fmt.Errorf("timeout waiting for Docker daemon (30s)")
}

// stopDocker stops the Docker daemon for a clean restart.
func stopDocker(isSystemd bool) {
	if isSystemd {
		exec.Command("systemctl", "stop", "docker").Run()        //nolint:errcheck
		exec.Command("systemctl", "stop", "docker.socket").Run() //nolint:errcheck
	} else {
		exec.Command("service", "docker", "stop").Run() //nolint:errcheck
	}
	os.Remove("/var/run/docker.pid") //nolint:errcheck
	time.Sleep(2 * time.Second)
}

// getDockerLogs returns recent Docker daemon log output.
func getDockerLogs(isSystemd bool) string {
	if isSystemd {
		cmd := exec.Command("journalctl", "-u", "docker", "--no-pager", "-n", "30")
		output, _ := cmd.CombinedOutput()
		return string(output)
	}
	for _, logFile := range []string{"/var/log/docker.log", "/var/log/syslog"} {
		if _, err := os.Stat(logFile); err == nil {
			cmd := exec.Command("tail", "-30", logFile)
			output, _ := cmd.CombinedOutput()
			return string(output)
		}
	}
	return "no Docker logs found"
}

func installDockerLocal(ctx context.Context) error {
	cmd := exec.Command("sh", "-c", "curl -fsSL https://get.docker.com | sh")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return err
	}
	// Enable and start Docker daemon — this must succeed for deployment to work
	caps, err := startDockerDaemon(ctx)
	if err != nil {
		return fmt.Errorf("Docker installed but failed to start: %w", err)
	}
	writeDockerCapabilities(caps)
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

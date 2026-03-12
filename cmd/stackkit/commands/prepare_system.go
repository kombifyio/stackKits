package commands

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/kombifyio/stackkits/internal/ssh"
	"github.com/kombifyio/stackkits/pkg/models"
)

// detectVirtualization detects the virtualization type of the current system.
// Returns "kvm", "openvz", "lxc", "vmware", "hyperv", "xen", or "none" (bare metal).
func detectVirtualization() string {
	// Method 1: systemd-detect-virt (most reliable on systemd systems)
	if out, err := exec.Command("systemd-detect-virt").CombinedOutput(); err == nil {
		virt := strings.TrimSpace(string(out))
		if virt != "" && virt != models.VirtNone {
			return virt
		}
		return models.VirtNone
	}

	// Method 2: Check /proc/vz (OpenVZ indicator)
	if _, err := os.Stat("/proc/vz"); err == nil {
		if _, err := os.Stat("/proc/bc"); err != nil {
			// /proc/vz exists but /proc/bc doesn't → guest (not host)
			return models.VirtOpenVZ
		}
	}

	// Method 3: Check for LXC
	if data, err := os.ReadFile("/proc/1/environ"); err == nil {
		if strings.Contains(string(data), "container=lxc") {
			return models.VirtLXC
		}
	}
	if data, err := os.ReadFile("/proc/1/cgroup"); err == nil {
		if strings.Contains(string(data), "/lxc/") {
			return models.VirtLXC
		}
	}

	// Method 4: Check DMI for KVM/QEMU/VMware
	if data, err := os.ReadFile("/sys/class/dmi/id/product_name"); err == nil {
		product := strings.TrimSpace(strings.ToLower(string(data)))
		switch {
		case strings.Contains(product, "kvm"), strings.Contains(product, "qemu"):
			return models.VirtKVM
		case strings.Contains(product, "vmware"):
			return "vmware"
		case strings.Contains(product, "virtualbox"):
			return "oracle"
		case strings.Contains(product, "hyper-v"):
			return "microsoft"
		}
	}

	// Method 5: Check hypervisor CPUID flag
	if data, err := os.ReadFile("/proc/cpuinfo"); err == nil {
		if strings.Contains(string(data), "hypervisor") {
			return models.VirtKVM
		}
	}

	return models.VirtNone
}

// testUnshare tests whether the unshare(2) syscall is available.
// This is the single most important check — if unshare is blocked, Docker cannot
// create any containers regardless of what else works.
func testUnshare() bool {
	cmd := exec.Command("unshare", "--mount", "--pid", "--fork", "true")
	return cmd.Run() == nil
}

// detectCgroupVersion returns "v2" if the system uses cgroup v2 (unified), else "v1".
func detectCgroupVersion() string {
	if data, err := os.ReadFile("/proc/filesystems"); err == nil {
		if strings.Contains(string(data), "cgroup2") {
			// Check if cgroup2 is actually mounted as the unified hierarchy
			if _, err := os.Stat("/sys/fs/cgroup/cgroup.controllers"); err == nil {
				return "v2"
			}
		}
	}
	return "v1"
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

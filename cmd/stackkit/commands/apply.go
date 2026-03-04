package commands

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/kombifyio/stackkits/internal/config"
	"github.com/kombifyio/stackkits/internal/docker"
	"github.com/kombifyio/stackkits/internal/iac"
	"github.com/kombifyio/stackkits/internal/tofu"
	"github.com/kombifyio/stackkits/pkg/models"
	"github.com/spf13/cobra"
)

var applyAutoApprove bool

var applyCmd = &cobra.Command{
	Use:   "apply [plan-file]",
	Short: "Apply infrastructure changes",
	Long: `Apply the planned changes to the infrastructure.

This command runs 'tofu apply' to create, update, or destroy
infrastructure resources as needed.

Examples:
  stackkit apply                   Apply changes (with confirmation)
  stackkit apply --auto-approve    Apply without confirmation
  stackkit apply plan.tfplan       Apply a saved plan`,
	Args: cobra.MaximumNArgs(1),
	RunE: runApply,
}

func init() {
	applyCmd.Flags().BoolVar(&applyAutoApprove, "auto-approve", false, "Skip interactive approval")
}

func runApply(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	wd := getWorkDir()

	// Load spec — create from kit defaults if missing
	loader := config.NewLoader(wd)
	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		specPath := filepath.Join(wd, specFile)
		if _, statErr := os.Stat(specPath); os.IsNotExist(statErr) {
			spec, err = createDefaultSpec(loader, wd)
			if err != nil {
				return fmt.Errorf("no spec file and auto-init failed: %w", err)
			}
		} else {
			return fmt.Errorf("failed to load spec: %w", err)
		}
	}

	printInfo("Applying deployment: %s (%s variant)", spec.StackKit, spec.Variant)

	// Ensure prerequisites are installed
	if err := ensurePrerequisites(ctx); err != nil {
		return err
	}

	// Determine deploy directory — auto-generate if missing or empty
	deployDir := filepath.Join(wd, config.GetDeployDir())
	needsGenerate := false
	if _, statErr := os.Stat(deployDir); os.IsNotExist(statErr) {
		needsGenerate = true
	} else if hasTF, _ := tofu.HasTerraformFiles(deployDir); !hasTF {
		needsGenerate = true
	}
	if needsGenerate {
		printInfo("Deploy directory not found or empty, running generate...")
		genOutputDir = config.GetDeployDir()
		genForce = true
		if genErr := runGenerate(cmd, nil); genErr != nil {
			return fmt.Errorf("auto-generate failed: %w", genErr)
		}
	}

	// Get plan file if provided
	planFile := ""
	if len(args) > 0 {
		planFile = args[0]
	}

	// Create IaC executor from spec (supports OpenTofu and Terramate modes)
	executor, err := iac.NewExecutorFromSpec(spec, deployDir)
	if err != nil {
		return fmt.Errorf("failed to create executor: %w", err)
	}

	// OpenTofu was already checked by ensurePrerequisites

	// Initialize if needed
	tfStatePath := filepath.Join(deployDir, ".terraform")
	if _, statErr := os.Stat(tfStatePath); os.IsNotExist(statErr) {
		printInfo("Initializing %s...", executor.Mode())
		if initErr := executor.Init(ctx); initErr != nil {
			return fmt.Errorf("init error: %w", initErr)
		}
		printSuccess("Initialized successfully")
	}

	// Run apply with troubleshooting retry wrapper
	printInfo("Applying changes...")
	startTime := time.Now()

	result, err := troubleshootAndApply(ctx, executor, applyAutoApprove, planFile, deployDir)
	if err != nil {
		return fmt.Errorf("apply error: %w", err)
	}

	duration := time.Since(startTime)

	// Display output
	if result.Stdout != "" {
		fmt.Println()
		fmt.Println(result.Stdout)
	}

	if !result.Success {
		userMsg := formatApplyError(result.Stderr)
		printError("%s", userMsg)
		fmt.Println()
		printInfo("Troubleshooting tips:")
		fmt.Println("  1. Run 'stackkit prepare' to re-detect system capabilities")
		fmt.Println("  2. Run 'stackkit apply' to retry the deployment")
		return fmt.Errorf("deployment failed")
	}

	// Update deployment state
	state := &models.DeploymentState{
		StackKit:    spec.StackKit,
		Variant:     spec.Variant,
		Mode:        spec.Mode,
		Status:      models.StatusRunning,
		LastApplied: time.Now(),
	}

	stateFile := filepath.Join(wd, ".stackkit", "state.yaml")
	if mkdirErr := os.MkdirAll(filepath.Dir(stateFile), 0750); mkdirErr != nil {
		printWarning("Failed to create state directory: %v", mkdirErr)
	} else if saveErr := loader.SaveDeploymentState(state, stateFile); saveErr != nil {
		printWarning("Failed to save deployment state: %v", saveErr)
	}

	fmt.Println()
	printSuccess("Apply complete! (took %s)", duration.Round(time.Second))

	// Get and display outputs
	output, err := executor.Output(ctx)
	if err == nil && output != "" {
		printInfo("Deployment outputs:")
		fmt.Println(output)
	}

	return nil
}

// createDefaultSpec finds a StackKit and copies its default-spec.yaml
// into the working directory as stack-spec.yaml.
func createDefaultSpec(loader *config.Loader, wd string) (*models.StackSpec, error) {
	kits, err := discoverStackKits(loader, wd)
	if err != nil || len(kits) == 0 {
		return nil, fmt.Errorf("no StackKits found — run 'stackkit init <kit>' first")
	}

	// Prefer base-kit, fall back to single kit, otherwise ask
	var kitName string
	for _, k := range kits {
		if k.Metadata.Name == "base-kit" {
			kitName = k.Metadata.Name
			break
		}
	}
	if kitName == "" && len(kits) == 1 {
		kitName = kits[0].Metadata.Name
	}
	if kitName == "" {
		p := newPrompter()
		var choices []choice
		for _, sk := range kits {
			choices = append(choices, choice{
				Key:     sk.Metadata.Name,
				Display: sk.Metadata.DisplayName,
			})
		}
		choices[0].IsDefault = true
		kitName, err = p.selectOne("Multiple StackKits found. Select one:", choices)
		if err != nil {
			return nil, err
		}
	}

	printInfo("No spec file found, using defaults from %s", bold(kitName))

	// Find kit directory
	kitDir, err := loader.FindStackKitDir(kitName)
	if err != nil {
		parentLoader := config.NewLoader(filepath.Dir(wd))
		kitDir, err = parentLoader.FindStackKitDir(kitName)
		if err != nil {
			return nil, fmt.Errorf("could not find %s: %w", kitName, err)
		}
	}

	// Copy default-spec.yaml to stack-spec.yaml
	defaultSpecPath := filepath.Join(kitDir, "default-spec.yaml")
	data, err := os.ReadFile(defaultSpecPath)
	if err != nil {
		return nil, fmt.Errorf("no default-spec.yaml in %s: %w", kitName, err)
	}

	specPath := filepath.Join(wd, specFile)
	if err := os.WriteFile(specPath, data, 0600); err != nil {
		return nil, fmt.Errorf("failed to write %s: %w", specFile, err)
	}
	printSuccess("Created %s from %s defaults", specFile, kitName)

	return loader.LoadStackSpec(specFile)
}

// ensurePrerequisites checks that Docker and OpenTofu are available,
// offering to install them if missing.
func ensurePrerequisites(ctx context.Context) error {
	// Check Docker
	dockerClient := docker.NewClient()
	if !dockerClient.IsInstalled() {
		if applyAutoApprove {
			printInfo("Docker is not installed, installing...")
		} else {
			printWarning("Docker is not installed")
			fmt.Print("Install Docker now? [Y/n] ")
			var answer string
			_, _ = fmt.Scanln(&answer)
			if len(answer) > 0 && (answer[0] == 'n' || answer[0] == 'N') {
				return fmt.Errorf("Docker is required. Install it manually or run 'stackkit prepare'")
			}
			printInfo("Installing Docker...")
		}
		if err := installDockerLocal(ctx); err != nil {
			return fmt.Errorf("failed to install Docker: %w", err)
		}
		printSuccess("Docker installed")
	}

	// Ensure Docker daemon is running (start it if needed)
	if !dockerClient.IsRunning(ctx) {
		printInfo("Docker daemon is not running, starting...")
		caps, err := startDockerDaemon(ctx)
		if err != nil {
			return fmt.Errorf("failed to start Docker daemon: %w", err)
		}
		writeDockerCapabilities(caps)
		printSuccess("Docker daemon started")
	}

	// Check OpenTofu
	tofuExec := tofu.NewExecutor()
	if !tofuExec.IsInstalled() {
		if applyAutoApprove {
			printInfo("OpenTofu is not installed, installing...")
		} else {
			printWarning("OpenTofu is not installed")
			fmt.Print("Install OpenTofu now? [Y/n] ")
			var answer string
			_, _ = fmt.Scanln(&answer)
			if len(answer) > 0 && (answer[0] == 'n' || answer[0] == 'N') {
				return fmt.Errorf("OpenTofu is required. Install it manually or run 'stackkit prepare'")
			}
			printInfo("Installing OpenTofu...")
		}
		if err := installTofuLocal(ctx); err != nil {
			return fmt.Errorf("failed to install OpenTofu: %w", err)
		}
		// Verify installation
		tofuExec = tofu.NewExecutor()
		if !tofuExec.IsInstalled() {
			return fmt.Errorf("OpenTofu installation completed but binary not found in PATH")
		}
		printSuccess("OpenTofu installed")
	}

	return nil
}

// =============================================================================
// TROUBLESHOOTING ENGINE
// =============================================================================

// applyFailurePattern represents a known failure pattern and its automated fix.
type applyFailurePattern struct {
	Name        string
	Match       func(stderr string) bool
	Fix         func(ctx context.Context, deployDir string) error
	UserMessage string
}

// knownFailurePatterns returns the ordered list of failure patterns to check.
func knownFailurePatterns() []applyFailurePattern {
	return []applyFailurePattern{
		{
			Name: "docker-image-pull",
			Match: func(stderr string) bool {
				return (strings.Contains(stderr, "unable to find") ||
					strings.Contains(stderr, "unable to pull") ||
					strings.Contains(stderr, "Error pulling image") ||
					strings.Contains(stderr, "i/o timeout")) &&
					strings.Contains(stderr, "docker_image")
			},
			Fix: func(ctx context.Context, deployDir string) error {
				printInfo("Pre-pulling images from host network...")
				caps := loadDockerCapabilities()
				if caps == nil {
					caps = &models.DockerCapabilities{}
				}
				prePullImages(ctx, caps)
				writeDockerCapabilities(caps)
				if len(caps.PrePullFailed) > 0 {
					return fmt.Errorf("%d images failed to pull", len(caps.PrePullFailed))
				}
				return nil
			},
			UserMessage: "Docker image pulls failed (DNS or network issue). Pulling images from host network...",
		},
		{
			Name: "docker-network",
			Match: func(stderr string) bool {
				return strings.Contains(stderr, "docker_network") &&
					(strings.Contains(stderr, "operation not permitted") ||
						strings.Contains(stderr, "Unable to create network"))
			},
			Fix: func(ctx context.Context, deployDir string) error {
				printInfo("Switching to host networking mode...")
				if err := patchTfvarsNetworkMode(deployDir, "host"); err != nil {
					return err
				}
				// Re-init to pick up the tfvars change
				tofuExec := tofu.NewExecutor()
				tofuExec.SetWorkDir(deployDir)
				_, err := tofuExec.Init(ctx)
				return err
			},
			UserMessage: "Bridge networking blocked (restricted VPS). Switching to host networking mode...",
		},
		{
			Name: "docker-daemon",
			Match: func(stderr string) bool {
				return strings.Contains(stderr, "Cannot connect to the Docker daemon") ||
					strings.Contains(stderr, "docker.sock") ||
					strings.Contains(stderr, "connection refused")
			},
			Fix: func(ctx context.Context, _ string) error {
				printInfo("Restarting Docker daemon...")
				caps, err := startDockerDaemon(ctx)
				if err != nil {
					return err
				}
				writeDockerCapabilities(caps)
				return nil
			},
			UserMessage: "Docker daemon lost connection. Restarting Docker...",
		},
		{
			Name: "state-lock",
			Match: func(stderr string) bool {
				return strings.Contains(stderr, "Error acquiring the state lock") ||
					strings.Contains(stderr, "state is locked")
			},
			Fix: func(_ context.Context, _ string) error {
				printInfo("Waiting for state lock to release...")
				time.Sleep(5 * time.Second)
				return nil
			},
			UserMessage: "Infrastructure state is locked. Waiting...",
		},
	}
}

// troubleshootAndApply wraps executor.Apply with detect-fix-retry logic.
// Follows the same pattern as startDockerDaemon() in prepare.go:
// Attempt → Detect failure pattern → Apply fix → Retry → Escalate.
func troubleshootAndApply(
	ctx context.Context,
	executor iac.Executor,
	autoApprove bool,
	planFile string,
	deployDir string,
) (*iac.ExecResult, error) {
	const maxRetries = 2
	patterns := knownFailurePatterns()

	var lastResult *iac.ExecResult
	var appliedFixes []string

	for attempt := 0; attempt <= maxRetries; attempt++ {
		if attempt > 0 {
			fmt.Println()
			printInfo("Retry attempt %d/%d...", attempt, maxRetries)
		}

		result, err := executor.Apply(ctx, autoApprove, planFile)
		if err != nil {
			return nil, fmt.Errorf("apply error: %w", err)
		}

		lastResult = result

		if result.Success {
			if attempt > 0 {
				printSuccess("Apply succeeded after troubleshooting (%d fix(es) applied)", len(appliedFixes))
			}
			return result, nil
		}

		// Apply failed — try to match a known pattern and fix
		if attempt >= maxRetries {
			break
		}

		fixed := false
		for _, pattern := range patterns {
			if !pattern.Match(result.Stderr) {
				continue
			}

			// Don't apply the same fix twice
			alreadyApplied := false
			for _, name := range appliedFixes {
				if name == pattern.Name {
					alreadyApplied = true
					break
				}
			}
			if alreadyApplied {
				continue
			}

			fmt.Println()
			printWarning("%s", pattern.UserMessage)

			if fixErr := pattern.Fix(ctx, deployDir); fixErr != nil {
				printWarning("Auto-fix failed: %v", fixErr)
				continue
			}

			appliedFixes = append(appliedFixes, pattern.Name)
			fixed = true
			break
		}

		if !fixed {
			break // no pattern matched — don't retry blindly
		}
	}

	return lastResult, nil
}

// formatApplyError translates raw Terraform/OpenTofu stderr into a
// user-friendly error message.
func formatApplyError(stderr string) string {
	translations := []struct {
		pattern string
		message string
	}{
		{"unable to find", "Could not download one or more container images. Check your internet connection."},
		{"unable to pull", "Could not download one or more container images. Check your internet connection."},
		{"Error pulling image", "Failed to download a container image (DNS or network issue)."},
		{"Unable to create network", "Could not create Docker network. Your VPS may not support bridge networking."},
		{"Cannot connect to the Docker daemon", "Docker is not running. Run 'stackkit prepare' to start it."},
		{"Error acquiring the state lock", "Another deployment operation is in progress. Wait and try again."},
		{"context deadline exceeded", "Operation timed out. Check if your server has adequate resources."},
	}

	for _, t := range translations {
		if strings.Contains(stderr, t.pattern) {
			return t.message
		}
	}

	// Extract first "Error:" line as fallback
	for _, line := range strings.Split(stderr, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "Error") || strings.HasPrefix(trimmed, "│ Error") {
			cleaned := strings.TrimPrefix(trimmed, "│ ")
			return "Deployment error: " + cleaned
		}
	}

	return "Deployment failed. Run 'stackkit prepare' then retry with 'stackkit apply'."
}

// patchTfvarsNetworkMode updates terraform.tfvars.json to change network_mode.
func patchTfvarsNetworkMode(deployDir, mode string) error {
	tfvarsPath := filepath.Join(deployDir, "terraform.tfvars.json")
	data, err := os.ReadFile(tfvarsPath)
	if err != nil {
		return fmt.Errorf("could not read tfvars: %w", err)
	}

	var vars map[string]interface{}
	if err := json.Unmarshal(data, &vars); err != nil {
		return fmt.Errorf("could not parse tfvars: %w", err)
	}

	vars["network_mode"] = mode

	newData, err := json.MarshalIndent(vars, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(tfvarsPath, append(newData, '\n'), 0600)
}

package commands

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/docker"
	"github.com/kombihq/stackkits/internal/iac"
	"github.com/kombihq/stackkits/internal/tofu"
	"github.com/kombihq/stackkits/pkg/models"
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

	// Run apply
	printInfo("Applying changes...")
	startTime := time.Now()

	result, err := executor.Apply(ctx, applyAutoApprove, planFile)
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
		printError("Apply failed:")
		fmt.Println(result.Stderr)
		return fmt.Errorf("%s apply failed", executor.Mode())
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
		if err := startDockerDaemon(ctx); err != nil {
			return fmt.Errorf("failed to start Docker daemon: %w", err)
		}
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

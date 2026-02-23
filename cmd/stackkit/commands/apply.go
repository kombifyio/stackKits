package commands

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/iac"
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

	// Load spec
	loader := config.NewLoader(wd)
	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		return fmt.Errorf("failed to load spec: %w", err)
	}

	printInfo("Applying deployment: %s (%s variant)", spec.StackKit, spec.Variant)

	// Determine deploy directory — auto-generate if missing
	deployDir := filepath.Join(wd, config.GetDeployDir())
	if _, statErr := os.Stat(deployDir); os.IsNotExist(statErr) {
		printInfo("Deploy directory not found, running generate...")
		genOutputDir = config.GetDeployDir()
		genForce = false
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

	// Check if tool is installed
	if !executor.IsInstalled() {
		return fmt.Errorf("%s is not installed. Run 'stackkit prepare' first", executor.Mode())
	}

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

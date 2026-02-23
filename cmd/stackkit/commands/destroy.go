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

var (
	destroyAutoApprove bool
	destroyForce       bool
)

var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy the deployed infrastructure",
	Long: `Destroy all resources created by the deployment.

This command runs 'tofu destroy' to tear down all infrastructure
resources managed by the StackKit deployment.

WARNING: This will permanently delete all resources and data.

Examples:
  stackkit destroy                 Destroy with confirmation
  stackkit destroy --auto-approve  Destroy without confirmation
  stackkit destroy --force         Force destroy even with errors`,
	RunE: runDestroy,
}

func init() {
	destroyCmd.Flags().BoolVar(&destroyAutoApprove, "auto-approve", false, "Skip interactive approval")
	destroyCmd.Flags().BoolVar(&destroyForce, "force", false, "Force destroy even with errors")
}

func runDestroy(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	wd := getWorkDir()

	// Load spec
	loader := config.NewLoader(wd)
	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		printWarning("Could not load spec file, continuing with destroy")
		spec = &models.StackSpec{StackKit: "unknown"}
	}

	printWarning("Destroying deployment: %s", spec.StackKit)

	// Determine deploy directory
	deployDir := filepath.Join(wd, config.GetDeployDir())
	if _, statErr := os.Stat(deployDir); os.IsNotExist(statErr) {
		printWarning("Deploy directory not found: %s", deployDir)
		if !destroyForce {
			return fmt.Errorf("nothing to destroy")
		}
	}

	// Confirmation if not auto-approved
	if !destroyAutoApprove {
		fmt.Println()
		printError("WARNING: This will permanently destroy all resources!")
		fmt.Print("Type 'yes' to confirm: ")

		var confirm string
		_, _ = fmt.Scanln(&confirm)
		if confirm != "yes" {
			printInfo("Destroy canceled")
			return nil
		}
	}

	// Create IaC executor from spec (supports OpenTofu and Terramate modes)
	executor, err := iac.NewExecutorFromSpec(spec, deployDir)
	if err != nil {
		return fmt.Errorf("failed to create executor: %w", err)
	}

	// Check if tool is installed
	if !executor.IsInstalled() {
		return fmt.Errorf("%s is not installed", executor.Mode())
	}

	// Run destroy
	printInfo("Destroying infrastructure...")
	startTime := time.Now()

	result, err := executor.Destroy(ctx, true) // already confirmed above
	if err != nil {
		return fmt.Errorf("destroy error: %w", err)
	}

	duration := time.Since(startTime)

	// Display output
	if result.Stdout != "" {
		fmt.Println()
		fmt.Println(result.Stdout)
	}

	if !result.Success {
		printError("Destroy encountered errors:")
		fmt.Println(result.Stderr)
		if !destroyForce {
			return fmt.Errorf("%s destroy failed", executor.Mode())
		}
		printWarning("Continuing despite errors (--force)")
	}

	// Update deployment state
	state := &models.DeploymentState{
		StackKit:    spec.StackKit,
		Variant:     spec.Variant,
		Mode:        spec.Mode,
		Status:      models.StatusDestroyed,
		LastApplied: time.Now(),
	}

	stateFile := filepath.Join(wd, ".stackkit", "state.yaml")
	if err := os.MkdirAll(filepath.Dir(stateFile), 0750); err != nil {
		printWarning("Failed to create state directory: %v", err)
	} else if err := loader.SaveDeploymentState(state, stateFile); err != nil {
		printWarning("Failed to save deployment state: %v", err)
	}

	fmt.Println()
	printSuccess("Destroy complete! (took %s)", duration.Round(time.Second))

	return nil
}

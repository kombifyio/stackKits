package commands

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/tofu"
	"github.com/spf13/cobra"
)

var (
	planOut     string
	planDestroy bool
)

var planCmd = &cobra.Command{
	Use:   "plan",
	Short: "Preview infrastructure changes",
	Long: `Generate and show an execution plan for the infrastructure.

This command runs 'tofu plan' to preview what changes would be made
to your infrastructure without actually applying them.

Examples:
  stackkit plan                    Preview changes
  stackkit plan -o plan.tfplan     Save plan to file
  stackkit plan --destroy          Preview destroy`,
	RunE: runPlan,
}

func init() {
	planCmd.Flags().StringVarP(&planOut, "out", "o", "", "Save plan to file")
	planCmd.Flags().BoolVar(&planDestroy, "destroy", false, "Create destroy plan")
}

func runPlan(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	wd := getWorkDir()

	// Load spec
	loader := config.NewLoader(wd)
	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		return fmt.Errorf("failed to load spec: %w", err)
	}

	printInfo("Planning deployment: %s (%s variant)", spec.StackKit, spec.Variant)

	// Determine deploy directory
	deployDir := filepath.Join(wd, config.GetDeployDir())
	if _, err := os.Stat(deployDir); os.IsNotExist(err) {
		return fmt.Errorf("deploy directory not found: %s\nRun 'stackkit init' first", deployDir)
	}

	// Create tofu executor
	executor := tofu.NewExecutor(
		tofu.WithWorkDir(deployDir),
	)

	// Check if tofu is installed
	if !executor.IsInstalled() {
		return fmt.Errorf("OpenTofu is not installed. Run 'stackkit prepare' first")
	}

	// Initialize if needed
	tfStatePath := filepath.Join(deployDir, ".terraform")
	if _, err := os.Stat(tfStatePath); os.IsNotExist(err) {
		printInfo("Initializing OpenTofu...")
		result, err := executor.Init(ctx)
		if err != nil {
			return fmt.Errorf("init error: %w", err)
		}
		if !result.Success {
			printError("Init failed:")
			fmt.Println(result.Stderr)
			return fmt.Errorf("tofu init failed")
		}
		printSuccess("Initialized successfully")
	}

	// Run plan
	printInfo("Running plan...")

	planFile := planOut
	if planFile == "" {
		planFile = filepath.Join(deployDir, "plan.tfplan")
	}

	result, err := executor.Plan(ctx, planFile)
	if err != nil {
		return fmt.Errorf("plan error: %w", err)
	}

	// Parse and display results
	if result.Stdout != "" {
		fmt.Println()
		fmt.Println(result.Stdout)
	}

	if !result.Success && result.ExitCode != 2 {
		printError("Plan failed:")
		fmt.Println(result.Stderr)
		return fmt.Errorf("tofu plan failed")
	}

	// Parse changes
	changes := tofu.ParsePlanOutput(result.Stdout)

	fmt.Println()
	if changes.Add > 0 || changes.Change > 0 || changes.Destroy > 0 {
		printInfo("Plan summary: %d to add, %d to change, %d to destroy",
			changes.Add, changes.Change, changes.Destroy)

		if planOut != "" {
			printSuccess("Plan saved to: %s", planFile)
			printInfo("Run 'stackkit apply %s' to apply this plan", planFile)
		} else {
			printInfo("Run 'stackkit apply' to apply these changes")
		}
	} else {
		printSuccess("No changes. Infrastructure is up-to-date.")
	}

	return nil
}

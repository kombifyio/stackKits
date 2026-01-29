package commands

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/pkg/models"
	"github.com/spf13/cobra"
)

var (
	initVariant       string
	initComputeTier   string
	initMode          string
	initOutputDir     string
	initForce         bool
	initNonInteractive bool
)

var initCmd = &cobra.Command{
	Use:   "init [stackkit]",
	Short: "Initialize a new deployment from a StackKit",
	Long: `Initialize a new deployment from a StackKit.

This command creates a new stack-spec.yaml file and sets up the deployment
directory structure based on the selected StackKit.

Examples:
  stackkit init                         Interactive mode
  stackkit init base-homelab            Initialize with base-homelab
  stackkit init base-homelab --variant minimal
  stackkit init ./my-stackkit           Initialize from local path`,
	Args: cobra.MaximumNArgs(1),
	RunE: runInit,
}

func init() {
	initCmd.Flags().StringVar(&initVariant, "variant", "default", "Service variant to use")
	initCmd.Flags().StringVar(&initComputeTier, "compute-tier", "minimal", "Compute tier (minimal, standard, performance)")
	initCmd.Flags().StringVar(&initMode, "mode", "simple", "Deployment mode (simple, advanced)")
	initCmd.Flags().StringVarP(&initOutputDir, "output", "o", "deploy", "Output directory for generated files")
	initCmd.Flags().BoolVarP(&initForce, "force", "f", false, "Overwrite existing files")
	initCmd.Flags().BoolVar(&initNonInteractive, "non-interactive", false, "Run in non-interactive mode (fail if input is required)")
}

func runInit(cmd *cobra.Command, args []string) error {
	wd := getWorkDir()

	// Determine StackKit name
	stackkitName := ""
	if len(args) > 0 {
		stackkitName = args[0]
	} else if initNonInteractive {
		return fmt.Errorf("stackkit name required in non-interactive mode")
	} else {
		// Interactive selection would go here
		printError("StackKit name required. Available StackKits:")
		fmt.Println("  • base-homelab    - Single-node homelab with Traefik + Dokploy")
		fmt.Println("  • modern-homelab  - Multi-node homelab with VPN overlay")
		fmt.Println("  • ha-homelab      - High-availability homelab with Kubernetes")
		return fmt.Errorf("run 'stackkit init <stackkit-name>' to initialize")
	}

	printInfo("Initializing StackKit: %s", bold(stackkitName))

	// Find StackKit directory
	loader := config.NewLoader(wd)
	stackkitDir, err := loader.FindStackKitDir(stackkitName)
	if err != nil {
		// Try parent directories for development
		parentDir := filepath.Dir(wd)
		loader = config.NewLoader(parentDir)
		stackkitDir, err = loader.FindStackKitDir(stackkitName)
		if err != nil {
			return fmt.Errorf("stackkit '%s' not found: %w", stackkitName, err)
		}
	}

	// Load StackKit
	stackkitPath := filepath.Join(stackkitDir, "stackkit.yaml")
	stackkit, err := loader.LoadStackKit(stackkitPath)
	if err != nil {
		return fmt.Errorf("failed to load stackkit: %w", err)
	}

	printSuccess("Found StackKit: %s v%s", stackkit.Metadata.Name, stackkit.Metadata.Version)

	// Validate variant
	validVariant := false
	var availableVariants []string
	for id := range stackkit.Variants {
		availableVariants = append(availableVariants, id)
		if id == initVariant {
			validVariant = true
		}
	}
	sort.Strings(availableVariants)
	if !validVariant {
		return fmt.Errorf("invalid variant '%s'. Available: %v", initVariant, availableVariants)
	}

	// Check for existing spec file
	specPath := filepath.Join(wd, specFile)
	if _, err := os.Stat(specPath); err == nil && !initForce {
		return fmt.Errorf("spec file already exists: %s (use --force to overwrite)", specPath)
	}

	// Create spec file
	spec := &models.StackSpec{
		Name:     filepath.Base(wd),
		StackKit: stackkitName,
		Variant:  initVariant,
		Mode:     initMode,
		Network: models.NetworkSpec{
			Mode:   "local",
			Subnet: "172.20.0.0/16",
		},
		Compute: models.ComputeSpec{
			Tier: initComputeTier,
		},
		SSH: models.SSHSpec{
			User: "root",
			Port: 22,
		},
	}

	// Save spec file
	if err := loader.SaveStackSpec(spec, specPath); err != nil {
		return fmt.Errorf("failed to save spec file: %w", err)
	}

	printSuccess("Created spec file: %s", specPath)

	// Create output directory
	outputPath := filepath.Join(wd, initOutputDir)
	if err := os.MkdirAll(outputPath, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	printSuccess("Created output directory: %s", outputPath)

	// Print next steps
	fmt.Println()
	printInfo("Next steps:")
	fmt.Printf("  1. Review configuration:  %s\n", cyan("cat "+specFile))
	fmt.Printf("  2. Prepare system:        %s\n", cyan("stackkit prepare --spec "+specFile))
	fmt.Printf("  3. Preview changes:       %s\n", cyan("stackkit plan"))
	fmt.Printf("  4. Deploy:                %s\n", cyan("stackkit apply"))

	return nil
}

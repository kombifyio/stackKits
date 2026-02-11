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
	initVariant        string
	initComputeTier    string
	initMode           string
	initOutputDir      string
	initForce          bool
	initNonInteractive bool
)

var initCmd = &cobra.Command{
	Use:   "init [stackkit]",
	Short: "Initialize a new deployment from a StackKit",
	Long: `Initialize a new deployment from a StackKit.

This command creates a new stack-spec.yaml file and sets up the deployment
directory structure based on the selected StackKit.

When run without arguments, an interactive wizard guides you through
StackKit selection, variant, compute tier, domain, and email.

Examples:
  stackkit init                         Interactive mode
  stackkit init base-homelab            Initialize with base-homelab
  stackkit init base-homelab --variant minimal
  stackkit init ./my-stackkit           Initialize from local path
  stackkit init --non-interactive       Fail if arguments are missing`,
	Args: cobra.MaximumNArgs(1),
	RunE: runInit,
}

func init() {
	initCmd.Flags().StringVar(&initVariant, "variant", "", "Service variant to use (default: auto)")
	initCmd.Flags().StringVar(&initComputeTier, "compute-tier", "", "Compute tier (low, standard, high)")
	initCmd.Flags().StringVar(&initMode, "mode", "", "Deployment mode (simple, advanced)")
	initCmd.Flags().StringVarP(&initOutputDir, "output", "o", "deploy", "Output directory for generated files")
	initCmd.Flags().BoolVarP(&initForce, "force", "f", false, "Overwrite existing files")
	initCmd.Flags().BoolVar(&initNonInteractive, "non-interactive", false, "Run in non-interactive mode (fail if input is required)")
}

func runInit(cmd *cobra.Command, args []string) error {
	wd := getWorkDir()

	// Discover available StackKits
	loader := config.NewLoader(wd)
	availableKits, err := discoverStackKits(loader, wd)
	if err != nil {
		return fmt.Errorf("failed to discover StackKits: %w", err)
	}

	stackkitName := ""
	if len(args) > 0 {
		stackkitName = args[0]
	}

	// Interactive mode when no stackkit given
	needsInteractive := stackkitName == "" || initVariant == "" || initComputeTier == "" || initMode == ""

	if needsInteractive && initNonInteractive {
		if stackkitName == "" {
			return fmt.Errorf("stackkit name required in non-interactive mode\n\nAvailable StackKits: %v", stackKitNames(availableKits))
		}
		// Apply defaults for missing flags in non-interactive mode
		if initVariant == "" {
			initVariant = "default"
		}
		if initComputeTier == "" {
			initComputeTier = "standard"
		}
		if initMode == "" {
			initMode = "simple"
		}
	}

	var p *prompter
	if stackkitName == "" || (needsInteractive && !initNonInteractive) {
		p = newPrompter()
	}

	// ── Step 1: Select StackKit ──────────────────────────────────
	if stackkitName == "" {
		if len(availableKits) == 0 {
			return fmt.Errorf("no StackKits found in %s", wd)
		}

		var choices []choice
		for _, sk := range availableKits {
			choices = append(choices, choice{
				Key:         sk.Metadata.Name,
				Display:     sk.Metadata.DisplayName,
				Description: sk.Metadata.Description,
			})
		}
		// Mark first as default
		if len(choices) > 0 {
			choices[0].IsDefault = true
		}

		selected, err := p.selectOne("Select a StackKit:", choices)
		if err != nil {
			return fmt.Errorf("stackkit selection: %w", err)
		}
		stackkitName = selected
	}

	printInfo("Initializing StackKit: %s", bold(stackkitName))

	// Find and load StackKit
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

	stackkitPath := filepath.Join(stackkitDir, "stackkit.yaml")
	stackkit, err := loader.LoadStackKit(stackkitPath)
	if err != nil {
		return fmt.Errorf("failed to load stackkit: %w", err)
	}

	printSuccess("Found StackKit: %s v%s", stackkit.Metadata.Name, stackkit.Metadata.Version)

	// ── Step 2: Select variant ───────────────────────────────────
	var availableVariants []string
	for id := range stackkit.Variants {
		availableVariants = append(availableVariants, id)
	}
	sort.Strings(availableVariants)

	if initVariant == "" && p != nil {
		var choices []choice
		for _, id := range availableVariants {
			v := stackkit.Variants[id]
			choices = append(choices, choice{
				Key:         id,
				Display:     v.DisplayName,
				Description: v.Description,
				IsDefault:   v.Default,
			})
		}
		selected, err := p.selectOne("Select a variant:", choices)
		if err != nil {
			return fmt.Errorf("variant selection: %w", err)
		}
		initVariant = selected
	}
	if initVariant == "" {
		initVariant = "default"
	}

	// Validate variant
	if _, ok := stackkit.Variants[initVariant]; !ok {
		return fmt.Errorf("invalid variant '%s'. Available: %v", initVariant, availableVariants)
	}

	// ── Step 3: Select deployment mode ───────────────────────────
	if initMode == "" && p != nil {
		var modeChoices []choice
		if stackkit.Modes.Simple.Name != "" {
			modeChoices = append(modeChoices, choice{
				Key:         "simple",
				Display:     stackkit.Modes.Simple.Name,
				Description: stackkit.Modes.Simple.Description,
				IsDefault:   stackkit.Modes.Simple.Default,
			})
		}
		if stackkit.Modes.Advanced.Name != "" {
			modeChoices = append(modeChoices, choice{
				Key:         "advanced",
				Display:     stackkit.Modes.Advanced.Name,
				Description: stackkit.Modes.Advanced.Description,
				IsDefault:   stackkit.Modes.Advanced.Default,
			})
		}
		if len(modeChoices) > 1 {
			selected, err := p.selectOne("Select deployment mode:", modeChoices)
			if err != nil {
				return fmt.Errorf("mode selection: %w", err)
			}
			initMode = selected
		} else if len(modeChoices) == 1 {
			initMode = modeChoices[0].Key
		}
	}
	if initMode == "" {
		initMode = "simple"
	}

	// ── Step 4: Select compute tier ──────────────────────────────
	if initComputeTier == "" && p != nil {
		tierChoices := []choice{
			{Key: "low", Display: "Low", Description: fmt.Sprintf("Minimum: %d CPU / %d GB RAM / %d GB disk",
				stackkit.Requirements.Minimum.CPU, stackkit.Requirements.Minimum.RAM, stackkit.Requirements.Minimum.Disk)},
			{Key: "standard", Display: "Standard", Description: "Balanced resources for typical workloads", IsDefault: true},
			{Key: "high", Display: "High", Description: fmt.Sprintf("Recommended: %d CPU / %d GB RAM / %d GB disk",
				stackkit.Requirements.Recommended.CPU, stackkit.Requirements.Recommended.RAM, stackkit.Requirements.Recommended.Disk)},
		}
		selected, err := p.selectOne("Select compute tier:", tierChoices)
		if err != nil {
			return fmt.Errorf("compute tier selection: %w", err)
		}
		initComputeTier = selected
	}
	if initComputeTier == "" {
		initComputeTier = "standard"
	}

	// ── Step 5: Domain & email (optional) ────────────────────────
	domain := ""
	email := ""
	if p != nil && !initNonInteractive {
		fmt.Println()
		printInfo("Optional configuration (press Enter to skip):")
		fmt.Println()

		d, err := p.inputString("Domain (e.g. home.example.com)", "")
		if err == nil {
			domain = d
		}

		e, err := p.inputString("Email (for Let's Encrypt certificates)", "")
		if err == nil {
			email = e
		}
	}

	// ── Step 6: Check for existing spec ──────────────────────────
	specPath := specFile
	if !filepath.IsAbs(specFile) {
		specPath = filepath.Join(wd, specFile)
	}
	if _, err := os.Stat(specPath); err == nil && !initForce {
		return fmt.Errorf("spec file already exists: %s (use --force to overwrite)", specPath)
	}

	// ── Step 7: Create spec file ─────────────────────────────────
	spec := &models.StackSpec{
		Name:     filepath.Base(wd),
		StackKit: stackkitName,
		Variant:  initVariant,
		Mode:     initMode,
		Domain:   domain,
		Email:    email,
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

	// Print summary & next steps
	fmt.Println()
	printInfo("Configuration:")
	fmt.Printf("  %s: %s\n", bold("StackKit"), stackkitName)
	fmt.Printf("  %s: %s\n", bold("Variant"), initVariant)
	fmt.Printf("  %s: %s\n", bold("Mode"), initMode)
	fmt.Printf("  %s: %s\n", bold("Compute"), initComputeTier)
	if domain != "" {
		fmt.Printf("  %s: %s\n", bold("Domain"), domain)
	}
	if email != "" {
		fmt.Printf("  %s: %s\n", bold("Email"), email)
	}

	fmt.Println()
	printInfo("Next steps:")
	fmt.Printf("  1. Review configuration:  %s\n", cyan("cat "+specFile))
	fmt.Printf("  2. Prepare system:        %s\n", cyan("stackkit prepare --spec "+specFile))
	fmt.Printf("  3. Preview changes:       %s\n", cyan("stackkit plan"))
	fmt.Printf("  4. Deploy:                %s\n", cyan("stackkit apply"))

	return nil
}

// discoverStackKits scans the working directory (and parent) for stackkit.yaml files.
func discoverStackKits(loader *config.Loader, wd string) ([]*models.StackKit, error) {
	var kits []*models.StackKit
	seen := make(map[string]bool)

	scanDir := func(baseDir string) {
		entries, err := os.ReadDir(baseDir)
		if err != nil {
			return
		}
		for _, entry := range entries {
			if !entry.IsDir() {
				continue
			}
			yamlPath := filepath.Join(baseDir, entry.Name(), "stackkit.yaml")
			if _, err := os.Stat(yamlPath); err != nil {
				continue
			}
			sk, err := loader.LoadStackKit(yamlPath)
			if err != nil || seen[sk.Metadata.Name] {
				continue
			}
			seen[sk.Metadata.Name] = true
			kits = append(kits, sk)
		}
	}

	scanDir(wd)
	scanDir(filepath.Dir(wd)) // parent dir (for dev setups)

	sort.Slice(kits, func(i, j int) bool { return kits[i].Metadata.Name < kits[j].Metadata.Name })
	return kits, nil
}

// stackKitNames returns a sorted list of StackKit names.
func stackKitNames(kits []*models.StackKit) []string {
	var names []string
	for _, k := range kits {
		names = append(names, k.Metadata.Name)
	}
	return names
}

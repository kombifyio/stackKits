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
  stackkit init base-kit            Initialize with base-kit
  stackkit init base-kit --variant minimal
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

// selectStackKit prompts the user to pick a StackKit or returns the one
// already provided via CLI args. Returns the selected name.
func selectStackKit(p *prompter, availableKits []*models.StackKit, wd string) (string, error) {
	if len(availableKits) == 0 {
		return "", fmt.Errorf("no StackKits found in %s", wd)
	}

	var choices []choice
	for _, sk := range availableKits {
		choices = append(choices, choice{
			Key:         sk.Metadata.Name,
			Display:     sk.Metadata.DisplayName,
			Description: sk.Metadata.Description,
		})
	}
	if len(choices) > 0 {
		choices[0].IsDefault = true
	}

	selected, err := p.selectOne("Select a StackKit:", choices)
	if err != nil {
		return "", fmt.Errorf("stackkit selection: %w", err)
	}
	return selected, nil
}

// selectVariant prompts for a variant or applies the default.
func selectVariant(p *prompter, stackkit *models.StackKit) (string, error) {
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
			return "", fmt.Errorf("variant selection: %w", err)
		}
		initVariant = selected
	}
	if initVariant == "" {
		initVariant = "default"
	}

	if _, ok := stackkit.Variants[initVariant]; !ok {
		return "", fmt.Errorf("invalid variant '%s'. Available: %v", initVariant, availableVariants)
	}
	return initVariant, nil
}

// selectMode prompts for a deployment mode or applies the default.
func selectMode(p *prompter, stackkit *models.StackKit) (string, error) {
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
				return "", fmt.Errorf("mode selection: %w", err)
			}
			initMode = selected
		} else if len(modeChoices) == 1 {
			initMode = modeChoices[0].Key
		}
	}
	if initMode == "" {
		initMode = "simple"
	}
	return initMode, nil
}

// selectComputeTier prompts for a compute tier or applies the default.
func selectComputeTier(p *prompter, stackkit *models.StackKit) (string, error) {
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
			return "", fmt.Errorf("compute tier selection: %w", err)
		}
		initComputeTier = selected
	}
	if initComputeTier == "" {
		initComputeTier = "standard"
	}
	return initComputeTier, nil
}

// promptOptionalConfig asks for domain and email when running interactively.
func promptOptionalConfig(p *prompter) (domain string, email string) {
	if p == nil || initNonInteractive {
		return "", ""
	}

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
	return domain, email
}

// applyNonInteractiveDefaults fills in missing flag values when running
// without a TTY. Returns an error if the stackkit name is missing.
func applyNonInteractiveDefaults(stackkitName string, availableKits []*models.StackKit) error {
	if stackkitName == "" {
		return fmt.Errorf("stackkit name required in non-interactive mode\n\nAvailable StackKits: %v", stackKitNames(availableKits))
	}
	if initVariant == "" {
		initVariant = "default"
	}
	if initComputeTier == "" {
		initComputeTier = "standard"
	}
	if initMode == "" {
		initMode = "simple"
	}
	return nil
}

// loadStackKit finds and loads a StackKit definition, falling back to the
// parent directory for development layouts.
func loadStackKit(loader *config.Loader, stackkitName, wd string) (*config.Loader, *models.StackKit, error) {
	stackkitDir, err := loader.FindStackKitDir(stackkitName)
	if err != nil {
		parentDir := filepath.Dir(wd)
		loader = config.NewLoader(parentDir)
		stackkitDir, err = loader.FindStackKitDir(stackkitName)
		if err != nil {
			return nil, nil, fmt.Errorf("stackkit '%s' not found: %w", stackkitName, err)
		}
	}

	stackkitPath := filepath.Join(stackkitDir, "stackkit.yaml")
	stackkit, err := loader.LoadStackKit(stackkitPath)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to load stackkit: %w", err)
	}
	return loader, stackkit, nil
}

// resolveSpecPath returns the absolute path for the spec file and checks
// whether it already exists (unless --force is set).
func resolveSpecPath(wd string) (string, error) {
	specPath := specFile
	if !filepath.IsAbs(specFile) {
		specPath = filepath.Join(wd, specFile)
	}
	if _, err := os.Stat(specPath); err == nil && !initForce {
		return "", fmt.Errorf("spec file already exists: %s (use --force to overwrite)", specPath)
	}
	return specPath, nil
}

// writeSpecAndOutput creates the spec YAML and the output directory.
func writeSpecAndOutput(loader *config.Loader, spec *models.StackSpec, specPath, wd string) error {
	if err := loader.SaveStackSpec(spec, specPath); err != nil {
		return fmt.Errorf("failed to save spec file: %w", err)
	}
	printSuccess("Created spec file: %s", specPath)

	outputPath := filepath.Join(wd, initOutputDir)
	if err := os.MkdirAll(outputPath, 0750); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}
	printSuccess("Created output directory: %s", outputPath)
	return nil
}

// printInitSummary displays the final configuration and next-step hints.
func printInitSummary(stackkitName, variant, mode, computeTier, domain, email string) {
	fmt.Println()
	printInfo("Configuration:")
	fmt.Printf("  %s: %s\n", bold("StackKit"), stackkitName)
	fmt.Printf("  %s: %s\n", bold("Variant"), variant)
	fmt.Printf("  %s: %s\n", bold("Mode"), mode)
	fmt.Printf("  %s: %s\n", bold("Compute"), computeTier)
	fmt.Printf("  %s: %s\n", bold("Context"), contextOrDefault(contextFlag))
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
}

// resolveStackKitName determines the StackKit name from CLI args, applying
// non-interactive defaults or prompting the user as needed. It also returns
// a prompter when interactive input is available.
func resolveStackKitName(args []string, availableKits []*models.StackKit, wd string) (string, *prompter, error) {
	stackkitName := ""
	if len(args) > 0 {
		stackkitName = args[0]
	}

	needsInteractive := stackkitName == "" || initVariant == "" || initComputeTier == "" || initMode == ""

	if needsInteractive && initNonInteractive {
		if err := applyNonInteractiveDefaults(stackkitName, availableKits); err != nil {
			return "", nil, err
		}
	}

	var p *prompter
	if stackkitName == "" || (needsInteractive && !initNonInteractive) {
		p = newPrompter()
	}

	if stackkitName == "" {
		selected, err := selectStackKit(p, availableKits, wd)
		if err != nil {
			return "", nil, err
		}
		stackkitName = selected
	}

	return stackkitName, p, nil
}

// gatherInitChoices prompts (or defaults) all user choices for the init wizard.
func gatherInitChoices(p *prompter, stackkit *models.StackKit) (variant, mode, computeTier, domain, email string, err error) {
	variant, err = selectVariant(p, stackkit)
	if err != nil {
		return
	}

	mode, err = selectMode(p, stackkit)
	if err != nil {
		return
	}

	computeTier, err = selectComputeTier(p, stackkit)
	if err != nil {
		return
	}

	domain, email = promptOptionalConfig(p)
	return
}

func runInit(cmd *cobra.Command, args []string) error {
	wd := getWorkDir()

	loader := config.NewLoader(wd)
	availableKits, err := discoverStackKits(loader, wd)
	if err != nil {
		return fmt.Errorf("failed to discover StackKits: %w", err)
	}

	stackkitName, p, err := resolveStackKitName(args, availableKits, wd)
	if err != nil {
		return err
	}

	printInfo("Initializing StackKit: %s", bold(stackkitName))

	loader, stackkit, err := loadStackKit(loader, stackkitName, wd)
	if err != nil {
		return err
	}
	printSuccess("Found StackKit: %s v%s", stackkit.Metadata.Name, stackkit.Metadata.Version)

	variant, mode, computeTier, domain, email, err := gatherInitChoices(p, stackkit)
	if err != nil {
		return err
	}

	specPath, err := resolveSpecPath(wd)
	if err != nil {
		return err
	}

	spec := &models.StackSpec{
		Name:     filepath.Base(wd),
		StackKit: stackkitName,
		Variant:  variant,
		Mode:     mode,
		Domain:   domain,
		Email:    email,
		Network: models.NetworkSpec{
			Mode:   "local",
			Subnet: "172.20.0.0/16",
		},
		Compute: models.ComputeSpec{
			Tier: computeTier,
		},
		SSH: models.SSHSpec{
			User: "root",
			Port: 22,
		},
	}

	if err := writeSpecAndOutput(loader, spec, specPath, wd); err != nil {
		return err
	}

	printInitSummary(stackkitName, variant, mode, computeTier, domain, email)
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

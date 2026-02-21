package commands

import (
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/kombihq/stackkits/internal/config"
	cuepkg "github.com/kombihq/stackkits/internal/cue"
	"github.com/kombihq/stackkits/internal/template"
	"github.com/kombihq/stackkits/pkg/models"
	"github.com/spf13/cobra"
)

var (
	genOutputDir string
	genForce     bool
)

var generateCmd = &cobra.Command{
	Use:     "generate",
	Aliases: []string{"gen"},
	Short:   "Generate OpenTofu files from stack specification",
	Long: `Generate OpenTofu configuration files from your stack specification.

This command reads your stack-spec.yaml and the associated StackKit templates
to generate ready-to-apply OpenTofu files in the output directory.

Examples:
  stackkit generate                     Generate using defaults
  stackkit generate -o ./terraform      Output to custom directory
  stackkit generate --force             Overwrite existing files`,
	RunE: runGenerate,
}

func init() {
	generateCmd.Flags().StringVarP(&genOutputDir, "output", "o", "deploy", "Output directory for generated files")
	generateCmd.Flags().BoolVarP(&genForce, "force", "f", false, "Overwrite existing files")
}

func runGenerate(cmd *cobra.Command, args []string) error {
	wd := getWorkDir()

	// Load spec (loader.resolvePath handles absolute vs relative paths)
	loader := config.NewLoader(wd)

	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		return fmt.Errorf("failed to load spec file: %w", err)
	}

	// Apply --context flag override if provided
	if contextFlag != "" {
		spec.Context = contextFlag
	}

	printInfo("Generating OpenTofu files for: %s", bold(spec.Name))
	printInfo("StackKit: %s, Variant: %s, Mode: %s, Context: %s", spec.StackKit, spec.Variant, spec.Mode, contextOrDefault(spec.Context))

	// Find StackKit directory
	stackkitDir, err := loader.FindStackKitDir(spec.StackKit)
	if err != nil {
		// Try parent directories for development
		parentDir := filepath.Dir(wd)
		loader = config.NewLoader(parentDir)
		stackkitDir, err = loader.FindStackKitDir(spec.StackKit)
		if err != nil {
			return fmt.Errorf("stackkit '%s' not found: %w", spec.StackKit, err)
		}
	}

	// Load StackKit
	stackkitPath := filepath.Join(stackkitDir, "stackkit.yaml")
	stackkit, err := loader.LoadStackKit(stackkitPath)
	if err != nil {
		return fmt.Errorf("failed to load stackkit: %w", err)
	}

	// Determine template directory based on mode
	templateDir := filepath.Join(stackkitDir, "templates", spec.Mode)
	if _, err := os.Stat(templateDir); os.IsNotExist(err) {
		// Fall back to simple mode
		templateDir = filepath.Join(stackkitDir, "templates", "simple")
		if _, err := os.Stat(templateDir); os.IsNotExist(err) {
			return fmt.Errorf("no templates found for mode '%s' in %s", spec.Mode, stackkitDir)
		}
	}

	// Create output directory
	outputPath := filepath.Join(wd, genOutputDir)
	if _, err := os.Stat(outputPath); err == nil && !genForce {
		return fmt.Errorf("output directory already exists: %s (use --force to overwrite)", outputPath)
	}

	if err := os.MkdirAll(outputPath, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Check if templates use Go templating or are plain files
	err = copyOrRenderTemplates(templateDir, outputPath, spec, stackkit)
	if err != nil {
		return fmt.Errorf("failed to generate files: %w", err)
	}

	// Generate main.tf if not present
	mainTfPath := filepath.Join(outputPath, "main.tf")
	if _, err := os.Stat(mainTfPath); os.IsNotExist(err) {
		// Generate a basic main.tf
		renderCtx := &template.RenderContext{
			Spec:     spec,
			StackKit: stackkit,
		}
		mainTf := template.GenerateMainTf(renderCtx)
		if err := os.WriteFile(mainTfPath, []byte(mainTf), 0644); err != nil {
			return fmt.Errorf("failed to write main.tf: %w", err)
		}
		printSuccess("Generated: main.tf")
	}

	// Generate terraform.tfvars.json from spec via CUE bridge
	bridge := cuepkg.NewTerraformBridge(stackkitDir)
	if err := bridge.GenerateTFVarsFromSpec(spec, outputPath); err != nil {
		return fmt.Errorf("failed to generate terraform.tfvars.json: %w", err)
	}
	printSuccess("Generated: terraform.tfvars.json")

	// Print summary
	files, _ := countFiles(outputPath)
	fmt.Println()
	printSuccess("Generated %d files in: %s", files, outputPath)

	// Print next steps
	fmt.Println()
	printInfo("Next steps:")
	fmt.Printf("  1. Review generated files: %s\n", cyan("ls "+genOutputDir))
	fmt.Printf("  2. Initialize OpenTofu:    %s\n", cyan("cd "+genOutputDir+" && tofu init"))
	fmt.Printf("  3. Or use StackKit:        %s\n", cyan("stackkit plan"))

	return nil
}

// copyOrRenderTemplates renders template files using the template.Renderer,
// falling back to plain copy for non-template files.
func copyOrRenderTemplates(srcDir, dstDir string, spec *models.StackSpec, stackkit *models.StackKit) error {
	renderer := template.NewRenderer(srcDir, dstDir)
	renderCtx := &template.RenderContext{
		Spec:     spec,
		StackKit: stackkit,
	}
	return renderer.Render(renderCtx)
}

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	srcFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	dstFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer dstFile.Close()

	_, err = io.Copy(dstFile, srcFile)
	return err
}

// Note: generateTfvarsJSON has been replaced by the CUE bridge's
// GenerateTFVarsFromSpec method for a single canonical code path.

// countFiles counts files in a directory
func countFiles(dir string) (int, error) {
	count := 0
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			count++
		}
		return nil
	})
	return count, err
}

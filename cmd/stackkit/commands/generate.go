package commands

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/template"
	"github.com/kombihq/stackkits/pkg/models"
	"github.com/spf13/cobra"
)

// getDockerHost returns the Docker host from environment or empty string
func getDockerHost() string {
	if host := os.Getenv("DOCKER_HOST"); host != "" {
		return host
	}
	return ""
}

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

	// Load spec
	specPath := filepath.Join(wd, specFile)
	loader := config.NewLoader(wd)

	spec, err := loader.LoadStackSpec(specPath)
	if err != nil {
		return fmt.Errorf("failed to load spec file: %w", err)
	}

	printInfo("Generating OpenTofu files for: %s", bold(spec.Name))
	printInfo("StackKit: %s, Variant: %s, Mode: %s", spec.StackKit, spec.Variant, spec.Mode)

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

	// Generate terraform.tfvars.json from spec (JSON format for consistency with API)
	tfvarsPath := filepath.Join(outputPath, "terraform.tfvars.json")
	tfvarsData := generateTfvarsJSON(spec)
	if err := os.WriteFile(tfvarsPath, tfvarsData, 0644); err != nil {
		return fmt.Errorf("failed to write terraform.tfvars.json: %w", err)
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

// generateTfvarsJSON generates terraform.tfvars.json content from spec (JSON format).
// This matches the API's output format for consistency.
func generateTfvarsJSON(spec *models.StackSpec) []byte {
	vars := make(map[string]interface{})

	// Docker host from environment (for remote Docker daemon)
	if dockerHost := getDockerHost(); dockerHost != "" {
		vars["docker_host"] = dockerHost
	}

	// Basic settings
	if spec.Domain != "" {
		vars["domain"] = spec.Domain
	} else {
		vars["domain"] = "example.local"
	}

	if spec.Email != "" {
		vars["acme_email"] = spec.Email
	} else {
		vars["acme_email"] = "admin@example.com"
	}

	// Variant
	if spec.Variant != "" {
		vars["variant"] = spec.Variant
	}

	// Compute tier
	if spec.Compute.Tier != "" && spec.Compute.Tier != "auto" {
		vars["compute_tier"] = spec.Compute.Tier
	}

	// Network settings
	if spec.Network.Mode == "public" {
		vars["network_mode"] = "public"
	}

	data, err := json.MarshalIndent(vars, "", "  ")
	if err != nil {
		// Should never happen with simple map, but log and fall back
		return []byte("{}")
	}
	return append(data, '\n')
}

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

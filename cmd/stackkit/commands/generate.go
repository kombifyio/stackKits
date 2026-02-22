package commands

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/kombihq/stackkits/internal/config"
	cueval "github.com/kombihq/stackkits/internal/cue"
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

	// Validate CUE schemas before generating
	cueValidator := cueval.NewValidator(wd)
	if cueResult, valErr := cueValidator.ValidateStackKit(stackkitDir); valErr != nil {
		printWarning("CUE validation: %v", valErr)
	} else if !cueResult.Valid {
		for _, e := range cueResult.Errors {
			printWarning("CUE: %s: %s", e.Path, e.Message)
		}
	}

	// Determine template directory based on mode
	templateDir := filepath.Join(stackkitDir, "templates", spec.Mode)
	if _, statErr := os.Stat(templateDir); os.IsNotExist(statErr) {
		// Fall back to simple mode
		templateDir = filepath.Join(stackkitDir, "templates", "simple")
		if _, statErr2 := os.Stat(templateDir); os.IsNotExist(statErr2) {
			return fmt.Errorf("no templates found for mode '%s' in %s", spec.Mode, stackkitDir)
		}
	}

	// Create output directory
	outputPath := filepath.Join(wd, genOutputDir)
	if _, statErr := os.Stat(outputPath); statErr == nil && !genForce {
		return fmt.Errorf("output directory already exists: %s (use --force to overwrite)", outputPath)
	}

	if mkdirErr := os.MkdirAll(outputPath, 0750); mkdirErr != nil {
		return fmt.Errorf("failed to create output directory: %w", mkdirErr)
	}

	// Check if templates use Go templating or are plain files
	err = copyOrRenderTemplates(templateDir, outputPath, spec, stackkit)
	if err != nil {
		return fmt.Errorf("failed to generate files: %w", err)
	}

	// Generate main.tf if not present
	mainTfPath := filepath.Join(outputPath, "main.tf")
	if _, statErr := os.Stat(mainTfPath); os.IsNotExist(statErr) {
		// Generate a basic main.tf
		renderCtx := &template.RenderContext{
			Spec:     spec,
			StackKit: stackkit,
		}
		mainTf := template.GenerateMainTf(renderCtx)
		if err := os.WriteFile(mainTfPath, []byte(mainTf), 0600); err != nil {
			return fmt.Errorf("failed to write main.tf: %w", err)
		}
		printSuccess("Generated: main.tf")
	}

	// Generate terraform.tfvars.json from spec (JSON format for consistency with API)
	tfvarsPath := filepath.Join(outputPath, "terraform.tfvars.json")
	tfvarsData := generateTfvarsJSON(spec)
	if err := os.WriteFile(tfvarsPath, tfvarsData, 0600); err != nil {
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

// generateTfvarsJSON generates terraform.tfvars.json matching the template variables.
// The template (main.tf) uses these variables to configure which services are deployed.
func generateTfvarsJSON(spec *models.StackSpec) []byte {
	vars := make(map[string]interface{})

	// Domain
	if spec.Domain != "" {
		vars["domain"] = spec.Domain
	} else {
		vars["domain"] = "stack.local"
	}

	// Network
	vars["network_name"] = "base_net"
	if spec.Network.Subnet != "" {
		vars["network_subnet"] = spec.Network.Subnet
	} else {
		vars["network_subnet"] = "172.20.0.0/16"
	}

	// Service enablement based on variant
	variant := spec.Variant
	if variant == "" {
		variant = "default"
	}

	switch variant {
	case "default", "secure":
		vars["enable_traefik"] = true
		vars["enable_tinyauth"] = true
		vars["enable_pocketid"] = true
		vars["enable_dokploy"] = true
		vars["enable_dokploy_apps"] = true
		vars["enable_dashboard"] = true
	case "beszel":
		vars["enable_traefik"] = true
		vars["enable_tinyauth"] = true
		vars["enable_pocketid"] = true
		vars["enable_dokploy"] = true
		vars["enable_dokploy_apps"] = true
		vars["enable_dashboard"] = true
	case "minimal":
		vars["enable_traefik"] = true
		vars["enable_tinyauth"] = false
		vars["enable_pocketid"] = false
		vars["enable_dokploy"] = false
		vars["enable_dokploy_apps"] = false
		vars["enable_dashboard"] = false
	}

	// TinyAuth configuration
	domain := vars["domain"].(string)
	vars["tinyauth_app_url"] = fmt.Sprintf("http://auth.%s", domain)
	vars["tinyauth_users"] = "admin:$2y$10$2aSDNcypqNOcOSOXkmQlSO0MBxZcUeRRtsU/gDZBIwWws.Oly8AYC"

	// Dashboard
	vars["brand_color"] = "#F97316"
	if spec.Name != "" {
		vars["dashboard_title"] = spec.Name
	} else {
		vars["dashboard_title"] = "My Homelab"
	}

	// Allow spec-level service overrides
	if spec.Services != nil {
		for name, cfg := range spec.Services {
			if cfgMap, ok := cfg.(map[string]interface{}); ok {
				if enabled, exists := cfgMap["enabled"]; exists {
					vars["enable_"+name] = enabled
				}
			}
		}
	}

	data, err := json.MarshalIndent(vars, "", "  ")
	if err != nil {
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

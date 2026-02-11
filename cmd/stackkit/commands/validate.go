package commands

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/cue"
	"github.com/kombihq/stackkits/internal/iac"
	"github.com/kombihq/stackkits/internal/tofu"
	"github.com/spf13/cobra"
)

var (
	validateAll bool
)

var validateCmd = &cobra.Command{
	Use:   "validate [file]",
	Short: "Validate configuration files",
	Long: `Validate spec files and CUE schemas.

This command validates:
  • stack-spec.yaml against the schema
  • StackKit CUE definitions
  • OpenTofu configuration files

Examples:
  stackkit validate                  Validate current spec
  stackkit validate spec.yaml        Validate specific file
  stackkit validate --all            Validate all files`,
	Args: cobra.MaximumNArgs(1),
	RunE: runValidate,
}

func init() {
	validateCmd.Flags().BoolVar(&validateAll, "all", false, "Validate all configuration files")
}

func runValidate(cmd *cobra.Command, args []string) error {
	wd := getWorkDir()
	loader := config.NewLoader(wd)
	validator := cue.NewValidator(wd)

	hasErrors := false

	// Determine what to validate
	targetFile := specFile
	if len(args) > 0 {
		targetFile = args[0]
	}

	// Validate spec file
	printInfo("Validating %s...", targetFile)

	spec, err := loader.LoadStackSpec(targetFile)
	if err != nil {
		if os.IsNotExist(err) {
			printWarning("Spec file not found: %s", targetFile)
		} else {
			printError("Failed to load spec: %v", err)
			hasErrors = true
		}
	} else {
		result, err := validator.ValidateSpec(spec)
		if err != nil {
			printError("Validation error: %v", err)
			hasErrors = true
		} else if !result.Valid {
			printError("Spec validation failed:")
			for _, e := range result.Errors {
				fmt.Printf("  • %s: %s\n", red(e.Path), e.Message)
			}
			hasErrors = true
		} else {
			printSuccess("Spec file is valid")

			for _, w := range result.Warnings {
				printWarning("%s: %s", w.Path, w.Message)
			}
		}
	}

	// Validate all CUE files if requested
	if validateAll {
		fmt.Println()
		printInfo("Validating CUE schemas...")

		cueFiles, err := findCUEFiles(wd)
		if err != nil {
			printWarning("Could not find CUE files: %v", err)
		} else {
			for _, cueFile := range cueFiles {
				relPath, _ := filepath.Rel(wd, cueFile)
				result, err := validator.ValidateCUEFile(cueFile)
				if err != nil {
					printError("%s: %v", relPath, err)
					hasErrors = true
				} else if !result.Valid {
					printError("%s:", relPath)
					for _, e := range result.Errors {
						fmt.Printf("  • %s\n", e.Message)
					}
					hasErrors = true
				} else {
					printSuccess("%s is valid", relPath)
				}
			}
		}
	}

	// Validate OpenTofu files
	deployDir := filepath.Join(wd, config.GetDeployDir())
	if _, err := os.Stat(deployDir); err == nil {
		fmt.Println()
		printInfo("Validating OpenTofu configuration...")

		hasTF, err := tofu.HasTerraformFiles(deployDir)
		if err != nil {
			printWarning("Could not check for .tf files: %v", err)
		} else if !hasTF {
			printWarning("No .tf files found in %s", deployDir)
		} else {
			// Use unified iac executor — mode determined from spec
			var executor iac.Executor
			if spec != nil {
				executor, err = iac.NewExecutorFromSpec(spec, deployDir)
			} else {
				executor, err = iac.NewExecutor(&iac.Config{WorkDir: deployDir, Mode: iac.ModeOpenTofu})
			}
			if err != nil {
				printError("Failed to create executor: %v", err)
				hasErrors = true
			} else if !executor.IsInstalled() {
				printWarning("%s is not installed — skipping validate", executor.Mode())
			} else {
				// Initialize if needed (validate requires init)
				tfStatePath := filepath.Join(deployDir, ".terraform")
				if _, err := os.Stat(tfStatePath); os.IsNotExist(err) {
					printInfo("Initializing %s...", executor.Mode())
					ctx := context.Background()
					if initErr := executor.Init(ctx); initErr != nil {
						printError("Init error: %v", initErr)
						hasErrors = true
					}
				}

				if !hasErrors {
					ctx := context.Background()
					result, err := executor.Validate(ctx)
					if err != nil {
						printError("Validate error: %v", err)
						hasErrors = true
					} else if !result.Success {
						printError("Validation failed:")
						// Parse JSON output from tofu validate -json
						var valResult struct {
							Valid       bool `json:"valid"`
							ErrorCount  int  `json:"error_count"`
							Diagnostics []struct {
								Severity string `json:"severity"`
								Summary  string `json:"summary"`
								Detail   string `json:"detail"`
							} `json:"diagnostics"`
						}
						if jsonErr := json.Unmarshal([]byte(result.Stdout), &valResult); jsonErr == nil {
							for _, d := range valResult.Diagnostics {
								if d.Severity == "error" {
									fmt.Printf("  • %s: %s\n", red(d.Summary), d.Detail)
								} else {
									printWarning("%s: %s", d.Summary, d.Detail)
								}
							}
						} else {
							// Fallback: print raw output
							if result.Stderr != "" {
								fmt.Println(result.Stderr)
							}
							if result.Stdout != "" {
								fmt.Println(result.Stdout)
							}
						}
						hasErrors = true
					} else {
						printSuccess("IaC configuration is valid")
					}
				}
			}
		}
	}

	fmt.Println()
	if hasErrors {
		return fmt.Errorf("validation failed")
	}

	printSuccess("All validations passed!")
	return nil
}

func findCUEFiles(dir string) ([]string, error) {
	var files []string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		// Skip hidden directories and node_modules
		if info.IsDir() {
			name := info.Name()
			if name == "node_modules" || name == ".git" || name == "cue.mod" {
				return filepath.SkipDir
			}
		}
		// Include .cue files
		if !info.IsDir() && filepath.Ext(path) == ".cue" {
			files = append(files, path)
		}
		return nil
	})

	return files, err
}

// Package commands implements the CLI commands for stackkit.
package commands

import (
	"fmt"
	"os"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	version   = "dev"
	gitCommit = "unknown"
	buildDate = "unknown"
)

// SetVersionInfo sets version information from build
func SetVersionInfo(v, gc, bd string) {
	version = v
	gitCommit = gc
	buildDate = bd
}

// Color helpers
var (
	green  = color.New(color.FgGreen).SprintFunc()
	yellow = color.New(color.FgYellow).SprintFunc()
	red    = color.New(color.FgRed).SprintFunc()
	cyan   = color.New(color.FgCyan).SprintFunc()
	bold   = color.New(color.Bold).SprintFunc()
)

// Global flags
var (
	verbose     bool
	quiet       bool
	workDir     string
	specFile    string
	contextFlag string
)

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "stackkit",
	Short: "StackKit CLI - Infrastructure deployment from declarative blueprints",
	Long: `StackKit CLI enables infrastructure deployment directly from the terminal.

It handles:
  • StackKit discovery and selection
  • Configuration validation (CUE)
  • OpenTofu execution
  • Drift detection and updates
  • System prerequisites (Docker, OpenTofu)

Examples:
  stackkit init base-homelab           Initialize a new deployment
  stackkit prepare --spec spec.yaml    Prepare system and validate spec
  stackkit plan                        Preview infrastructure changes
  stackkit apply                       Apply infrastructure changes
  stackkit status                      Check deployment status
  stackkit destroy                     Tear down deployment`,
	SilenceUsage: true,
}

// Execute runs the root command
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "Enable verbose output")
	rootCmd.PersistentFlags().BoolVarP(&quiet, "quiet", "q", false, "Suppress non-essential output")
	rootCmd.PersistentFlags().StringVarP(&workDir, "chdir", "C", ".", "Change to directory before running")
	rootCmd.PersistentFlags().StringVarP(&specFile, "spec", "s", "stack-spec.yaml", "Path to stack specification file")
	rootCmd.PersistentFlags().StringVar(&contextFlag, "context", "", "Node context override (local, cloud, pi). Auto-detected if omitted.")

	// Add subcommands
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(prepareCmd)
	rootCmd.AddCommand(generateCmd)
	rootCmd.AddCommand(planCmd)
	rootCmd.AddCommand(applyCmd)
	rootCmd.AddCommand(destroyCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(validateCmd)
	rootCmd.AddCommand(versionCmd)
	rootCmd.AddCommand(completionCmd)
	rootCmd.AddCommand(addonCmd)
}

// Helper functions for output

// printSuccess prints a success message
func printSuccess(format string, args ...interface{}) {
	if !quiet {
		fmt.Printf("%s %s\n", green("✓"), fmt.Sprintf(format, args...))
	}
}

// printWarning prints a warning message
func printWarning(format string, args ...interface{}) {
	if !quiet {
		fmt.Printf("%s %s\n", yellow("⚠"), fmt.Sprintf(format, args...))
	}
}

// printError prints an error message
func printError(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "%s %s\n", red("✗"), fmt.Sprintf(format, args...))
}

// printInfo prints an info message
func printInfo(format string, args ...interface{}) {
	if !quiet {
		fmt.Printf("%s %s\n", cyan("ℹ"), fmt.Sprintf(format, args...))
	}
}

// printVerbose prints verbose output
func printVerbose(format string, args ...interface{}) {
	if verbose {
		fmt.Printf("  %s\n", fmt.Sprintf(format, args...))
	}
}

// contextOrDefault returns the context display string
func contextOrDefault(ctx string) string {
	if ctx == "" {
		return "auto-detect"
	}
	return ctx
}

// getWorkDir returns the effective working directory
func getWorkDir() string {
	if workDir != "." {
		return workDir
	}
	wd, err := os.Getwd()
	if err != nil {
		return "."
	}
	return wd
}

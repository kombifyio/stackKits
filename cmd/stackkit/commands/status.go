package commands

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"github.com/kombihq/stackkits/internal/config"
	"github.com/kombihq/stackkits/internal/docker"
	"github.com/kombihq/stackkits/pkg/models"
	"github.com/olekukonko/tablewriter"
	"github.com/spf13/cobra"
)

var (
	statusJson bool
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show deployment status",
	Long: `Display the current status of the StackKit deployment.

Shows:
  • Deployment state (running, degraded, error)
  • Service statuses and health
  • Resource usage
  • URLs and endpoints

Examples:
  stackkit status            Show status
  stackkit status --json     Output as JSON`,
	RunE: runStatus,
}

func init() {
	statusCmd.Flags().BoolVar(&statusJson, "json", false, "Output as JSON")
}

func runStatus(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	wd := getWorkDir()

	// Load spec
	loader := config.NewLoader(wd)
	spec, err := loader.LoadStackSpec(specFile)
	if err != nil {
		return fmt.Errorf("failed to load spec: %w", err)
	}

	// Load deployment state
	stateFile := filepath.Join(wd, ".stackkit", "state.yaml")
	state, err := loader.LoadDeploymentState(stateFile)
	if err != nil || state == nil {
		printWarning("No deployment state found. Run 'stackkit apply' first.")
		return nil
	}

	// Print header
	fmt.Println()
	fmt.Printf("  %s: %s\n", bold("StackKit"), spec.StackKit)
	fmt.Printf("  %s: %s\n", bold("Variant"), spec.Variant)
	fmt.Printf("  %s: %s\n", bold("Mode"), spec.Mode)
	fmt.Printf("  %s: %s\n", bold("Last Applied"), state.LastApplied.Format("2006-01-02 15:04:05"))
	fmt.Println()

	// Get Docker containers
	dockerClient := docker.NewClient()
	if !dockerClient.IsInstalled() || !dockerClient.IsRunning(ctx) {
		printWarning("Docker is not running")
		return nil
	}

	containers, err := dockerClient.GetStackKitContainers(ctx)
	if err != nil {
		printWarning("Could not get container status: %v", err)
		return nil
	}

	if len(containers) == 0 {
		printInfo("No containers found")
		return nil
	}

	// Build service states
	var services []models.ServiceState
	for _, c := range containers {
		health, _ := dockerClient.GetContainerHealth(ctx, c.ID)
		services = append(services, models.ServiceState{
			Name:      c.Name,
			Container: c.ID[:12],
			Status:    docker.GetServiceStatus(&c),
			Health:    health,
		})
	}

	// Display table
	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"Service", "Status", "Health", "Container"})
	table.SetBorder(false)
	table.SetHeaderColor(
		tablewriter.Colors{tablewriter.Bold},
		tablewriter.Colors{tablewriter.Bold},
		tablewriter.Colors{tablewriter.Bold},
		tablewriter.Colors{tablewriter.Bold},
	)

	for _, s := range services {
		statusStr := formatStatus(s.Status)
		healthStr := formatHealth(s.Health)
		table.Append([]string{s.Name, statusStr, healthStr, s.Container})
	}

	table.Render()

	// Overall status
	fmt.Println()
	overallStatus := determineOverallStatus(services)
	switch overallStatus {
	case models.StatusRunning:
		printSuccess("Deployment is healthy")
	case models.StatusDegraded:
		printWarning("Deployment is degraded")
	case models.StatusError:
		printError("Deployment has errors")
	}

	return nil
}

func formatStatus(status models.ServiceStatus) string {
	switch status {
	case models.ServiceStatusRunning:
		return green("running")
	case models.ServiceStatusStopped:
		return red("stopped")
	case models.ServiceStatusStarting:
		return yellow("starting")
	case models.ServiceStatusError:
		return red("error")
	default:
		return "unknown"
	}
}

func formatHealth(health models.HealthStatus) string {
	switch health {
	case models.HealthStatusHealthy:
		return green("healthy")
	case models.HealthStatusUnhealthy:
		return red("unhealthy")
	case models.HealthStatusStarting:
		return yellow("starting")
	case models.HealthStatusNone:
		return "-"
	default:
		return "-"
	}
}

func determineOverallStatus(services []models.ServiceState) models.DeploymentStatus {
	hasError := false
	hasDegraded := false

	for _, s := range services {
		if s.Status == models.ServiceStatusError {
			hasError = true
		}
		if s.Status == models.ServiceStatusStopped {
			hasDegraded = true
		}
		if s.Health == models.HealthStatusUnhealthy {
			hasDegraded = true
		}
	}

	if hasError {
		return models.StatusError
	}
	if hasDegraded {
		return models.StatusDegraded
	}
	return models.StatusRunning
}

// Package docker provides Docker operations for StackKits.
package docker

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
	"time"

	"github.com/kombihq/stackkits/pkg/models"
)

// containerNameRegex validates Docker container/network/volume names
var containerNameRegex = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9_.-]*$`)

// validateName validates a Docker resource name (container, network, volume)
func validateName(name string) error {
	if name == "" {
		return fmt.Errorf("name cannot be empty")
	}
	if len(name) > 255 {
		return fmt.Errorf("name too long (max 255 characters)")
	}
	if !containerNameRegex.MatchString(name) {
		return fmt.Errorf("invalid name: must match [a-zA-Z0-9][a-zA-Z0-9_.-]*")
	}
	return nil
}

// validateNameOrID validates a container name or ID (allows hex IDs)
func validateNameOrID(nameOrID string) error {
	if nameOrID == "" {
		return fmt.Errorf("name or ID cannot be empty")
	}
	// Allow hex container IDs (64 char) or short IDs (12 char)
	if regexp.MustCompile(`^[a-f0-9]{12,64}$`).MatchString(nameOrID) {
		return nil
	}
	return validateName(nameOrID)
}

// Client handles Docker operations
type Client struct {
	binary  string
	timeout time.Duration
}

// ClientOption configures the Docker client
type ClientOption func(*Client)

// WithBinary sets the Docker binary path
func WithBinary(binary string) ClientOption {
	return func(c *Client) {
		c.binary = binary
	}
}

// WithTimeout sets the operation timeout
func WithTimeout(timeout time.Duration) ClientOption {
	return func(c *Client) {
		c.timeout = timeout
	}
}

// NewClient creates a new Docker client
func NewClient(opts ...ClientOption) *Client {
	c := &Client{
		binary:  "docker",
		timeout: 30 * time.Second,
	}
	for _, opt := range opts {
		opt(c)
	}
	return c
}

// ContainerInfo represents container information
type ContainerInfo struct {
	ID      string            `json:"Id"`
	Name    string            `json:"Name"`
	Image   string            `json:"Image"`
	State   ContainerState    `json:"State"`
	Ports   []ContainerPort   `json:"Ports"`
	Labels  map[string]string `json:"Labels"`
	Created string            `json:"Created"`
}

// ContainerState represents container state
type ContainerState struct {
	Status     string       `json:"Status"`
	Running    bool         `json:"Running"`
	Paused     bool         `json:"Paused"`
	Restarting bool         `json:"Restarting"`
	Health     *HealthState `json:"Health,omitempty"`
}

// HealthState represents container health
type HealthState struct {
	Status string `json:"Status"`
}

// ContainerPort represents a container port
type ContainerPort struct {
	PrivatePort int    `json:"PrivatePort"`
	PublicPort  int    `json:"PublicPort"`
	Type        string `json:"Type"`
}

// IsInstalled checks if Docker is installed
func (c *Client) IsInstalled() bool {
	_, err := exec.LookPath(c.binary)
	return err == nil
}

// Version returns the Docker version
func (c *Client) Version(ctx context.Context) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binary, "version", "--format", "{{.Server.Version}}")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get Docker version: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

// IsRunning checks if Docker daemon is running
func (c *Client) IsRunning(ctx context.Context) bool {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binary, "info")
	return cmd.Run() == nil
}

// ListContainers lists all containers
func (c *Client) ListContainers(ctx context.Context, all bool) ([]ContainerInfo, error) {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	args := []string{"ps", "--format", "{{json .}}"}
	if all {
		args = []string{"ps", "-a", "--format", "{{json .}}"}
	}

	cmd := exec.CommandContext(ctx, c.binary, args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list containers: %w", err)
	}

	var containers []ContainerInfo
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}
		var info struct {
			ID     string `json:"ID"`
			Names  string `json:"Names"`
			Image  string `json:"Image"`
			State  string `json:"State"`
			Status string `json:"Status"`
			Ports  string `json:"Ports"`
		}
		if err := json.Unmarshal([]byte(line), &info); err != nil {
			continue
		}
		containers = append(containers, ContainerInfo{
			ID:    info.ID,
			Name:  info.Names,
			Image: info.Image,
			State: ContainerState{
				Status:  info.Status,
				Running: info.State == "running",
			},
		})
	}

	return containers, nil
}

// InspectContainer inspects a container
func (c *Client) InspectContainer(ctx context.Context, nameOrID string) (*ContainerInfo, error) {
	// Validate input to prevent command injection
	if err := validateNameOrID(nameOrID); err != nil {
		return nil, fmt.Errorf("invalid container name/ID: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binary, "inspect", nameOrID)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to inspect container: %w", err)
	}

	var containers []ContainerInfo
	if err := json.Unmarshal(output, &containers); err != nil {
		return nil, fmt.Errorf("failed to parse container info: %w", err)
	}

	if len(containers) == 0 {
		return nil, fmt.Errorf("container not found: %s", nameOrID)
	}

	return &containers[0], nil
}

// GetContainerHealth gets the health status of a container
func (c *Client) GetContainerHealth(ctx context.Context, nameOrID string) (models.HealthStatus, error) {
	// Validation happens in InspectContainer
	info, err := c.InspectContainer(ctx, nameOrID)
	if err != nil {
		return models.HealthStatusUnknown, err
	}

	if !info.State.Running {
		return models.HealthStatusUnhealthy, nil
	}

	if info.State.Health == nil {
		return models.HealthStatusNone, nil
	}

	switch info.State.Health.Status {
	case "healthy":
		return models.HealthStatusHealthy, nil
	case "unhealthy":
		return models.HealthStatusUnhealthy, nil
	case "starting":
		return models.HealthStatusStarting, nil
	default:
		return models.HealthStatusNone, nil
	}
}

// GetStackKitContainers returns containers managed by StackKit
func (c *Client) GetStackKitContainers(ctx context.Context) ([]ContainerInfo, error) {
	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	// Filter by StackKit label
	cmd := exec.CommandContext(ctx, c.binary, "ps", "-a",
		"--filter", "label=managed-by=stackkit",
		"--format", "{{json .}}")

	output, err := cmd.Output()
	if err != nil {
		// Try without filter (might not have labeled containers yet)
		return c.ListContainers(ctx, true)
	}

	var containers []ContainerInfo
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}
		var info struct {
			ID     string `json:"ID"`
			Names  string `json:"Names"`
			Image  string `json:"Image"`
			State  string `json:"State"`
			Status string `json:"Status"`
		}
		if err := json.Unmarshal([]byte(line), &info); err != nil {
			continue
		}
		containers = append(containers, ContainerInfo{
			ID:    info.ID,
			Name:  info.Names,
			Image: info.Image,
			State: ContainerState{
				Status:  info.Status,
				Running: info.State == "running",
			},
		})
	}

	return containers, nil
}

// NetworkExists checks if a network exists
func (c *Client) NetworkExists(ctx context.Context, name string) bool {
	// Validate network name
	if err := validateName(name); err != nil {
		return false
	}

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binary, "network", "inspect", name)
	return cmd.Run() == nil
}

// VolumeExists checks if a volume exists
func (c *Client) VolumeExists(ctx context.Context, name string) bool {
	// Validate volume name
	if err := validateName(name); err != nil {
		return false
	}

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binary, "volume", "inspect", name)
	return cmd.Run() == nil
}

// Exec runs a command in a container
func (c *Client) Exec(ctx context.Context, container string, command []string) (string, error) {
	// Validate container name/ID
	if err := validateNameOrID(container); err != nil {
		return "", fmt.Errorf("invalid container name/ID: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	args := append([]string{"exec", container}, command...)
	cmd := exec.CommandContext(ctx, c.binary, args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("exec failed: %w: %s", err, stderr.String())
	}

	return stdout.String(), nil
}

// Logs returns container logs
func (c *Client) Logs(ctx context.Context, container string, tail int) (string, error) {
	// Validate container name/ID
	if err := validateNameOrID(container); err != nil {
		return "", fmt.Errorf("invalid container name/ID: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, c.timeout)
	defer cancel()

	args := []string{"logs", container}
	if tail > 0 {
		args = append(args, "--tail", fmt.Sprintf("%d", tail))
	}

	cmd := exec.CommandContext(ctx, c.binary, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to get logs: %w", err)
	}

	return string(output), nil
}

// validateImageName validates a Docker image name
// Supports formats: name, name:tag, registry/name, registry/name:tag, name@sha256:digest
var imageNameRegex = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9_./@:-]*$`)

func validateImageName(image string) error {
	if image == "" {
		return fmt.Errorf("image name cannot be empty")
	}
	if len(image) > 512 {
		return fmt.Errorf("image name too long (max 512 characters)")
	}
	if !imageNameRegex.MatchString(image) {
		return fmt.Errorf("invalid image name format")
	}
	return nil
}

// Pull pulls a Docker image
func (c *Client) Pull(ctx context.Context, image string) error {
	// Validate image name
	if err := validateImageName(image); err != nil {
		return fmt.Errorf("invalid image name: %w", err)
	}

	ctx, cancel := context.WithTimeout(ctx, 5*time.Minute)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binary, "pull", image)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to pull image %s: %w", image, err)
	}

	return nil
}

// GetServiceStatus converts container info to service status
func GetServiceStatus(container *ContainerInfo) models.ServiceStatus {
	if container == nil {
		return models.ServiceStatusUnknown
	}

	if container.State.Running {
		return models.ServiceStatusRunning
	}
	if container.State.Restarting {
		return models.ServiceStatusStarting
	}

	return models.ServiceStatusStopped
}

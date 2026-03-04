// Package models defines the core data structures for StackKits.
package models

import "time"

// StackKitMetadata represents the metadata section of a stackkit.yaml
type StackKitMetadata struct {
	APIVersion  string   `yaml:"apiVersion" json:"apiVersion"`
	Kind        string   `yaml:"kind" json:"kind"`
	Name        string   `yaml:"name" json:"name"`
	Version     string   `yaml:"version" json:"version"`
	DisplayName string   `yaml:"displayName" json:"displayName"`
	Description string   `yaml:"description" json:"description"`
	Author      string   `yaml:"author,omitempty" json:"author,omitempty"`
	License     string   `yaml:"license" json:"license"`
	Homepage    string   `yaml:"homepage,omitempty" json:"homepage,omitempty"`
	Repository  string   `yaml:"repository,omitempty" json:"repository,omitempty"`
	Tags        []string `yaml:"tags,omitempty" json:"tags,omitempty"`
}

// StackKit represents a complete stackkit.yaml file
type StackKit struct {
	Metadata       StackKitMetadata   `yaml:"metadata" json:"metadata"`
	SupportedOS    []string           `yaml:"supportedOS" json:"supportedOS"`
	Requirements   Requirements       `yaml:"requirements" json:"requirements"`
	Modes          Modes              `yaml:"modes" json:"modes"`
	Variants       map[string]Variant `yaml:"variants" json:"variants"`
	DefaultVariant string             `yaml:"defaultVariant,omitempty" json:"defaultVariant,omitempty"`
	Features       Features           `yaml:"features,omitempty" json:"features,omitempty"`
}

// Requirements defines system requirements
type Requirements struct {
	Minimum     ResourceSpec `yaml:"minimum" json:"minimum"`
	Recommended ResourceSpec `yaml:"recommended" json:"recommended"`
}

// ResourceSpec defines resource specifications
type ResourceSpec struct {
	CPU  int `yaml:"cpu" json:"cpu"`
	RAM  int `yaml:"ram" json:"ram"`   // in GB
	Disk int `yaml:"disk" json:"disk"` // in GB
}

// Modes defines deployment modes
type Modes struct {
	Simple   ModeSpec `yaml:"simple" json:"simple"`
	Advanced ModeSpec `yaml:"advanced,omitempty" json:"advanced,omitempty"`
}

// ModeSpec defines a single deployment mode
type ModeSpec struct {
	Name        string `yaml:"name" json:"name"`
	Description string `yaml:"description" json:"description"`
	Engine      string `yaml:"engine" json:"engine"` // "opentofu" or "terramate"
	Default     bool   `yaml:"default,omitempty" json:"default,omitempty"`
}

// Variant defines a service variant
type Variant struct {
	DisplayName       string   `yaml:"name" json:"displayName"`
	Description       string   `yaml:"description" json:"description"`
	ServiceCollection string   `yaml:"serviceCollection,omitempty" json:"serviceCollection,omitempty"`
	Services          []string `yaml:"services" json:"services"`
	Default           bool     `yaml:"default,omitempty" json:"default,omitempty"`
}

// Features defines optional features
type Features struct {
	MultiNode    bool `yaml:"multiNode,omitempty" json:"multiNode,omitempty"`
	VPNOverlay   bool `yaml:"vpnOverlay,omitempty" json:"vpnOverlay,omitempty"`
	PublicAccess bool `yaml:"publicAccess,omitempty" json:"publicAccess,omitempty"`
}

// StackSpec represents the user's deployment specification (stack-spec.yaml)
type StackSpec struct {
	Name        string            `yaml:"name" json:"name"`
	StackKit    string            `yaml:"stackkit" json:"stackkit"`
	Variant     string            `yaml:"variant,omitempty" json:"variant,omitempty"`
	Mode        string            `yaml:"mode,omitempty" json:"mode,omitempty"`
	Context     string            `yaml:"context,omitempty" json:"context,omitempty"`
	Domain      string            `yaml:"domain,omitempty" json:"domain,omitempty"`
	Email       string            `yaml:"email,omitempty" json:"email,omitempty"`
	AdminEmail  string            `yaml:"adminEmail,omitempty" json:"adminEmail,omitempty"`
	Network     NetworkSpec       `yaml:"network,omitempty" json:"network,omitempty"`
	Compute     ComputeSpec       `yaml:"compute,omitempty" json:"compute,omitempty"`
	SSH         SSHSpec           `yaml:"ssh,omitempty" json:"ssh,omitempty"`
	Nodes       []NodeSpec        `yaml:"nodes,omitempty" json:"nodes,omitempty"`
	Addons      []string          `yaml:"addons,omitempty" json:"addons,omitempty"`
	Services    map[string]any    `yaml:"services,omitempty" json:"services,omitempty"`
	Environment map[string]string `yaml:"environment,omitempty" json:"environment,omitempty"`
}

// NetworkSpec defines network configuration
type NetworkSpec struct {
	Mode    string `yaml:"mode" json:"mode"` // "local", "public", "hybrid"
	Subnet  string `yaml:"subnet,omitempty" json:"subnet,omitempty"`
	Gateway string `yaml:"gateway,omitempty" json:"gateway,omitempty"`
}

// ComputeSpec defines compute tier configuration
type ComputeSpec struct {
	Tier string `yaml:"tier" json:"tier"` // "low", "standard", "high"
}

// SSHSpec defines SSH configuration
type SSHSpec struct {
	KeyPath string `yaml:"keyPath,omitempty" json:"keyPath,omitempty"`
	User    string `yaml:"user,omitempty" json:"user,omitempty"`
	Port    int    `yaml:"port,omitempty" json:"port,omitempty"`
}

// NodeSpec defines a deployment node
type NodeSpec struct {
	Name     string   `yaml:"name" json:"name"`
	Role     string   `yaml:"role" json:"role"` // "control-plane", "worker", "standalone"
	IP       string   `yaml:"ip" json:"ip"`
	Services []string `yaml:"services,omitempty" json:"services,omitempty"`
}

// DeploymentState represents the current deployment state
type DeploymentState struct {
	StackKit    string           `yaml:"stackkit" json:"stackkit"`
	Variant     string           `yaml:"variant" json:"variant"`
	Mode        string           `yaml:"mode" json:"mode"`
	Status      DeploymentStatus `yaml:"status" json:"status"`
	LastApplied time.Time        `yaml:"lastApplied" json:"lastApplied"`
	TofuState   string           `yaml:"tofuState,omitempty" json:"tofuState,omitempty"`
	Services    []ServiceState   `yaml:"services" json:"services"`
}

// DeploymentStatus represents deployment status
type DeploymentStatus string

const (
	StatusPending   DeploymentStatus = "pending"
	StatusPlanning  DeploymentStatus = "planning"
	StatusApplying  DeploymentStatus = "applying"
	StatusRunning   DeploymentStatus = "running"
	StatusDegraded  DeploymentStatus = "degraded"
	StatusError     DeploymentStatus = "error"
	StatusDestroyed DeploymentStatus = "destroyed"
)

// ServiceState represents the state of a service
type ServiceState struct {
	Name      string        `yaml:"name" json:"name"`
	Status    ServiceStatus `yaml:"status" json:"status"`
	Container string        `yaml:"container,omitempty" json:"container,omitempty"`
	URL       string        `yaml:"url,omitempty" json:"url,omitempty"`
	Health    HealthStatus  `yaml:"health" json:"health"`
}

// ServiceStatus represents service status
type ServiceStatus string

const (
	ServiceStatusRunning  ServiceStatus = "running"
	ServiceStatusStopped  ServiceStatus = "stopped"
	ServiceStatusStarting ServiceStatus = "starting"
	ServiceStatusError    ServiceStatus = "error"
	ServiceStatusUnknown  ServiceStatus = "unknown"
)

// HealthStatus represents health check status
type HealthStatus string

const (
	HealthStatusHealthy   HealthStatus = "healthy"
	HealthStatusUnhealthy HealthStatus = "unhealthy"
	HealthStatusStarting  HealthStatus = "starting"
	HealthStatusNone      HealthStatus = "none"
	HealthStatusUnknown   HealthStatus = "unknown"
)

// ValidationResult represents the result of a validation
type ValidationResult struct {
	Valid    bool              `json:"valid"`
	Errors   []ValidationError `json:"errors,omitempty"`
	Warnings []ValidationError `json:"warnings,omitempty"`
}

// ValidationError represents a validation error or warning
type ValidationError struct {
	Path    string `json:"path"`
	Message string `json:"message"`
	Code    string `json:"code,omitempty"`
}

// DockerCapabilities represents detected Docker runtime capabilities.
// Written by `stackkit prepare` and read by `stackkit generate`.
type DockerCapabilities struct {
	BridgeNetworking bool   `json:"bridgeNetworking"`
	Iptables         bool   `json:"iptables"`
	StorageDriver    string `json:"storageDriver"`
}

// SystemInfo represents system information from a node
type SystemInfo struct {
	Hostname      string `json:"hostname"`
	OS            string `json:"os"`
	OSVersion     string `json:"osVersion"`
	Arch          string `json:"arch"`
	CPUCores      int    `json:"cpuCores"`
	MemoryMB      int    `json:"memoryMB"`
	DiskGB        int    `json:"diskGB"`
	DockerVersion string `json:"dockerVersion,omitempty"`
	TofuVersion   string `json:"tofuVersion,omitempty"`
}

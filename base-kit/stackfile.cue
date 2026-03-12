// =============================================================================
// STACKKIT: base-kit - Single Server Deployment
// =============================================================================
//
// Version 4.0 - Architecture v4 (StackKit + Context + Add-Ons)
//
// Architecture Pattern: Single-Environment
//   All services run in one deployment target (local server or cloud VPS).
//
// Deployment Modes:
//   - simple:   OpenTofu Day-1 only (initial provisioning)
//   - advanced: OpenTofu + Terramate Day-1 + Day-2 (drift, updates, lifecycle)
//
// PaaS Selection (Context-driven, M2):
//   - local context → Dokploy (simpler, port-based)
//   - cloud context → Coolify (more features, git deploys)
//
// Use Cases:
//   - Personal home server or cloud VPS
//   - Development environment
//   - Small self-hosted services
//   - PaaS-style application deployments
//
// Note: Variants are being migrated to Add-Ons (M4).
//       Context system replaces manual compute tier selection (M2).
// =============================================================================

package base_kit

import (
	"list"
)

// =============================================================================
// MAIN SCHEMA: #BaseKitStack
// =============================================================================
// This is the primary user-facing schema that tests and users interact with.
// It provides a simplified interface while using the base schemas internally.

#BaseKitStack: {
	// Metadata
	meta: #StackMeta

	// Deployment Mode: simple or advanced
	deploymentMode: *"simple" | "advanced"

	// Variant selection (coolify requires domain)
	variant: *"default" | "coolify" | "beszel" | "minimal"

	// Compute tier (auto or explicit)
	computeTier: *"standard" | "high" | "low"

	// Drift detection (triggers advanced mode)
	driftDetection?: {
		enabled:  bool | *false
		schedule: string | *"0 */6 * * *"
	}

	// Node configuration (exactly 1 node)
	nodes: [...#HomelabNode] & list.MinItems(1) & list.MaxItems(1)

	// Network configuration
	network: #NetworkConfig

	// Services (auto-populated based on variant)
	services: #ServiceSet

	// Deployment config (auto-generated based on mode)
	_deployment: #DeploymentConfig & {
		if deploymentMode == "simple" {
			mode: "simple"
			day1: {
				engine: "opentofu"
				actions: ["init", "plan", "apply"]
			}
			day2: enabled: false
		}
		if deploymentMode == "advanced" {
			mode: "advanced"
			day1: {
				engine: "opentofu"
				actions: ["init", "plan", "apply"]
			}
			day2: {
				enabled: true
				engine:  "terramate"
				actions: ["drift", "update", "destroy"]
				features: {
					drift_detection:  true
					change_sets:      true
					rolling_updates:  true
					stack_ordering:   true
				}
			}
		}
	}
}

// =============================================================================
// METADATA
// =============================================================================

#StackMeta: {
	name:    string & =~"^[a-z][a-z0-9-]*$"
	version: string | *"4.0.0"
}

// =============================================================================
// DEPLOYMENT MODE CONFIGURATION
// =============================================================================

#DeploymentConfig: {
	mode: "simple" | "advanced"

	day1: {
		engine: "opentofu"
		actions: [...string]
	}

	day2: {
		enabled: bool
		engine?: string
		actions?: [...string]
		features?: {
			drift_detection:  bool
			change_sets:      bool
			rolling_updates:  bool
			stack_ordering:   bool
		}
	}
}

// =============================================================================
// NODE DEFINITION
// =============================================================================

#HomelabNode: {
	id:   string & =~"^[a-z][a-z0-9-]*$"
	name: string & =~"^[a-z][a-z0-9-]*$"
	host: string // IP address or hostname

	compute: #ComputeResources

	os?: #OSConfig

	role: *"worker" | "main"
}

#ComputeResources: {
	cpuCores:  int & >=1
	ramGB:     int & >=2
	storageGB: int & >=20
}

#OSConfig: {
	family:  *"debian" | "rhel"
	distro:  *"ubuntu" | "debian" | "rocky" | "alma"
	version: string | *"24.04"
}

// =============================================================================
// NETWORK CONFIGURATION
// =============================================================================

#NetworkConfig: {
	domain:    string
	acmeEmail: string

	subnet: string | *"172.20.0.0/16"

	dns?: {
		servers: [...string] | *["1.1.1.1", "8.8.8.8"]
	}
}

// =============================================================================
// SERVICE SET (Variant-based)
// =============================================================================

#ServiceSet: {
	// Core services (always present)
	traefik: #ServiceToggle & {enabled: true}
	dozzle:  #ServiceToggle
	whoami:  #ServiceToggle

	// Default variant services
	dokploy?:    #ServiceToggle
	uptimeKuma?: #ServiceToggle

	// Beszel variant services
	beszel?: #ServiceToggle

	// Minimal variant services
	dockge?:    #ServiceToggle
	portainer?: #ServiceToggle
	netdata?:   #ServiceToggle
}

#ServiceToggle: {
	enabled: bool | *false
}

// =============================================================================
// NOTE: #BaseKitKit was removed in v4.0.0 (TD-07)
// All tests and users use #BaseKitStack as the canonical schema.
// Rich layer configs (identity, platform, security, observability) are
// handled by the CLI at generation time, not in the user-facing schema.
// =============================================================================

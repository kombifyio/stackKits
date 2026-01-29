// Package base - 3-Layer Architecture Validation Schemas
package base

// =============================================================================
// LAYER 1: FOUNDATION - REQUIRED
// =============================================================================

// #Layer1Foundation validates Layer 1 requirements
#Layer1Foundation: {
	// System configuration MUST be present
	system: #SystemConfig

	// Base packages MUST be defined
	packages: #BasePackages

	// Security settings MUST be configured
	security: {
		// SSH hardening is REQUIRED
		ssh: #SSHHardening

		// Firewall policy is REQUIRED
		firewall: #FirewallPolicy
	}

	// Validation check
	_valid: true
}

// =============================================================================
// LAYER 2: PLATFORM - REQUIRED
// =============================================================================

// Platform types supported
#PlatformType: "docker" | "docker-swarm" | "kubernetes"

// #Layer2Platform validates Layer 2 requirements
#Layer2Platform: {
	// Platform type MUST be explicitly declared
	platform: #PlatformType

	// Container runtime configuration MUST be present
	container: #ContainerRuntime

	// Networking base MUST be configured
	network: {
		defaults: #NetworkDefaults
	}

	// Validation check
	_valid: true
}

// =============================================================================
// LAYER 3: APPLICATIONS - REQUIRED
// =============================================================================

// PAAS service types
#PAASServiceType: "dokploy" | "coolify" | "dokku" | "portainer" | "dockge"

// Service role classification
#ServiceRole: "paas" | "monitoring" | "management" | "proxy" | "utility" | "test"

// #Layer3Applications validates Layer 3 requirements
#Layer3Applications: {
	// Services map
	services: [string]: #ServiceDefinition

	// At least ONE PAAS/management service MUST be enabled
	_paasServices: [
		for name, svc in services
		if (svc.type == "paas" || svc.type == "management") && svc.enabled != false {
			name
		},
	]

	// Validation: Must have at least one PAAS service
	_hasPAASService: len(_paasServices) > 0
}

// =============================================================================
// COMPLETE STACKKIT VALIDATION
// =============================================================================

// #ValidatedStackKit combines all 3 layers
#ValidatedStackKit: {
	// Layer 1: Foundation (embedded)
	#Layer1Foundation

	// Layer 2: Platform (embedded)
	#Layer2Platform

	// Layer 3: Applications (embedded)
	#Layer3Applications

	// Metadata requirements
	metadata: #StackKitMetadata

	// Final validation - all layers must be valid
	_valid: {
		layer1: true
		layer2: true
		layer3: true
	}
}

// =============================================================================
// VALIDATION ERROR TYPES
// =============================================================================

// #LayerValidationError represents a layer validation failure
#LayerValidationError: {
	layer:   "1" | "2" | "3"
	code:    string
	message: string
	field?:  string
	hint?:   string
}

// #LayerValidationResult contains validation results
#LayerValidationResult: {
	valid:  bool
	layer:  "1" | "2" | "3" | "all"
	errors: [...#LayerValidationError]
}

// =============================================================================
// LAYER METADATA
// =============================================================================

// #LayerMetadata provides information about layer configuration
#LayerMetadata: {
	// Layer name
	name: string

	// Layer version
	version: string

	// Layer description
	description: string

	// Required components
	required: [...string]

	// Optional components
	optional: [...string]
}

// Default layer metadata
#DefaultLayerMetadata: {
	layer1: #LayerMetadata & {
		name:        "foundation"
		version:     "1.0.0"
		description: "System configuration, packages, and security"
		required: ["system", "packages", "security.ssh", "security.firewall"]
		optional: ["security.container", "security.secrets", "security.tls", "security.audit"]
	}

	layer2: #LayerMetadata & {
		name:        "platform"
		version:     "1.0.0"
		description: "Container runtime and networking platform"
		required: ["platform", "container", "network.defaults"]
		optional: ["network.dns", "network.ntp", "network.vpn", "network.proxy"]
	}

	layer3: #LayerMetadata & {
		name:        "applications"
		version:     "1.0.0"
		description: "Services and applications"
		required: ["services"]
		optional: []
	}
}

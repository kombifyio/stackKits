// Package modern_homelab - CUE Schema Definition
// 
// Modern Homelab = Multi-server Docker setup with hybrid (cloud + local) topology
// Platform: Docker + Coolify
// Network: Public + VPN Overlay (Headscale)
//
// This is the main StackKit schema that extends base.

package modern_homelab

import "github.com/kombihq/stackkits/base"

// =============================================================================
// STACKKIT DEFINITION
// =============================================================================

// #StackKitDefinition - Main schema for Modern Homelab
#StackKitDefinition: base.#StackKitBase & {
	version: "v0.1.0"
	kind:    "StackKit"
	name:    "modern-homelab"
	
	metadata: {
		displayName: "Modern Homelab"
		description: "Multi-server hybrid homelab with Docker + Coolify"
		category:    "homelab"
		tier:        "advanced"
		platform:    "docker"  // NOT kubernetes!
		author:      "KombiStack"
		license:     "Apache-2.0"
	}

	// Modern Homelab requires: multi-node, public access, VPN overlay
	requirements: {
		minNodes: 2  // At least cloud + local node
		platform: "docker"
		publicAccess: true
		vpnOverlay: true
	}
}

// =============================================================================
// MULTI-NODE TOPOLOGY
// =============================================================================

// #NodeType defines the role of a node in the cluster
#NodeType: "cloud" | "local"

// #NodeDefinition - Base for all nodes
#NodeDefinition: {
	name:     string
	type:     #NodeType
	hostname: string | *name
	
	// Provider info (for IaC)
	provider: {
		type: "hetzner" | "digitalocean" | "vultr" | "linode" | "proxmox" | "bare-metal" | "local"
		
		// Cloud provider specifics (optional)
		if type != "bare-metal" && type != "local" {
			region?: string
			size?:   string
			image?:  string
		}
	}
	
	// Network config
	network: {
		// Public IP (only for cloud nodes)
		if type == "cloud" {
			publicIp: string
		}
		
		// Private/Tailscale IP (all nodes)
		tailscaleIp?: string
		
		// Local network (for local nodes)
		if type == "local" {
			localIp: string
			subnet:  string | *"192.168.1.0/24"
		}
	}
	
	// Docker configuration
	docker: {
		installed: bool | *true
		version:   string | *"24.0"
		dataRoot:  string | *"/var/lib/docker"
	}
	
	// SSH access (used by Coolify)
	ssh: {
		user: string | *"root"
		port: int | *22
		// Key is managed by Coolify
	}
	
	// Node-specific labels for service placement
	labels: [string]: string
}

// #CloudNode - Entry point node with public IP
#CloudNode: #NodeDefinition & {
	type: "cloud"
	
	labels: {
		"kombistack.io/role": "entry-point"
		"kombistack.io/public": "true"
	}
}

// #LocalNode - On-premises node behind NAT
#LocalNode: #NodeDefinition & {
	type: "local"
	
	labels: {
		"kombistack.io/role": "worker"
		"kombistack.io/public": "false"
	}
}

// =============================================================================
// CLUSTER CONFIGURATION
// =============================================================================

// #ClusterConfig - Multi-node cluster definition
#ClusterConfig: {
	name:   string
	domain: string  // Public domain for services
	
	// Node definitions
	nodes: {
		// At least one cloud node required
		cloud: [#CloudNode, ...#CloudNode]
		
		// Local nodes are optional
		local?: [...#LocalNode]
	}
	
	// VPN overlay configuration
	vpn: #VpnConfig
	
	// TLS configuration
	tls: {
		provider:  "letsencrypt" | "letsencrypt-staging" | "custom"
		email:     string
		wildcardEnabled: bool | *false
	}
	
	// DNS provider (for automatic DNS)
	dns?: {
		provider: "cloudflare" | "route53" | "hetzner" | "manual"
		if provider != "manual" {
			apiToken: string
		}
	}
}

// #VpnConfig - Headscale VPN configuration
#VpnConfig: {
	enabled:     bool | *true
	provider:    "headscale"
	
	// Headscale settings
	serverUrl:   string  // https://hs.domain.com
	baseDomain:  string  // domain.com
	
	// DERP (relay) settings
	derpEnabled: bool | *true
	derpRegions: [...string] | *["default"]
	
	// MagicDNS for internal resolution
	magicDns:    bool | *true
	
	// Pre-auth keys (one per node type)
	preAuthKeys: {
		cloud: string
		local: string
	}
	
	// Advertised routes from local nodes
	advertisedRoutes: [...string]
}

// =============================================================================
// STACK CONFIGURATION (kombination.yaml)
// =============================================================================

// #ModernHomelabStack - Complete stack configuration
#ModernHomelabStack: {
	apiVersion: "kombistack.io/v1alpha1"
	kind:       "Stack"
	
	metadata: {
		name:      string
		namespace: string | *"default"
	}
	
	spec: {
		stackKit: "modern-homelab"
		variant:  "default" | "minimal" | "beszel" | *"default"
		
		// Cluster definition
		cluster: #ClusterConfig
		
		// Service overrides
		services?: {
			[Name=string]: {
				enabled?: bool
				config?:  _
			}
		}
		
		// User applications (deployed via Coolify)
		applications?: [...#ApplicationDefinition]
	}
}

// #ApplicationDefinition - User application (deployed via Coolify)
#ApplicationDefinition: {
	name:   string
	type:   "dockerfile" | "docker-compose" | "nixpacks" | "static"
	source: {
		type: "git" | "local"
		if type == "git" {
			url:    string
			branch: string | *"main"
		}
	}
	
	// Deployment target
	placement: {
		node:   string  // Node name
		domain: string  // Subdomain
	}
	
	// Environment
	env?: [string]: string
}

// =============================================================================
// VALIDATION RULES
// =============================================================================

// Validation constraints are enforced via schema structure
// - Cloud nodes: enforced by [...#CloudNode] requiring at least one element
// - Domain: required field in #ClusterConfig
// - VPN: optional, validated when local nodes are present

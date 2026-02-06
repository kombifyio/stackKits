// =============================================================================
// STACKKIT: BASE-HOMELAB - Single Server Deployment
// =============================================================================
//
// Version 3.1 - With PaaS selection strategy
//
// Deployment Modes:
//   - simple:   OpenTofu Day-1 only (initial provisioning)
//   - advanced: OpenTofu + Terramate Day-1 + Day-2 (drift, updates, lifecycle)
//
// Variants:
//   - default: Dokploy + Uptime Kuma (for users WITHOUT own domain)
//   - coolify: Coolify + Uptime Kuma (for users WITH own domain)
//   - beszel:  Dokploy + Beszel (server metrics focus)
//   - minimal: Dockge + Portainer + Netdata (lightweight)
//
// PaaS Selection Logic:
//   - No domain / local network → Dokploy (simpler, port-based)
//   - Own domain configured    → Coolify (more features, git deploys)
//
// Use Cases:
//   - Personal home server
//   - Development environment
//   - Small self-hosted services
//   - PaaS-style application deployments
//
// Limitations:
//   - Single node only (no HA)
//   - No cloud providers
//   - No VPN overlay (local network only)
// =============================================================================

package base_homelab

import (
	"list"
	"github.com/kombihq/stackkits/base"
)

// =============================================================================
// MAIN SCHEMA: #BaseHomelabStack
// =============================================================================
// This is the primary user-facing schema that tests and users interact with.
// It provides a simplified interface while using the base schemas internally.

#BaseHomelabStack: {
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
	version: string | *"3.0.0"
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
// LEGACY ALIAS: #BaseHomelabKit (deprecated, use #BaseHomelabStack)
// =============================================================================

#BaseHomelabKit: base.#BaseStackKit & {
	// StackKit metadata
	metadata: {
		name:        "base-homelab"
		displayName: "Base Homelab"
		version:     "2.0.0"
		description: "Single-server homelab with Docker, Dokploy and monitoring"
		author:      "KombiStack Team"
		license:     "MIT"
		tags: ["homelab", "single-node", "docker", "dokploy", "professional"]

		minKombiStackVersion: "1.0.0"
	}

	// Variant selection
	variant: "default" | "coolify" | "beszel" | "minimal" | "secure" | *"default"

	// ==========================================================================
	// LAYER 1: FOUNDATION IDENTITY (Zero-Trust - REQUIRED)
	// ==========================================================================

	// Layer 1 Identity services - REQUIRED for all StackKits
	identity: {
		// LLDAP - Lightweight LDAP directory service
		lldap: base.#LLDAPConfig & {
			enabled: true // Zero-Trust: MUST be enabled
			domain: {
				base:         string | *"dc=homelab,dc=local"
				organization: "Homelab"
			}
			admin: {
				email: string | *"admin@homelab.local"
			}
		}

		// Step-CA - Certificate Authority for mTLS
		stepCA: base.#StepCAConfig & {
			enabled: true // Zero-Trust: MUST be enabled for mTLS
			pki: {
				rootCommonName:         "Homelab Root CA"
				intermediateCommonName: "Homelab Intermediate CA"
			}
		}
	}

	// ==========================================================================
	// LAYER 2: PLATFORM CONFIGURATION
	// ==========================================================================

	// Platform type declaration
	platform: base.#PlatformType | *"docker"

	// PAAS configuration (Dokploy or Coolify based on variant)
	paas: base.#PAASConfig & {
		type: *"dokploy" | "coolify"
		installMethod: "container"

		dokploy: base.#DokployConfig & {
			enabled: variant != "coolify"
		}

		coolify: base.#CoolifyConfig & {
			enabled: variant == "coolify"
		}
	}

	// Platform Identity (TinyAuth for secure variant)
	platformIdentity: base.#PlatformIdentityConfig & {
		tinyauth: base.#TinyAuthConfig & {
			enabled: variant == "secure"
		}
	}

	// ==========================================================================
	// LAYER 1: SYSTEM CONFIGURATION
	// ==========================================================================

	// System defaults for homelab
	system: {
		timezone:           string | *"UTC"
		locale:             "en_US.UTF-8"
		swap:               "auto"
		unattendedUpgrades: "security"
	}

	// Base packages with homelab extras
	packages: base.#BasePackages & {
		extra: [
			"docker-compose",
			"rsync",
			"sqlite3",
			"htop",
			"btop",
			"tmux",
			"jq",
			"micro",
		]
	}

	// User configuration
	users: base.#SystemUsers

	// Docker as container runtime
	container: base.#ContainerRuntime & {
		engine:        "docker"
		rootless:      false
		liveRestore:   true
		logDriver:     "json-file"
		networkDriver: "bridge"
	}

	// Security settings
	security: {
		ssh: base.#SSHHardening & {
			port:            22
			permitRootLogin: "no"
			passwordAuth:    false
			pubkeyAuth:      true
			maxAuthTries:    3
		}

		firewall: base.#FirewallPolicy & {
			enabled:         true
			backend:         "ufw"
			defaultInbound:  "deny"
			defaultOutbound: "allow"
			rules: [
				{port: 22, protocol: "tcp", comment:  "SSH"},
				{port: 80, protocol: "tcp", comment:  "HTTP"},
				{port: 443, protocol: "tcp", comment: "HTTPS"},
			]
		}

		container: base.#ContainerSecurityContext & {
			runAsNonRoot:   true
			privileged:     false
			noNewPrivileges: true
		}

		secrets: base.#SecretsPolicy & {
			backend: "file"
		}

		tls: base.#TLSPolicy & {
			minVersion:   "1.2"
			requireTLS:   true
			certSource:   "acme"
			acmeProvider: "letsencrypt"
		}

		audit: base.#AuditConfig & {
			enabled: false
		}
	}

	// Network configuration
	network: {
		defaults: base.#NetworkDefaults & {
			domain: string | *"local"
			subnet: "172.20.0.0/16"
		}

		dns: base.#DNSConfig & {
			servers: ["1.1.1.1", "8.8.8.8"]
		}

		ntp: base.#NTPConfig & {
			enabled: true
		}

		vpn: base.#VPNConfig & {
			enabled: false
			type:    "none"
		}

		proxy: base.#ProxyConfig & {
			enabled: false
		}
	}

	// Observability configuration
	observability: {
		logging: base.#LoggingConfig & {
			driver:  "json-file"
			level:   "info"
			maxSize: "50m"
			maxFile: 5
		}

		health: base.#HealthCheck & {
			enabled:  true
			interval: "30s"
			timeout:  "10s"
			retries:  3
		}

		metrics: base.#MetricsConfig & {
			enabled: true
			backend: "prometheus"
		}

		alerting: base.#AlertingConfig & {
			enabled: false
		}

		backup: base.#BackupConfig & {
			enabled:  true
			backend:  "restic"
			schedule: "0 3 * * *"
		}
	}

	// Constraint: Exactly 1 node for base-homelab
	nodes: [#MainNode, ...] & list.MaxItems(1)

	// Services based on variant selection
	services: *#DefaultServices | #DefaultServicesWithBeszel | #MinimalServices

	// Service URL outputs
	outputs: #ServiceOutputs
}

// #MainNode defines the single server for base-homelab
#MainNode: base.#NodeDefinition & {
	name: =~"^[a-z][a-z0-9-]+$"
	role: "main"
	type: "local"

	// Supported operating systems
	os: #SupportedOS

	// Resource requirements
	resources: #ResourceRequirements
}

// #SupportedOS for base-homelab
#SupportedOS: "ubuntu-24" | "ubuntu-22" | "debian-12"

// #ResourceRequirements with compute tier detection
#ResourceRequirements: base.#NodeResources & {
	cpu:    >=2
	memory: >=4
	disk:   >=50

	// Computed tier based on resources
	_tier: *"standard" | "high" | "low"
	if cpu >= 8 && memory >= 16 {
		_tier: "high"
	}
	if cpu < 4 || memory < 8 {
		_tier: "low"
	}
}

// #ServiceOutputs aggregates all service URLs for deployment output
#ServiceOutputs: {
	format: "markdown"
	
	// Collect URLs from all enabled services
	urls: [...{
		name:        string
		url:         string
		description: string
		credentials?: {
			defaultUser?: string
			note:         string
		}
	}]
}

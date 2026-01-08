// Package base_homelab provides a StackKit for single-server homelab deployments.
//
// Version 2.0 Changes:
//   - Default stack: Dokploy + Uptime Kuma (PaaS-focused)
//   - Alternative: Beszel monitoring instead of Uptime Kuma
//   - Minimal variant: Dockge + Portainer + Netdata
//
// Features:
//   - Single node deployment (local server)
//   - Traefik reverse proxy with auto-SSL
//   - Docker-based service deployment
//   - Multiple monitoring options
//   - Secure defaults (SSH hardening, firewall)
//
// Variants:
//   - default: Dokploy + Uptime Kuma
//   - beszel:  Dokploy + Beszel  
//   - minimal: Dockge + Portainer + Netdata
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

package base_homelab

import "github.com/kombihq/stackkits/base"

// #BaseHomelabKit extends the base StackKit for single-server deployments
#BaseHomelabKit: base.#BaseStackKit & {
	// StackKit metadata
	metadata: {
		name:        "base-homelab"
		displayName: "Base Homelab"
		version:     "2.0.0"
		description: "Single-server homelab with Docker, Dokploy and monitoring"
		author:      "KombiStack Team"
		license:     "MIT"
		tags: ["homelab", "single-node", "docker", "dokploy", "beginner"]

		minKombiStackVersion: "1.0.0"
	}

	// Variant selection
	variant: "default" | "beszel" | "minimal" | *"default"

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

// Import list for constraint
import "list"


// Package base - PAAS (Platform as a Service) schemas for Layer 2 Platform
// This file defines PAAS/management services that belong in Layer 2 (Platform)
// NOT Layer 3 (Applications). These are infrastructure controllers.
package base

// Ensure this file is part of the base package for easy importing

// =============================================================================
// PAAS SERVICE TYPES
// =============================================================================

// #PAASServiceType defines available PAAS platforms
#PAASServiceType: "dokploy" | "coolify" | "dokku" | "portainer" | "dockge"

// #PAASConfig is the main PAAS configuration block for Layer 2
#PAASConfig: {
	// PAAS platform selection
	type: #PAASServiceType

	// Installation method
	installMethod: #InstallMethod | *"container"

	// Dokploy configuration (when type == "dokploy")
	dokploy?: #DokployConfig

	// Coolify configuration (when type == "coolify")
	coolify?: #CoolifyConfig

	// Portainer configuration (when type == "portainer")
	portainer?: #PortainerConfig

	// Dockge configuration (when type == "dockge")
	dockge?: #DockgeConfig
}

// #InstallMethod defines how platform services are installed
#InstallMethod: "container" | "bare_metal" | "vm"

// =============================================================================
// DOKPLOY CONFIGURATION
// =============================================================================

// #DokployConfig defines Dokploy PAAS settings
#DokployConfig: {
	// Enable Dokploy
	enabled: bool | *true

	// Dokploy version
	version: string | *"latest"

	// Docker image
	image: string | *"dokploy/dokploy"

	// Web UI port
	port: uint16 & >0 & <=65535 | *3000

	// Database configuration (for Dokploy's internal use)
	database?: {
		// Use external database
		external: bool | *false

		// PostgreSQL version (if internal)
		postgresVersion: string | *"16-alpine"

		// Connection string (if external)
		connectionString?: string
	}

	// Traefik integration
	traefik: {
		// Enable Traefik routing
		enabled: bool | *true

		// Host rule for web UI
		host?: string

		// Use TLS
		tls: bool | *true

		// Middlewares to apply
		middlewares?: [...string]
	}

	// Storage configuration
	storage: {
		// Data volume name
		dataVolume: string | *"dokploy-data"

		// Backup enabled
		backup: bool | *true
	}

	// Resource limits
	resources?: #ResourceLimits

	// Environment variables
	environment?: [string]: string
}

// #DokployService generates a complete service definition for Dokploy
#DokployService: #ServiceDefinition & {
	name:        "dokploy"
	displayName: "Dokploy PAAS"
	image:       "dokploy/dokploy"
	tag:         string | *"latest"
	type:        "paas"
	required:    false

	// Dokploy is Layer 2 - platform management
	labels: {
		"traefik.enable":      "true"
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "paas"
	}

	network: {
		ports: [
			{host: 3000, container: 3000, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`deploy.{{.domain}}`)"
			tls:     true
			port:    3000
		}
	}

	volumes: [
		{
			source:      "/var/run/docker.sock"
			target:      "/var/run/docker.sock"
			type:        "bind"
			readOnly:    false
			backup:      false
			description: "Docker socket for container management"
		},
		{
			source:      "dokploy-data"
			target:      "/etc/dokploy"
			type:        "volume"
			backup:      true
			description: "Dokploy application data"
		},
	]

	environment: {
		"NODE_ENV":          "production"
		"PORT":              "3000"
		"TRPC_PLAYGROUND":   "false"
		"TRAEFIK_ENABLED":   "true"
	}

	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/settings"]
		interval: "30s"
		timeout:  "10s"
		retries:  5
	}

	resources: {
		memory: "512m"
		cpus:   0.5
	}

	securityContext: {
		noNewPrivileges: true
		capabilitiesDrop: ["ALL"]
	}

	config: {
		type:          "paas"
		installMethod: "container"
		backup:        true
	}
}

// =============================================================================
// COOLIFY CONFIGURATION
// =============================================================================

// #CoolifyConfig defines Coolify PAAS settings
#CoolifyConfig: {
	// Enable Coolify
	enabled: bool | *false

	// Coolify version
	version: string | *"latest"

	// Docker image
	image: string | *"ghcr.io/coollabsio/coolify"

	// Web UI port
	port: uint16 & >0 & <=65535 | *8000

	// Storage configuration
	storage: {
		// Data directory
		dataPath: string | *"/data/coolify"

		// Backup enabled
		backup: bool | *true
	}

	// Traefik integration
	traefik: {
		// Enable Traefik routing
		enabled: bool | *true

		// Host rule for web UI
		host?: string

		// Use TLS
		tls: bool | *true
	}

	// Resource limits
	resources?: #ResourceLimits
}

// #CoolifyService generates a complete service definition for Coolify
#CoolifyService: #ServiceDefinition & {
	name:        "coolify"
	displayName: "Coolify PAAS"
	image:       "ghcr.io/coolabsio/coolify"
	tag:         string | *"latest"
	type:        "paas"
	required:    false

	labels: {
		"traefik.enable":      "true"
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "paas"
	}

	network: {
		ports: [
			{host: 8000, container: 8000, protocol: "tcp", description: "Web UI"},
			{host: 6001, container: 6001, protocol: "tcp", description: "Websockets"},
			{host: 6002, container: 6002, protocol: "tcp", description: "Terminal"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`coolify.{{.domain}}`)"
			tls:     true
			port:    8000
		}
	}

	volumes: [
		{
			source:      "/var/run/docker.sock"
			target:      "/var/run/docker.sock"
			type:        "bind"
			readOnly:    false
			backup:      false
			description: "Docker socket for container management"
		},
		{
			source:      "/data/coolify"
			target:      "/data/coolify"
			type:        "bind"
			backup:      true
			description: "Coolify application data"
		},
	]

	environment: {
		"APP_URL":       "https://coolify.{{.domain}}"
		"DB_CONNECTION": "sqlite"
	}

	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:8000/"]
		interval: "30s"
		timeout:  "10s"
		retries:  3
	}

	resources: {
		memory: "1g"
		cpus:   2.0
	}
}

// =============================================================================
// PORTAINER CONFIGURATION
// =============================================================================

// #PortainerConfig defines Portainer container management settings
#PortainerConfig: {
	// Enable Portainer
	enabled: bool | *false

	// Portainer version
	version: string | *"latest"

	// Docker image
	image: string | *"portainer/portainer-ce"

	// Web UI port (HTTP)
	httpPort: uint16 & >0 & <=65535 | *9000

	// Web UI port (HTTPS)
	httpsPort: uint16 & >0 & <=65535 | *9443

	// Storage configuration
	storage: {
		// Data volume name
		dataVolume: string | *"portainer-data"

		// Backup enabled
		backup: bool | *true
	}

	// Traefik integration
	traefik: {
		// Enable Traefik routing
		enabled: bool | *true

		// Host rule for web UI
		host?: string

		// Use TLS
		tls: bool | *true
	}
}

// =============================================================================
// DOCKGE CONFIGURATION
// =============================================================================

// #DockgeConfig defines Dockge compose management settings
#DockgeConfig: {
	// Enable Dockge
	enabled: bool | *false

	// Dockge version
	version: string | *"1"

	// Docker image
	image: string | *"louislam/dockge"

	// Web UI port
	port: uint16 & >0 & <=65535 | *5001

	// Stacks directory
	stacksDir: string | *"/opt/stacks"

	// Storage configuration
	storage: {
		// Data volume name
		dataVolume: string | *"dockge-data"

		// Backup enabled
		backup: bool | *true
	}

	// Traefik integration
	traefik: {
		// Enable Traefik routing
		enabled: bool | *true

		// Host rule for web UI
		host?: string

		// Use TLS
		tls: bool | *true
	}
}

// =============================================================================
// BARE-METAL INSTALLATION SUPPORT
// =============================================================================

// #BareMetalInstall defines bare-metal installation configuration
#BareMetalInstall: {
	// Enable bare-metal installation method
	enabled: bool | *false

	// Installation directory
	installDir: string | *"/opt/stackkits"

	// Systemd service configuration
	systemd: {
		// Create systemd service
		enabled: bool | *true

		// Service user
		user: string | *"stackkits"

		// Service group
		group: string | *"stackkits"
	}

	// Binary download configuration
	binary: {
		// Download URL template
		urlTemplate: string

		// Version to install
		version: string | *"latest"

		// Checksum verification
		verifyChecksum: bool | *true
	}

	// Reverse proxy configuration (when not using Traefik in container)
	reverseProxy?: {
		// Type of reverse proxy
		type: "nginx" | "caddy" | "traefik-binary"

		// Configuration template
		configTemplate?: string

		// ACME email for TLS
		acmeEmail?: string
	}
}

// =============================================================================
// PLATFORM RUNTIME CONFIGURATION
// =============================================================================

// #PlatformRuntime extends ContainerRuntime with bare-metal support
#PlatformRuntime: {
	// Container engine or bare-metal
	engine: "docker" | "podman" | "kubernetes" | "bare-metal" | *"docker"

	// Installation method
	installMethod: #InstallMethod | *"container"

	// Bare-metal configuration (when engine == "bare-metal")
	bareMetal?: #BareMetalInstall

	// Container runtime config (when engine != "bare-metal")
	container?: #ContainerRuntime
}

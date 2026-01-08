// Package base_homelab - Service Definitions
// 
// Default Stack: Traefik + Dokploy + Uptime Kuma
// Alternative Stack: Traefik + Dockge + Portainer (minimal)
//
// Monitoring Options:
//   - Uptime Kuma (default): Simple uptime monitoring
//   - Beszel (alternative): Lightweight server metrics
//
// This file defines all available services for the Base Homelab StackKit.

package base_homelab

import "github.com/kombihq/stackkits/base"

// =============================================================================
// CORE SERVICES (Always Required)
// =============================================================================

// #TraefikService - Reverse Proxy with auto-SSL
#TraefikService: base.#ServiceDefinition & {
	name:        "traefik"
	displayName: "Traefik"
	category:    "core"
	type:        "reverse-proxy"
	required:    true
	image:       "traefik"
	tag:         "v3.1"
	description: "Modern reverse proxy with automatic HTTPS via Let's Encrypt"

	network: {
		ports: [
			{host: 80, container: 80, protocol: "tcp", description: "HTTP"},
			{host: 443, container: 443, protocol: "tcp", description: "HTTPS"},
			{host: 8080, container: 8080, protocol: "tcp", description: "Dashboard"},
		]
		mode: "bridge"
	}

	volumes: [
		{
			source:      "/var/run/docker.sock"
			target:      "/var/run/docker.sock"
			type:        "bind"
			readOnly:    true
			backup:      false
			description: "Docker socket for container discovery"
		},
		{
			source:      "traefik-certs"
			target:      "/certs"
			type:        "volume"
			backup:      true
			description: "SSL certificates storage"
		},
		{
			source:      "traefik-config"
			target:      "/etc/traefik"
			type:        "volume"
			backup:      true
			description: "Traefik configuration"
		},
	]

	healthCheck: {
		enabled: true
		http: {
			path:   "/ping"
			port:   8080
			scheme: "http"
		}
		interval:    "10s"
		timeout:     "5s"
		retries:     3
		startPeriod: "10s"
	}

	config: {
		dashboard:         bool | *true
		dashboardInsecure: bool | *false
		acme:              bool | *true
		acmeEmail:         string
		acmeProvider:      "letsencrypt" | "letsencrypt-staging" | *"letsencrypt"
		logLevel:          "DEBUG" | "INFO" | "WARN" | "ERROR" | *"INFO"
	}

	labels: {
		"traefik.enable":                            "true"
		"traefik.http.routers.api.entrypoints":      "websecure"
		"traefik.http.routers.api.rule":             "Host(`traefik.{{.domain}}`)"
		"traefik.http.routers.api.service":          "api@internal"
		"traefik.http.routers.api.tls.certresolver": "letsencrypt"
	}

	// Output URL for this service
	output: {
		url:         "https://traefik.{{.domain}}"
		description: "Traefik Dashboard"
		credentials: {
			note: "Protected by middleware or basic auth"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// DEFAULT PLATFORM: DOKPLOY
// =============================================================================

// #DokployService - Self-hosted PaaS Platform (Default)
#DokployService: base.#ServiceDefinition & {
	name:        "dokploy"
	displayName: "Dokploy"
	category:    "platform"
	type:        "paas"
	required:    false
	enabled:     true // Default enabled
	image:       "dokploy/dokploy"
	tag:         "latest"
	description: "Self-hosted PaaS for deploying applications with Docker"
	needs:       ["traefik"]

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
			target:      "/app/data"
			type:        "volume"
			backup:      true
			description: "Dokploy application data"
		},
	]

	environment: {
		"NODE_ENV": "production"
	}

	healthCheck: {
		enabled: true
		http: {
			path:   "/api/health"
			port:   3000
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "60s"
	}

	resources: {
		memory:    "512m"
		memoryMax: "1g"
		cpus:      1.0
	}

	labels: {
		"traefik.enable":                                       "true"
		"traefik.http.routers.dokploy.entrypoints":             "websecure"
		"traefik.http.routers.dokploy.rule":                    "Host(`deploy.{{.domain}}`)"
		"traefik.http.routers.dokploy.tls.certresolver":        "letsencrypt"
		"traefik.http.services.dokploy.loadbalancer.server.port": "3000"
	}

	output: {
		url:         "https://deploy.{{.domain}}"
		description: "Dokploy Dashboard - Deploy and manage applications"
		credentials: {
			defaultUser: "admin"
			note:        "Set password during first login"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// MONITORING OPTIONS (Choose One)
// =============================================================================

// #UptimeKumaService - Uptime Monitoring (Default)
#UptimeKumaService: base.#ServiceDefinition & {
	name:        "uptime-kuma"
	displayName: "Uptime Kuma"
	category:    "monitoring"
	type:        "uptime"
	required:    false
	enabled:     true // Default monitoring choice
	image:       "louislam/uptime-kuma"
	tag:         "1"
	description: "Self-hosted uptime monitoring with beautiful status pages"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 3001, container: 3001, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`status.{{.domain}}`)"
			tls:     true
			port:    3001
		}
	}

	volumes: [
		{
			source:      "uptime-kuma-data"
			target:      "/app/data"
			type:        "volume"
			backup:      true
			description: "Uptime Kuma database and configuration"
		},
	]

	healthCheck: {
		enabled: true
		http: {
			path:   "/"
			port:   3001
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "30s"
	}

	resources: {
		memory:    "256m"
		memoryMax: "512m"
		cpus:      0.5
	}

	labels: {
		"traefik.enable":                                           "true"
		"traefik.http.routers.uptime-kuma.entrypoints":             "websecure"
		"traefik.http.routers.uptime-kuma.rule":                    "Host(`status.{{.domain}}`)"
		"traefik.http.routers.uptime-kuma.tls.certresolver":        "letsencrypt"
		"traefik.http.services.uptime-kuma.loadbalancer.server.port": "3001"
	}

	output: {
		url:         "https://status.{{.domain}}"
		description: "Uptime Kuma - Service status and monitoring"
		credentials: {
			note: "Create admin account on first access"
		}
	}

	restartPolicy: "unless-stopped"
}

// #BeszelService - Lightweight Server Monitoring (Alternative to Uptime Kuma)
#BeszelService: base.#ServiceDefinition & {
	name:        "beszel"
	displayName: "Beszel"
	category:    "monitoring"
	type:        "metrics"
	required:    false
	enabled:     false // Alternative, not default
	image:       "henrygd/beszel"
	tag:         "latest"
	description: "Lightweight server monitoring with historical data and alerts"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 8090, container: 8090, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`monitor.{{.domain}}`)"
			tls:     true
			port:    8090
		}
	}

	volumes: [
		{
			source:      "beszel-data"
			target:      "/beszel_data"
			type:        "volume"
			backup:      true
			description: "Beszel database and metrics"
		},
	]

	healthCheck: {
		enabled: true
		http: {
			path:   "/api/health"
			port:   8090
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "30s"
	}

	resources: {
		memory:    "128m"
		memoryMax: "256m"
		cpus:      0.25
	}

	labels: {
		"traefik.enable":                                      "true"
		"traefik.http.routers.beszel.entrypoints":             "websecure"
		"traefik.http.routers.beszel.rule":                    "Host(`monitor.{{.domain}}`)"
		"traefik.http.routers.beszel.tls.certresolver":        "letsencrypt"
		"traefik.http.services.beszel.loadbalancer.server.port": "8090"
	}

	output: {
		url:         "https://monitor.{{.domain}}"
		description: "Beszel - Server metrics and monitoring"
		credentials: {
			note: "Create admin account on first access"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// LOG VIEWER (Always Included)
// =============================================================================

// #DozzleService - Real-time Docker Log Viewer
#DozzleService: base.#ServiceDefinition & {
	name:        "dozzle"
	displayName: "Dozzle"
	category:    "observability"
	type:        "logs"
	required:    true
	enabled:     true
	image:       "amir20/dozzle"
	tag:         "latest"
	description: "Real-time Docker container log viewer"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 8081, container: 8080, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`logs.{{.domain}}`)"
			tls:     true
			port:    8080
		}
	}

	volumes: [
		{
			source:      "/var/run/docker.sock"
			target:      "/var/run/docker.sock"
			type:        "bind"
			readOnly:    true
			backup:      false
			description: "Docker socket for log access"
		},
	]

	healthCheck: {
		enabled: true
		http: {
			path:   "/healthcheck"
			port:   8080
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "5s"
		retries:     3
		startPeriod: "10s"
	}

	resources: {
		memory:    "128m"
		memoryMax: "256m"
		cpus:      0.25
	}

	labels: {
		"traefik.enable":                                      "true"
		"traefik.http.routers.dozzle.entrypoints":             "websecure"
		"traefik.http.routers.dozzle.rule":                    "Host(`logs.{{.domain}}`)"
		"traefik.http.routers.dozzle.tls.certresolver":        "letsencrypt"
		"traefik.http.services.dozzle.loadbalancer.server.port": "8080"
	}

	output: {
		url:         "https://logs.{{.domain}}"
		description: "Dozzle - Real-time container logs"
		credentials: {
			note: "No authentication by default (use Traefik middleware)"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// SAMPLE APPLICATION: Lightweight Test Service
// =============================================================================

// #WhoamiService - Simple test container for verification
#WhoamiService: base.#ServiceDefinition & {
	name:        "whoami"
	displayName: "Whoami"
	category:    "test"
	type:        "application"
	required:    false
	enabled:     true // Included for testing proxy configuration
	image:       "traefik/whoami"
	tag:         "latest"
	description: "Simple HTTP server for testing reverse proxy configuration"
	needs:       ["traefik"]

	network: {
		ports: [
			{container: 80, protocol: "tcp", description: "HTTP"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`whoami.{{.domain}}`)"
			tls:     true
			port:    80
		}
	}

	healthCheck: {
		enabled: true
		http: {
			path:   "/health"
			port:   80
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "5s"
		retries:     3
		startPeriod: "5s"
	}

	resources: {
		memory:    "32m"
		memoryMax: "64m"
		cpus:      0.1
	}

	labels: {
		"traefik.enable":                                      "true"
		"traefik.http.routers.whoami.entrypoints":             "websecure"
		"traefik.http.routers.whoami.rule":                    "Host(`whoami.{{.domain}}`)"
		"traefik.http.routers.whoami.tls.certresolver":        "letsencrypt"
		"traefik.http.services.whoami.loadbalancer.server.port": "80"
	}

	output: {
		url:         "https://whoami.{{.domain}}"
		description: "Whoami - Test service showing request info"
		credentials: {
			note: "No authentication required"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// MINIMAL VARIANT SERVICES (Alternative Stack)
// =============================================================================

// #DockgeService - Docker Compose Management (Minimal Variant)
#DockgeService: base.#ServiceDefinition & {
	name:        "dockge"
	displayName: "Dockge"
	category:    "management"
	type:        "compose-manager"
	required:    false
	enabled:     false // Only in minimal variant
	image:       "louislam/dockge"
	tag:         "1"
	description: "Visual Docker Compose management interface"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 5001, container: 5001, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`dockge.{{.domain}}`)"
			tls:     true
			port:    5001
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
			source:      "dockge-data"
			target:      "/app/data"
			type:        "volume"
			backup:      true
			description: "Dockge application data"
		},
		{
			source:      "/opt/stacks"
			target:      "/opt/stacks"
			type:        "bind"
			backup:      true
			description: "Docker Compose stacks directory"
		},
	]

	environment: {
		"DOCKGE_STACKS_DIR": "/opt/stacks"
	}

	healthCheck: {
		enabled: true
		http: {
			path:   "/"
			port:   5001
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "10s"
	}

	resources: {
		memory:    "256m"
		memoryMax: "512m"
		cpus:      0.5
	}

	labels: {
		"traefik.enable":                                      "true"
		"traefik.http.routers.dockge.entrypoints":             "websecure"
		"traefik.http.routers.dockge.rule":                    "Host(`dockge.{{.domain}}`)"
		"traefik.http.routers.dockge.tls.certresolver":        "letsencrypt"
		"traefik.http.services.dockge.loadbalancer.server.port": "5001"
	}

	output: {
		url:         "https://dockge.{{.domain}}"
		description: "Dockge - Docker Compose Manager"
		credentials: {
			note: "Create admin account on first access"
		}
	}

	restartPolicy: "unless-stopped"
}

// #PortainerService - Container Management (Minimal Variant)
#PortainerService: base.#ServiceDefinition & {
	name:        "portainer"
	displayName: "Portainer CE"
	category:    "management"
	type:        "container-manager"
	required:    false
	enabled:     false // Only in minimal variant
	image:       "portainer/portainer-ce"
	tag:         "latest"
	description: "Full-featured Docker management UI"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 9000, container: 9000, protocol: "tcp", description: "Web UI"},
			{host: 9443, container: 9443, protocol: "tcp", description: "HTTPS UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`portainer.{{.domain}}`)"
			tls:     true
			port:    9000
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
			source:      "portainer-data"
			target:      "/data"
			type:        "volume"
			backup:      true
			description: "Portainer data and settings"
		},
	]

	healthCheck: {
		enabled: true
		http: {
			path:   "/api/status"
			port:   9000
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "30s"
	}

	resources: {
		memory:    "256m"
		memoryMax: "512m"
		cpus:      0.5
	}

	labels: {
		"traefik.enable":                                         "true"
		"traefik.http.routers.portainer.entrypoints":             "websecure"
		"traefik.http.routers.portainer.rule":                    "Host(`portainer.{{.domain}}`)"
		"traefik.http.routers.portainer.tls.certresolver":        "letsencrypt"
		"traefik.http.services.portainer.loadbalancer.server.port": "9000"
	}

	output: {
		url:         "https://portainer.{{.domain}}"
		description: "Portainer - Container Management"
		credentials: {
			note: "Create admin account on first access (password min 12 chars)"
		}
	}

	restartPolicy: "unless-stopped"
}

// #NetdataService - System Monitoring (Minimal Variant)
#NetdataService: base.#ServiceDefinition & {
	name:        "netdata"
	displayName: "Netdata"
	category:    "monitoring"
	type:        "metrics"
	required:    false
	enabled:     false // Only in minimal variant
	image:       "netdata/netdata"
	tag:         "stable"
	description: "Real-time system monitoring with detailed metrics"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 19999, container: 19999, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`netdata.{{.domain}}`)"
			tls:     true
			port:    19999
		}
	}

	volumes: [
		{
			source:   "/proc"
			target:   "/host/proc"
			type:     "bind"
			readOnly: true
			backup:   false
		},
		{
			source:   "/sys"
			target:   "/host/sys"
			type:     "bind"
			readOnly: true
			backup:   false
		},
		{
			source:   "/var/run/docker.sock"
			target:   "/var/run/docker.sock"
			type:     "bind"
			readOnly: true
			backup:   false
		},
		{
			source: "netdata-config"
			target: "/etc/netdata"
			type:   "volume"
			backup: true
		},
		{
			source: "netdata-lib"
			target: "/var/lib/netdata"
			type:   "volume"
			backup: true
		},
		{
			source: "netdata-cache"
			target: "/var/cache/netdata"
			type:   "volume"
			backup: false
		},
	]

	securityContext: {
		capabilitiesAdd: ["SYS_PTRACE"]
	}

	healthCheck: {
		enabled: true
		http: {
			path:   "/api/v1/info"
			port:   19999
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "30s"
	}

	resources: {
		memory:    "512m"
		memoryMax: "1g"
		cpus:      1.0
	}

	labels: {
		"traefik.enable":                                       "true"
		"traefik.http.routers.netdata.entrypoints":             "websecure"
		"traefik.http.routers.netdata.rule":                    "Host(`netdata.{{.domain}}`)"
		"traefik.http.routers.netdata.tls.certresolver":        "letsencrypt"
		"traefik.http.services.netdata.loadbalancer.server.port": "19999"
	}

	output: {
		url:         "https://netdata.{{.domain}}"
		description: "Netdata - System Monitoring"
		credentials: {
			note: "No authentication by default"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// SERVICE COLLECTIONS (Pre-defined Service Sets)
// =============================================================================

// #DefaultServices - Standard deployment (Dokploy-based)
#DefaultServices: [
	#TraefikService,
	#DokployService,
	#UptimeKumaService,
	#DozzleService,
	#WhoamiService,
]

// #DefaultServicesWithBeszel - Alternative monitoring
#DefaultServicesWithBeszel: [
	#TraefikService,
	#DokployService,
	#BeszelService,
	#DozzleService,
	#WhoamiService,
]

// #MinimalServices - Minimal variant (Dockge + Portainer)
#MinimalServices: [
	#TraefikService,
	#DockgeService,
	#PortainerService,
	#NetdataService,
	#DozzleService,
]

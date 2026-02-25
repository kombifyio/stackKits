// Package base_homelab - Service Definitions
//
// Layer Architecture:
//   Layer 1 (Foundation): System, security, core identity (LLDAP, Step-CA from base)
//   Layer 2 (Platform): Traefik, PAAS (Dokploy/Coolify), Platform Identity (TinyAuth, PocketID)
//   Layer 3 (Applications): Uptime Kuma, Beszel, Whoami, etc. (user applications)
//
// PaaS Strategy:
//   - Dokploy (default): For users WITHOUT a domain (ports mode, simpler)
//   - Coolify (option):  For users WITH a domain (proxy mode, more features)
//
// Variants:
//   - default: Traefik + Dokploy + Uptime Kuma (local/no-domain users)
//   - coolify: Traefik + Coolify + Uptime Kuma (own-domain users)
//   - beszel:  Traefik + Dokploy + Beszel (server metrics focus)
//   - minimal: Traefik + Dockge + Portainer (lightweight)
//   - secure:  Traefik + Dokploy + TinyAuth + Uptime Kuma (with auth)
//
// Monitoring Options:
//   - Uptime Kuma (default): Simple uptime monitoring
//   - Beszel (alternative): Lightweight server metrics
//
// Platform Identity Options (Layer 2):
//   - TinyAuth: Lightweight identity proxy (simple, fast)
//   - PocketID: Full OIDC provider (SSO, more features)
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
	tag:         "v3.3"
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
		// Layer classification
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
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
// LAYER 2: PLATFORM IDENTITY SERVICES
// =============================================================================

// #TinyAuthService - Lightweight Identity Proxy (Layer 2)
#TinyAuthService: base.#ServiceDefinition & {
	name:        "tinyauth"
	displayName: "TinyAuth"
	category:    "platform-identity"
	type:        "auth"
	required:    false
	enabled:     false // Disabled by default in base-homelab
	image:       "ghcr.io/steveiliop56/tinyauth"
	tag:         "v4"
	description: "Lightweight authentication proxy with ForwardAuth, passkeys, and OAuth"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 4002, container: 3000, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`auth.{{.domain}}`)"
			tls:     true
			port:    3000
		}
	}

	volumes: [
		{
			source:      "tinyauth-data"
			target:      "/data"
			type:        "volume"
			backup:      true
			description: "TinyAuth SQLite database and session data"
		},
		{
			source:      "/var/run/docker.sock"
			target:      "/var/run/docker.sock"
			type:        "bind"
			readOnly:    true
			backup:      false
			description: "Docker socket for label-based access control"
		},
	]

	environment: {
		"TZ":             "Europe/Berlin"
		"APP_URL":        "https://auth.{{.domain}}"
		"USERS":          "{{.tinyauth_users}}"
		"SECURE_COOKIE":  "{{.tinyauth_secure_cookie}}"
		"SESSION_EXPIRY": "{{.tinyauth_session_expiry}}"
	}

	healthCheck: {
		enabled: true
		command: "tinyauth healthcheck"
		interval:    "30s"
		timeout:     "5s"
		retries:     3
		startPeriod: "15s"
	}

	resources: {
		memory:    "128m"
		memoryMax: "256m"
		cpus:      0.25
	}

	labels: {
		"traefik.enable":                                                        "true"
		"traefik.http.routers.tinyauth.entrypoints":                             "websecure"
		"traefik.http.routers.tinyauth.rule":                                    "Host(`auth.{{.domain}}`)"
		"traefik.http.routers.tinyauth.tls.certresolver":                        "letsencrypt"
		"traefik.http.services.tinyauth.loadbalancer.server.port":               "3000"
		"traefik.http.middlewares.tinyauth.forwardauth.address":                 "http://tinyauth:3000/api/auth/traefik"
		"traefik.http.middlewares.tinyauth.forwardauth.trustForwardHeader":      "true"
		"traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders":     "remote-user,remote-sub,remote-name,remote-email,remote-groups"
		// Layer classification
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "platform-identity"
	}

	output: {
		url:         "https://auth.{{.domain}}"
		description: "TinyAuth - Authentication portal with passkeys and OAuth"
		credentials: {
			note: "Credentials set via USERS env var (bcrypt hashed)"
		}
	}

	restartPolicy: "unless-stopped"
}

// #PocketIDService - OIDC Provider (Layer 2)
#PocketIDService: base.#ServiceDefinition & {
	name:        "pocketid"
	displayName: "PocketID"
	category:    "platform-identity"
	type:        "auth"
	required:    false
	enabled:     false // Disabled by default
	image:       "ghcr.io/pocket-id/pocket-id"
	tag:         "v1"
	description: "Self-hosted OIDC provider for single sign-on"
	needs:       ["traefik"]

	network: {
		ports: [
			{host: 4003, container: 80, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`id.{{.domain}}`)"
			tls:     true
			port:    80
		}
	}

	volumes: [
		{
			source:      "pocketid-data"
			target:      "/app/backend/data"
			type:        "volume"
			backup:      true
			description: "PocketID database and config"
		},
	]

	environment: {
		"TZ":              "Europe/Berlin"
		"PUBLIC_APP_URL":  "https://id.{{.domain}}"
		"TRUST_PROXY":     "true"
	}

	healthCheck: {
		enabled: true
		http: {
			path:   "/api/health"
			port:   80
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "5s"
		retries:     3
		startPeriod: "30s"
	}

	resources: {
		memory:    "256m"
		memoryMax: "512m"
		cpus:      0.5
	}

	labels: {
		"traefik.enable":                                      "true"
		"traefik.http.routers.pocketid.entrypoints":           "websecure"
		"traefik.http.routers.pocketid.rule":                  "Host(`id.{{.domain}}`)"
		"traefik.http.routers.pocketid.tls.certresolver":      "letsencrypt"
		"traefik.http.services.pocketid.loadbalancer.server.port": "80"
		// Layer classification
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "platform-identity"
	}

	output: {
		url:         "https://id.{{.domain}}"
		description: "PocketID - OIDC provider for SSO"
		credentials: {
			note: "Configure on first access"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// DEFAULT PLATFORM: DOKPLOY (Layer 2 PAAS)
// =============================================================================

// #DokployService - Self-hosted PaaS Platform (Layer 2)
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
			{host: 4000, container: 3000, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`dokploy.{{.domain}}`)"
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
		"traefik.http.routers.dokploy.rule":                    "Host(`dokploy.{{.domain}}`)"
		"traefik.http.routers.dokploy.tls.certresolver":        "letsencrypt"
		"traefik.http.services.dokploy.loadbalancer.server.port": "3000"
		// Layer classification
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
	}

	output: {
		url:         "https://dokploy.{{.domain}}"
		description: "Dokploy Dashboard - Deploy and manage applications"
		credentials: {
			defaultUser: "admin"
			note:        "Set password during first login"
		}
	}

	restartPolicy: "unless-stopped"
}

// =============================================================================
// ALTERNATIVE PLATFORM: COOLIFY (For users with own domain)
// =============================================================================

// #CoolifyService - Self-hosted PaaS Platform (Alternative to Dokploy)
// Use when: User has their own domain and wants more features
#CoolifyService: base.#ServiceDefinition & {
	name:        "coolify"
	displayName: "Coolify"
	category:    "platform"
	type:        "paas"
	required:    false
	enabled:     false // Not default, enabled in "coolify" variant
	image:       "ghcr.io/coollabsio/coolify"
	tag:         "latest"
	description: "Self-hosted Heroku/Vercel alternative - recommended for users with own domain"
	needs:       ["traefik"]

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
			description: "Coolify application data and SSH keys"
		},
	]

	environment: {
		"APP_ID":       "{{.coolify_app_id}}"
		"APP_KEY":      "{{.coolify_app_key}}"
		"APP_URL":      "https://coolify.{{.domain}}"
		"DB_CONNECTION": "sqlite"
	}

	healthCheck: {
		enabled: true
		http: {
			path:   "/"
			port:   8000
			scheme: "http"
		}
		interval:    "30s"
		timeout:     "10s"
		retries:     3
		startPeriod: "90s"  // Coolify takes longer to start
	}

	resources: {
		memory:    "1g"
		memoryMax: "2g"
		cpus:      2.0
	}

	labels: {
		"traefik.enable":                                        "true"
		"traefik.http.routers.coolify.entrypoints":              "websecure"
		"traefik.http.routers.coolify.rule":                     "Host(`coolify.{{.domain}}`)"
		"traefik.http.routers.coolify.tls.certresolver":         "letsencrypt"
		"traefik.http.services.coolify.loadbalancer.server.port": "8000"
		// Layer classification
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
	}

	output: {
		url:         "https://coolify.{{.domain}}"
		description: "Coolify Dashboard - Deploy applications from Git"
		credentials: {
			defaultUser: "admin@example.com"
			note:        "Set email and password during first setup"
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
			{host: 4001, container: 3001, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`kuma.{{.domain}}`)"
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
		"traefik.http.routers.uptime-kuma.rule":                    "Host(`kuma.{{.domain}}`)"
		"traefik.http.routers.uptime-kuma.tls.certresolver":        "letsencrypt"
		"traefik.http.services.uptime-kuma.loadbalancer.server.port": "3001"
		// Layer classification - deployed via PAAS (Dokploy)
		"stackkit.layer":      "3-application"
		"stackkit.managed-by": "dokploy"
	}

	output: {
		url:         "https://kuma.{{.domain}}"
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
		// Layer classification - deployed via PAAS (Dokploy)
		"stackkit.layer":      "3-application"
		"stackkit.managed-by": "dokploy"
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
		// Layer classification - Platform observability, deployed via Terraform
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
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
		// Layer classification - deployed via PAAS (Dokploy)
		"stackkit.layer":      "3-application"
		"stackkit.managed-by": "dokploy"
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
		// Layer classification - Platform management, deployed via Terraform
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
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
		// Layer classification - Platform management, deployed via Terraform
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
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
		// Layer classification - deployed via PAAS (Dokploy)
		"stackkit.layer":      "3-application"
		"stackkit.managed-by": "dokploy"
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

// #DefaultServices - Standard deployment (Dokploy-based, with identity)
// Service enablement is controlled by tfvars at deployment time.
#DefaultServices: {
	traefik:    #TraefikService
	tinyauth:   #TinyAuthService
	pocketid:   #PocketIDService
	dokploy:    #DokployService
	uptimeKuma: #UptimeKumaService
	dozzle:     #DozzleService
	whoami:     #WhoamiService
}

// #DefaultServicesWithBeszel - Alternative monitoring (with identity)
#DefaultServicesWithBeszel: {
	traefik:  #TraefikService
	tinyauth: #TinyAuthService
	pocketid: #PocketIDService
	dokploy:  #DokployService
	beszel:   #BeszelService
	dozzle:   #DozzleService
	whoami:   #WhoamiService
}

// #DefaultServicesWithAuth - With platform identity (TinyAuth)
#DefaultServicesWithAuth: {
	traefik:    #TraefikService
	tinyauth:   #TinyAuthService
	dokploy:    #DokployService
	uptimeKuma: #UptimeKumaService
	dozzle:     #DozzleService
	whoami:     #WhoamiService
}

// #MinimalServices - Minimal variant (Dockge + Portainer)
#MinimalServices: {
	traefik:   #TraefikService
	dockge:    #DockgeService
	portainer: #PortainerService
	netdata:   #NetdataService
	dozzle:    #DozzleService
}

// #SecureServices - With TinyAuth authentication
#SecureServices: {
	traefik:    #TraefikService
	tinyauth:   #TinyAuthService
	dokploy:    #DokployService
	uptimeKuma: #UptimeKumaService
	dozzle:     #DozzleService
	whoami:     #WhoamiService
}

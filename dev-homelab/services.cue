package devhomelab

// Dev Homelab Service Definitions
// Production-ready services with security, persistence, and proper management
// Implements 3-layer architecture with explicit service types

import "github.com/kombihq/stackkits/base"

// =============================================================================
// CORE SERVICES
// =============================================================================

// Whoami test service - deployed THROUGH Dokploy, not standalone
#WhoamiService: base.#Service & {
	name:        "whoami"
	image:       "traefik/whoami:latest"
	description: "Simple HTTP service for deployment testing - managed by Dokploy"
	role:        "test-endpoint"
	type:        "utility"
	
	ports: [{
		container: 80
		host:      9080
		protocol:  "tcp"
	}]
	
	healthCheck: {
		endpoint: "/"
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "64m"
		cpu:    0.1
	}
	
	// Security: Require authentication
	security: {
		requireAuth: true
		authProvider: "tinyauth"
	}
}

// Uptime Kuma - Monitoring Service - deployed THROUGH Dokploy
#UptimeKumaService: base.#Service & {
	name:        "uptime-kuma"
	image:       "louislam/uptime-kuma:1"
	description: "Self-hosted monitoring tool - managed by Dokploy"
	role:        "monitoring"
	type:        "monitoring"
	
	ports: [{
		container: 3001
		host:      3001
		protocol:  "tcp"
	}]
	
	volumes: [{
		name:   "kuma-data"
		path:   "/app/data"
		driver: "local"
		backup: "required"
	}]
	
	healthCheck: {
		endpoint: "/"
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "256m"
		cpu:    0.2
	}
	
	// Security: Require authentication
	security: {
		requireAuth: true
		authProvider: "tinyauth"
	}
}

// =============================================================================
// PLATFORM SERVICES
// =============================================================================

// Dokploy - PAAS/Management Tool (MANAGES other services)
#DokployService: base.#Service & {
	name:        "dokploy"
	image:       "dokploy/dokploy:latest"
	description: "Open-source PAAS for deploying applications - manages Kuma and Whoami"
	role:        "paas"
	type:        "paas"
	
	ports: [{
		container: 3000
		host:      3000
		protocol:  "tcp"
	}]
	
	volumes: [{
		name:   "dokploy-data"
		path:   "/etc/dokploy"
		driver: "local"
		backup: "required"
	}]
	
	mounts: [{
		type:   "bind"
		source: "/var/run/docker.sock"
		target: "/var/run/docker.sock"
	}]
	
	env: {
		"NODE_ENV": "production"
		"TRAEFIK_ENABLED": "true"
	}
	
	healthCheck: {
		endpoint: "/api/trpc/health.live"
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "512m"
		cpu:    0.5
	}
	
	// Security: Require authentication
	security: {
		requireAuth: true
		authProvider: "tinyauth"
	}
	
	// Dependencies
	dependsOn: ["dokploy-postgres", "traefik"]
}

// Dokploy PostgreSQL Database
#DokployPostgresService: base.#Service & {
	name:        "dokploy-postgres"
	image:       "postgres:16-alpine"
	description: "PostgreSQL database for Dokploy"
	role:        "database"
	type:        "database"
	
	volumes: [{
		name:   "dokploy-postgres-data"
		path:   "/var/lib/postgresql/data"
		driver: "local"
		backup: "required"
	}]
	
	env: {
		"POSTGRES_USER":     "dokploy"
		"POSTGRES_DB":       "dokploy"
		"PGDATA":            "/var/lib/postgresql/data/pgdata"
	}
	
	healthCheck: {
		command:  "pg_isready -U dokploy -d dokploy"
		interval: "10s"
		timeout:  "5s"
		retries:  5
	}
	
	resources: {
		memory: "256m"
		cpu:    0.2
	}
	
	// Internal network only
	networkMode: "internal"
}

// =============================================================================
// REVERSE PROXY & NETWORKING
// =============================================================================

// Traefik - Reverse Proxy for automatic HTTPS and routing
#TraefikService: base.#Service & {
	name:        "traefik"
	image:       "traefik:v3.1"
	description: "Cloud-native reverse proxy and load balancer"
	role:        "proxy"
	type:        "proxy"
	
	ports: [
		{
			container: 80
			host:      80
			protocol:  "tcp"
		},
		{
			container: 443
			host:      443
			protocol:  "tcp"
		},
		{
			container: 8080
			host:      8080
			protocol:  "tcp"
		},
	]
	
	volumes: [
		{
			name:   "traefik-data"
			path:   "/etc/traefik"
			driver: "local"
		},
		{
			name:   "traefik-certs"
			path:   "/letsencrypt"
			driver: "local"
			backup: "required"
		},
	]
	
	mounts: [{
		type:   "bind"
		source: "/var/run/docker.sock"
		target: "/var/run/docker.sock"
		readOnly: true
	}]
	
	command: [
		"--api.dashboard=true",
		"--api.insecure=true",
		"--providers.docker=true",
		"--providers.docker.exposedbydefault=false",
		"--entrypoints.web.address=:80",
		"--entrypoints.websecure.address=:443",
		"--certificatesresolvers.local.acme.tlschallenge=true",
		"--certificatesresolvers.local.acme.storage=/letsencrypt/acme.json",
		"--log.level=INFO",
		"--accesslog=true",
	]
	
	healthCheck: {
		endpoint: "/ping"
		port:     8080
		interval: "10s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "128m"
		cpu:    0.2
	}
	
	// Security hardening
	security: {
		readOnlyRootFilesystem: true
		noNewPrivileges: true
		capabilities: {
			drop: ["ALL"]
			add: ["NET_BIND_SERVICE"]
		}
	}
}

// =============================================================================
// SECURITY SERVICES
// =============================================================================

// TinyAuth - OIDC/SSO Authentication Proxy
#TinyAuthService: base.#Service & {
	name:        "tinyauth"
	image:       "ghcr.io/steveiliop56/tinyauth:v3"
	description: "Lightweight OIDC SSO proxy for protecting services"
	role:        "auth"
	type:        "auth"
	
	ports: [{
		container: 3000
		host:      0  // No direct host port - accessed via Traefik
		protocol:  "tcp"
	}]
	
	volumes: [{
		name:   "tinyauth-data"
		path:   "/data"
		driver: "local"
		backup: "required"
	}]
	
	env: {
		"TZ": "Europe/Berlin"
		"LOG_LEVEL": "info"
	}
	
	healthCheck: {
		endpoint: "/api/health"
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "128m"
		cpu:    0.1
	}
	
	// Security hardening
	security: {
		readOnlyRootFilesystem: true
		noNewPrivileges: true
		capabilities: {
			drop: ["ALL"]
		}
		user: "1000:1000"
	}
}

// =============================================================================
// SERVICE REGISTRY
// =============================================================================

// Service registry for dev-homelab
#Services: {
	// Platform services
	traefik:          #TraefikService
	tinyauth:         #TinyAuthService
	
	// Database
	dokployPostgres:  #DokployPostgresService
	
	// PAAS
	dokploy:          #DokployService
	
	// Managed by Dokploy (not deployed directly)
	whoami:           #WhoamiService
	uptimeKuma:       #UptimeKumaService
}
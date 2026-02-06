package devhomelab

// =============================================================================
// Dev Homelab Service Definitions - Hybrid Architecture
// =============================================================================
// Platform services (Layer 1-2) via Terraform
// Application services (Layer 3) via Dokploy
// =============================================================================

import "github.com/kombihq/stackkits/base"

// =============================================================================
// LAYER 1: FOUNDATION SERVICES
// =============================================================================
// NOTE: Layer 1 foundation services are from base (LLDAP, Step-CA).
// TinyAuth is a Layer 2 platform identity service, defined below.

// =============================================================================
// LAYER 2: PLATFORM SERVICES
// =============================================================================

// TinyAuth - Platform Identity Proxy (Layer 2)
// Provides application-level authentication/authorization
#TinyAuthService: base.#ServiceDefinition & {
	name:        "tinyauth"
	displayName: "TinyAuth Identity Proxy"
	image:       "ghcr.io/steveiliop56/tinyauth"
	tag:         "v3"
	type:        "auth"
	
	// Managed by: Terraform (not Dokploy)
	managedBy: "terraform"
	layer:     "2-platform"
	
	network: {
		traefik: {
			enabled: true
			rule:    "Host(`auth.stack.local`)"
			port:    3000
		}
	}
	
	volumes: [
		{source: "tinyauth-data", target: "/data", type: "volume", backup: true},
	]
	
	environment: {
		"TZ":      "Europe/Berlin"
		"APP_URL": "http://auth.stack.local"
		"LOG_LEVEL": "info"
	}
	
	labels: {
		"traefik.enable": "true"
		"stackkit.layer": "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "platform-identity"
		"traefik.http.middlewares.tinyauth.forwardauth.address": "http://tinyauth:3000/api/auth/verify"
		"traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders": "X-User,X-Email"
	}
	
	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/health"]
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "128m"
		cpus:   0.1
	}
	
	securityContext: {
		runAsUser:              1000
		runAsGroup:             1000
		readOnlyRootFilesystem: true
		noNewPrivileges:        true
		capabilitiesDrop: ["ALL"]
	}
	
	needs: ["traefik"]
}

// Traefik - Reverse Proxy (Layer 2)
#TraefikService: base.#ServiceDefinition & {
	name:        "traefik"
	displayName: "Traefik Reverse Proxy"
	image:       "traefik"
	tag:         "v3.1"
	type:        "reverse-proxy"
	
	// Managed by: Terraform (not Dokploy)
	managedBy: "terraform"
	layer:     "2-platform"
	
	network: {
		ports: [
			{host: 80, container: 80, protocol: "tcp", description: "HTTP"},
			{host: 443, container: 443, protocol: "tcp", description: "HTTPS"},
			{host: 8080, container: 8080, protocol: "tcp", description: "Dashboard"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`traefik.stack.local`)"
			port:    8080
		}
	}
	
	volumes: [
		{source: "traefik-data", target: "/etc/traefik", type: "volume", backup: false},
		{source: "traefik-certs", target: "/letsencrypt", type: "volume", backup: true},
	]
	
	environment: {
		"TZ": "Europe/Berlin"
	}
	
	labels: {
		"traefik.enable": "true"
		"stackkit.layer": "2-platform"
		"stackkit.managed-by": "terraform"
	}
	
	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:8080/ping"]
		interval: "10s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "128m"
		cpus:   0.2
	}
	
	securityContext: {
		runAsNonRoot:           false
		readOnlyRootFilesystem: true
		noNewPrivileges:        true
		capabilitiesDrop: ["ALL"]
		capabilitiesAdd: ["NET_BIND_SERVICE"]
	}
}

// Dokploy PostgreSQL - Database (Layer 2)
#DokployPostgresService: base.#ServiceDefinition & {
	name:        "dokploy-postgres"
	displayName: "Dokploy PostgreSQL"
	image:       "postgres"
	tag:         "16-alpine"
	type:        "database"
	
	// Managed by: Terraform (Dokploy needs it to start)
	managedBy: "terraform"
	layer:     "2-platform"
	
	network: {
		mode:     "bridge"
		networks: ["dev_net_db"]
	}
	
	volumes: [
		{source: "dokploy-postgres-data", target: "/var/lib/postgresql/data", type: "volume", backup: true},
	]
	
	environment: {
		"POSTGRES_USER": "dokploy"
		"POSTGRES_DB":   "dokploy"
		"PGDATA":        "/var/lib/postgresql/data/pgdata"
	}
	
	labels: {
		"stackkit.layer": "2-platform"
		"stackkit.managed-by": "terraform"
	}
	
	healthCheck: {
		test:     ["CMD-SHELL", "pg_isready -U dokploy -d dokploy"]
		interval: "10s"
		timeout:  "5s"
		retries:  5
	}
	
	resources: {
		memory: "256m"
		cpus:   0.2
	}
	
	securityContext: {
		runAsUser:       999
		noNewPrivileges: true
		capabilitiesDrop: ["ALL"]
	}
}

// Dokploy - PAAS Controller (Layer 2)
#DokployService: base.#ServiceDefinition & {
	name:        "dokploy"
	displayName: "Dokploy PAAS"
	image:       "dokploy/dokploy"
	tag:         "latest"
	type:        "paas"
	
	// Managed by: Terraform (it's the controller)
	managedBy: "terraform"
	layer:     "2-platform"
	
	network: {
		traefik: {
			enabled:     true
			rule:        "Host(`dokploy.stack.local`)"
			port:        3000
			middlewares: ["tinyauth@docker"]
		}
		networks: ["dev_net", "dev_net_db"]
	}
	
	volumes: [
		{source: "dokploy-data", target: "/etc/dokploy", type: "volume", backup: true},
		{source: "/var/run/docker.sock", target: "/var/run/docker.sock", type: "bind", readOnly: false},
	]
	
	environment: {
		"DOCKER_HOST":       "unix:///var/run/docker.sock"
		"NODE_ENV":          "production"
		"PORT":              "3000"
		"TRPC_PLAYGROUND":   "false"
		"LETSENCRYPT_EMAIL": "admin@stack.local"
		"TRAEFIK_ENABLED":   "true"
		"TRAEFIK_NETWORK":   "dev_net"
	}
	
	labels: {
		"traefik.enable": "true"
		"stackkit.layer": "2-platform"
		"stackkit.managed-by": "terraform"
	}
	
	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/settings"]
		interval: "30s"
		timeout:  "10s"
		retries:  5
		start_period: "60s"
	}
	
	resources: {
		memory: "512m"
		cpus:   0.5
	}
	
	securityContext: {
		runAsNonRoot:    false
		noNewPrivileges: true
		capabilitiesDrop: ["ALL"]
		capabilitiesAdd: ["CHOWN", "SETGID", "SETUID"]
	}
	
	needs: ["traefik", "dokploy-postgres", "tinyauth"]
}

// =============================================================================
// LAYER 3: APPLICATION SERVICES
// =============================================================================

// These services are deployed BY Dokploy, not by Terraform

// Uptime Kuma - Monitoring (Layer 3)
#KumaService: base.#ServiceDefinition & {
	name:        "kuma"
	displayName: "Uptime Kuma"
	image:       "louislam/uptime-kuma"
	tag:         "1"
	type:        "monitoring"
	
	// Managed by: Dokploy (Layer 2 controller)
	managedBy: "dokploy"
	layer:     "3-application"
	
	network: {
		traefik: {
			enabled:     true
			rule:        "Host(`kuma.stack.local`)"
			port:        3001
			middlewares: ["tinyauth@docker"]
		}
	}
	
	volumes: [
		{source: "kuma-data", target: "/app/data", type: "volume", backup: true},
	]
	
	environment: {
		"TZ": "Europe/Berlin"
	}
	
	labels: {
		"traefik.enable": "true"
		"stackkit.layer": "3-application"
		"stackkit.managed-by": "dokploy"
	}
	
	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:3001/"]
		interval: "30s"
		timeout:  "5s"
		retries:  3
		start_period: "30s"
	}
	
	resources: {
		memory: "256m"
		cpus:   0.2
	}
	
	securityContext: {
		noNewPrivileges: true
		capabilitiesDrop: ["ALL"]
	}
}

// Whoami - Test Service (Layer 3)
#WhoamiService: base.#ServiceDefinition & {
	name:        "whoami"
	displayName: "Whoami Test"
	image:       "traefik/whoami"
	tag:         "latest"
	type:        "application"
	
	// Managed by: Dokploy (Layer 2 controller)
	managedBy: "dokploy"
	layer:     "3-application"
	
	network: {
		traefik: {
			enabled:     true
			rule:        "Host(`whoami.stack.local`)"
			port:        80
			middlewares: ["tinyauth@docker"]
		}
	}
	
	environment: {
		"TZ": "Europe/Berlin"
	}
	
	labels: {
		"traefik.enable": "true"
		"stackkit.layer": "3-application"
		"stackkit.managed-by": "dokploy"
	}
	
	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:80/"]
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}
	
	resources: {
		memory: "64m"
		cpus:   0.1
	}
	
	securityContext: {
		runAsUser:              1000
		runAsGroup:             1000
		noNewPrivileges:        true
		capabilitiesDrop: ["ALL"]
	}
}

// =============================================================================
// SERVICE REGISTRY
// =============================================================================

#Services: {
	// Layer 2: Platform Identity
	tinyauth: #TinyAuthService
	
	// Layer 2: Platform Infrastructure
	traefik:         #TraefikService
	dokployPostgres: #DokployPostgresService
	dokploy:         #DokployService
	
	// Layer 3: Applications (managed by Dokploy)
	kuma:   #KumaService
	whoami: #WhoamiService
}

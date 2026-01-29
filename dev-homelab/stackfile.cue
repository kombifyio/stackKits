package devhomelab

// =============================================================================
// Dev Homelab Stackfile - 3-Layer Architecture
// =============================================================================
//
// Layer 1 (Foundation): Identity & Security
//   - TinyAuth: Identity proxy with passkey-first auth
//
// Layer 2 (Platform): Docker Runtime + Traefik
//   - Docker: Container runtime
//   - Traefik: Reverse proxy and ingress
//
// Layer 3 (StackKit): Applications
//   - Dokploy: PAAS for application deployment
//   - Kuma: Uptime monitoring
//   - Whoami: Test service
//
// Security: Zero-Trust Architecture with mandatory authentication
// =============================================================================

import (
	"github.com/kombihq/stackkits/base"
	"github.com/kombihq/stackkits/platforms/docker"
)

#Stack: base.#BaseStackKit & {
	// -------------------------------------------------------------------------
	// METADATA
	// -------------------------------------------------------------------------
	metadata: {
		name:        "dev-homelab"
		displayName: "Dev Homelab"
		version:     "2.0.0"
		description: "Development homelab with 3-layer architecture, Traefik routing, and Zero-Trust security"
		category:    "development"
		author:      "StackKits"
		license:     "MIT"
		tags: ["docker", "traefik", "zero-trust", "paas"]
	}

	// -------------------------------------------------------------------------
	// LAYER 1: FOUNDATION - System & Identity
	// -------------------------------------------------------------------------
	system: {
		timezone: "Europe/Berlin"
		locale:   "en_US.UTF-8"
		swap:     "auto"
		unattendedUpgrades: "security"
	}

	packages: {
		base: ["curl", "wget", "ca-certificates", "gnupg", "jq"]
		tools: ["htop", "btop", "tmux", "tree"]
	}

	users: {
		admin: {
			name:  "kombi"
			shell: "/bin/bash"
			sudo:  true
		}
	}

	container: {
		engine:      "docker"
		liveRestore: true
		logDriver:   "json-file"
	}

	// -------------------------------------------------------------------------
	// LAYER 1: FOUNDATION - Security & Identity
	// -------------------------------------------------------------------------
	security: {
		// SSH hardening
		ssh: {
			port:               22
			permitRootLogin:    "no"
			passwordAuth:       false
			pubkeyAuth:         true
			maxAuthTries:       3
			allowTcpForwarding: false
		}

		// Firewall
		firewall: {
			enabled:         true
			backend:         "ufw"
			defaultInbound:  "deny"
			defaultOutbound: "allow"
			rules: [
				{port: 22, protocol: "tcp", action: "allow", comment: "SSH"},
				{port: 80, protocol: "tcp", action: "allow", comment: "HTTP"},
				{port: 443, protocol: "tcp", action: "allow", comment: "HTTPS"},
			]
		}

		// Container security
		container: {
			runAsNonRoot:           true
			readOnlyRootFilesystem: true
			noNewPrivileges:        true
			capabilitiesDrop: ["ALL"]
		}

		// TLS policy
		tls: {
			minVersion:   "1.2"
			requireTLS:   true
			certSource:   "self-signed"
			acmeProvider: "letsencrypt-staging"
		}
	}

	// -------------------------------------------------------------------------
	// LAYER 1: FOUNDATION - Identity Services (from base)
	// -------------------------------------------------------------------------
	// These are inherited from base.#BaseStackKit identity section:
	// - identity.lldap: Lightweight LDAP server
	// - identity.stepCA: Certificate Authority
	//
	// Dev-homelab extends with TinyAuth as identity proxy
	identity: {
		// LLDAP: Lightweight directory (from base)
		lldap: {
			enabled: true
			domain: {
				base: "dc=stack,dc=local"
				organization: "Dev Homelab"
			}
			admin: {
				username: "admin"
				email:    "admin@stack.local"
			}
			traefik: {
				enabled: true
				host:    "lldap.stack.local"
			}
		}

		// Step-CA: Certificate authority (from base)
		stepCA: {
			enabled: false // Disabled for dev (enable for production)
			pki: {
				rootCommonName:         "Dev Homelab Root CA"
				intermediateCommonName: "Dev Homelab Intermediate CA"
			}
			traefik: {
				enabled: true
				host:    "ca.stack.local"
			}
		}

		// Identity provider: TinyAuth (local OIDC proxy)
		provider: {
			type:         "tinyauth"
			name:         "tinyauth"
			primary:      true
			authMethods:  ["passkey", "password"]
			oidcEndpoint: "http://auth.stack.local"
		}

		// RBAC configuration
		rbac: {
			enabled:    true
			roleSource: "local"
			roles: [
				{name: "owner", permissions: ["*"]},
				{name: "operator", permissions: ["deploy", "update", "monitor"]},
				{name: "viewer", permissions: ["read"]},
			]
		}
	}

	// -------------------------------------------------------------------------
	// LAYER 2: PLATFORM - Docker Configuration
	// -------------------------------------------------------------------------
	platform: "docker"

	// Extend Docker platform configuration
	docker: docker.#DockerConfig & {
		version:         "24.0"
		compose_version: "2.24"
		buildkit:        true
		logging: {
			driver:   "json-file"
			max_size: "50m"
			max_file: "5"
		}
	}

	// -------------------------------------------------------------------------
	// LAYER 2: PLATFORM - Traefik Configuration
	// -------------------------------------------------------------------------
	traefik: docker.#TraefikConfig & {
		enabled: true
		version: "v3.1"
		dashboard: {
			enabled:  true
			insecure: true // Local dev only
		}
		tls: {
			mode: "self-signed"
		}
		entrypoints: {
			http_port:  80
			https_port: 443
		}
		logging: {
			level:      "INFO"
			access_log: true
		}
	}

	// -------------------------------------------------------------------------
	// NETWORK CONFIGURATION
	// -------------------------------------------------------------------------
	network: {
		defaults: {
			domain: "stack.local"
			subnet: "172.21.0.0/16"
			driver: "bridge"
		}

		dns: {
			servers: ["1.1.1.1", "1.0.0.1"]
		}
	}

	// -------------------------------------------------------------------------
	// LAYER 3: STACKKIT - SERVICES
	// -------------------------------------------------------------------------
	services: [
		// Layer 1: Identity Services (from base)
		// These are deployed as infrastructure components via Terraform
		// - lldap: Lightweight LDAP (when identity.lldap.enabled = true)
		// - step-ca: Certificate Authority (when identity.stepCA.enabled = true)

		// Layer 2: Traefik (Platform)
		#Services.traefik,

		// Layer 1: TinyAuth Identity Proxy (Foundation)
		#Services.tinyauth,

		// Layer 2: Dokploy Database
		#Services.dokployPostgres,

		// Layer 2: Dokploy PAAS
		#Services.dokploy,

		// Layer 3: Kuma Monitoring (managed by Dokploy)
		#Services.kuma,

		// Layer 3: Whoami Test (managed by Dokploy)
		#Services.whoami,
	]

	// -------------------------------------------------------------------------
	// OBSERVABILITY
	// -------------------------------------------------------------------------
	observability: {
		logging: {
			driver: "json-file"
			maxSize: "50m"
			maxFiles: 5
		}

		health: {
			enabled: true
			interval: "30s"
			timeout: "10s"
			retries: 3
		}

		backup: {
			enabled:   true
			schedule:  "0 2 * * *"
			retention: 7
			volumes: [
				"dokploy-data",
				"dokploy-postgres-data",
				"kuma-data",
				"tinyauth-data",
				"traefik-certs",
			]
		}
	}

	// -------------------------------------------------------------------------
	// OUTPUTS
	// -------------------------------------------------------------------------
	outputs: {
		urls: {
			traefik: "http://traefik.stack.local"
			auth:    "http://auth.stack.local"
			dokploy: "http://dokploy.stack.local"
			kuma:    "http://kuma.stack.local"
			whoami:  "http://whoami.stack.local"
			// Identity services (from base)
			lldap:   "http://lldap.stack.local"
			stepCA:  "https://ca.stack.local:8443"
		}
		credentials: {
			tinyauth: {
				username: "admin"
				password: "admin123"
			}
			// LLDAP default credentials
			lldap: {
				username: "admin"
				note:     "Set via LLDAP_LDAP_USER_PASS environment variable"
			}
		}
	}
}

// Export the stack
stack: #Stack

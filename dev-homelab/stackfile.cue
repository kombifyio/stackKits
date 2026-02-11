package dev_homelab

// =============================================================================
// Dev Homelab Stackfile - 3-Layer Architecture
// =============================================================================
//
// Layer 1 (Foundation): System, Security & Core Identity
//   - System: Timezone, packages, users
//   - Security: SSH, Firewall, Container security
//   - Core Identity: LLDAP (directory), Step-CA (PKI)
//   - These are infrastructure-level identity services
//
// Layer 2 (Platform): Runtime, PAAS & Platform Identity
//   - Platform Runtime: Docker, networking
//   - Ingress: Traefik reverse proxy
//   - PAAS: Dokploy (platform management)
//   - Platform Identity: TinyAuth (identity proxy for apps)
//
// Layer 3 (Applications): User Applications
//   - Kuma: Uptime monitoring (deployed via PAAS)
//   - Whoami: Test service (deployed via PAAS)
//   - User applications deployed through Layer 2 PAAS
//
// Security: Zero-Trust Architecture with mandatory authentication
// =============================================================================

import (
	"github.com/kombihq/stackkits/base"
	dockerplatform "github.com/kombihq/stackkits/platforms/docker"
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
		license:     "Apache-2.0"
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
	// LAYER 1: FOUNDATION - Core Identity Services (from base)
	// -------------------------------------------------------------------------
	// These are infrastructure-level identity services:
	// - identity.lldap: Lightweight LDAP server (directory services)
	// - identity.stepCA: Certificate Authority (PKI infrastructure)
	//
	// NOTE: TinyAuth is a PLATFORM identity service (Layer 2), not a core
	// identity service. It provides application-level authentication proxying
	// using Layer 1 identity as the backend.
	identity: {
		// LLDAP: Lightweight directory (from base) - Layer 1
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

		// Step-CA: Certificate authority (from base) - Layer 1
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

		// Layer 1 identity provider configuration
		// References Layer 2 platform identity (TinyAuth)
		provider: {
			type:         "tinyauth"  // Points to Layer 2 platform identity
			name:         "tinyauth"
			primary:      true
			authMethods:  ["passkey", "password"]
			oidcEndpoint: "http://auth.stack.local"
			// NOTE: The actual TinyAuth service is defined in Layer 2
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
	// LAYER 2: PLATFORM - Platform Identity Services
	// -------------------------------------------------------------------------
	// Platform-level identity services provide authentication/authorization
	// for applications running on the platform. These are distinct from
	// Layer 1 core identity services (LLDAP, Step-CA).
	platformIdentity: {
		// TinyAuth: Platform identity proxy (Layer 2)
		tinyauth: {
			enabled:       true
			version:       "v3"
			image:         "ghcr.io/steveiliop56/tinyauth"
			installMethod: "container"
			appUrl:        "http://auth.stack.local"
			traefik: {
				enabled:        true
				middlewareName: "tinyauth"
				authResponseHeaders: ["X-User", "X-Email"]
			}
			storage: {
				dataVolume: "tinyauth-data"
				backup:     true
			}
		}

		// PocketID: OIDC provider (optional, disabled by default)
		pocketid: {
			enabled:       false
			version:       "latest"
			publicAppUrl:  "http://id.stack.local"
			database: {
				type: "sqlite"
			}
			traefik: {
				enabled: true
				host:    "id.stack.local"
			}
		}
	}

	// -------------------------------------------------------------------------
	// LAYER 2: PLATFORM - PAAS Configuration
	// -------------------------------------------------------------------------
	// PAAS (Platform as a Service) management belongs in Layer 2
	// These are infrastructure controllers, not user applications.
	paas: {
		// Dokploy: PAAS controller (Layer 2)
		type:          "dokploy"
		installMethod: "container"
		dokploy: {
			enabled: true
			version: "latest"
			image:   "dokploy/dokploy"
			port:    3000
			database: {
				external:        false
				postgresVersion: "16-alpine"
			}
			traefik: {
				enabled: true
				host:    "dokploy.stack.local"
				tls:     true
			}
			storage: {
				dataVolume: "dokploy-data"
				backup:     true
			}
		}
	}

	// -------------------------------------------------------------------------
	// LAYER 2: PLATFORM - Docker Configuration
	// -------------------------------------------------------------------------
	platform: "docker"

	// Ingress controller configuration
	ingress: {
		type: "traefik"
		traefik: {
			enabled: true
			version: "v3.1"
		}
	}

	// Extend Docker platform configuration
	docker: dockerplatform.#DockerConfig & {
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
	traefik: dockerplatform.#TraefikConfig & {
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
	// LAYER 3: APPLICATIONS - User Services
	// -------------------------------------------------------------------------
	// These services are user applications deployed via the Layer 2 PAAS.
	// Layer 2 services (Traefik, TinyAuth, Dokploy) are configured above
	// in the platform, platformIdentity, and paas sections.
	services: {
		// Layer 2: Infrastructure services (Traefik, TinyAuth, Dokploy)
		// These are deployed by Terraform as platform infrastructure
		traefik:        #Services.traefik          // Layer 2: Ingress controller
		tinyauth:       #Services.tinyauth         // Layer 2: Platform identity proxy
		dokployPostgres: #Services.dokployPostgres  // Layer 2: PAAS database
		dokploy:        #Services.dokploy           // Layer 2: PAAS controller

		// Layer 3: User applications (deployed BY Dokploy)
		// These are managed by the Layer 2 PAAS, not by Terraform directly
		kuma:           #Services.kuma              // Layer 3: Uptime monitoring
		whoami:         #Services.whoami            // Layer 3: Test service
	}

	// -------------------------------------------------------------------------
	// OBSERVABILITY
	// -------------------------------------------------------------------------
	observability: {
		logging: {
			driver: "json-file"
			maxSize: "50m"
			maxFile: 5
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
			retention: {
				daily: 7
			}
			paths: [
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

package dev_homelab

// Dev Homelab Defaults
// Production-ready defaults with security hardening

#Defaults: {
	// Infrastructure
	mode:     "simple"
	provider: "docker"

	// Domain configuration
	domain: "stack.local"

	// Network
	network: {
		name:           "dev_net"
		subnet:         "172.21.0.0/16"
		accessMode:     "traefik"      // Use Traefik for routing, not direct ports
		internalSubnet: "172.21.1.0/24" // For database network
	}

	// Security defaults - Zero Trust Architecture
	security: {
		// Enable security hardening by default
		enabled: true

		// Authentication - TinyAuth as identity proxy, LLDAP as directory (from base)
		auth: {
			provider:      "tinyauth"  // Identity proxy
			directory:     "lldap"     // Backend directory from base identity
			enabled:       true
			requireAuth:   true
			passkeyFirst:  true        // Passkey-first as per Identity Plan
		}

		// Container security hardening
		container: {
			readOnlyRootFilesystem: true
			noNewPrivileges:        true
			dropAllCapabilities:    true
			nonRootUser:            true
		}

		// mTLS configuration using Step-CA from base identity
		mtls: {
			enabled:  false  // Disabled for dev, enable for production
			provider: "step-ca" // From base identity.stepCA
			required: false
		}

		// Network segmentation
		network: {
			internalDB: true // Separate network for databases
			isolated:   true // Services isolated by default
		}

		// Admin access
		admin: {
			noAnonymousAccess: true // NO anonymous admin interfaces
			requireMFA:        false // Disabled for dev, enable for production
		}
	}

	// Service configuration
	services: {
		// Core platform services
		traefik: {
			enabled: true
			image:   "traefik:v3.1"
			ports: {
				http:      80
				https:     443
				dashboard: 8080
			}
			volumes: {
				data:  "traefik-data"
				certs: "traefik-certs"
			}
		}

		tinyauth: {
			enabled: true
			image:   "ghcr.io/steveiliop56/tinyauth:v3"
			domain:  "auth.stack.local"
			volumes: {
				data: "tinyauth-data"
			}
		}

		// Identity services from base (Layer 1 Foundation)
		lldap: {
			enabled:      true
			image:        "ghcr.io/lldap/lldap:stable"
			domain:       "lldap.stack.local"
			dataVolume:   "lldap-data"
			adminEmail:   "admin@stack.local"
			fromBase:     true // Indicates this comes from base identity module
		}

		stepCA: {
			enabled:    false // Disabled for dev
			image:      "smallstep/step-ca:latest"
			domain:     "ca.stack.local"
			dataVolume: "step-ca-data"
			fromBase:   true // Indicates this comes from base identity module
		}

		// Dokploy PAAS
		dokploy: {
			enabled:        true
			image:          "dokploy/dokploy:latest"
			domain:         "dokploy.stack.local"
			port:           3000
			volumes: {
				data: "dokploy-data"
			}
			traefikEnabled: true
		}

		dokployPostgres: {
			enabled:     true
			image:       "postgres:16-alpine"
			volumes: {
				data: "dokploy-postgres-data"
			}
			networkMode: "internal"
		}

		// Services managed BY Dokploy (not standalone)
		whoami: {
			enabled:     true
			image:       "traefik/whoami:latest"
			domain:      "whoami.stack.local"
			managedBy:   "dokploy" // KEY: Deployed through Dokploy, not standalone
			port:        9080
			healthCheck: "/"
		}

		uptimeKuma: {
			enabled:     true
			image:       "louislam/uptime-kuma:1"
			domain:      "kuma.stack.local"
			managedBy:   "dokploy" // KEY: Deployed through Dokploy, not standalone
			port:        3001
			volumes: {
				data: "kuma-data"
			}
			healthCheck: "/"
			backup:      "required"
		}
	}

	// Persistent storage configuration
	storage: {
		// All volumes must survive restarts
		persistent: true

		// Backup configuration
		backup: {
			enabled:   true
			schedule:  "0 2 * * *" // Daily at 2 AM
			retention: 7           // Keep 7 days
		}

		// Volumes that MUST be backed up
		criticalVolumes: [
			"dokploy-data",
			"dokploy-postgres-data",
			"kuma-data",
			"tinyauth-data",
			"traefik-certs",
			"lldap-data",
			"step-ca-data",
		]
	}

	// Testing configuration
	testing: {
		enabled:        true
		validateHealth: true
		timeout:        "5m"

		// E2E test expectations
		expect: {
			servicesRunning: ["traefik", "tinyauth", "dokploy-postgres", "dokploy", "lldap"]
			servicesManagedByDokploy: ["whoami", "uptime-kuma"]
			domainsReachable: [
				"dokploy.stack.local",
				"kuma.stack.local",
				"whoami.stack.local",
				"auth.stack.local",
				"lldap.stack.local",
			]
		}
	}
}

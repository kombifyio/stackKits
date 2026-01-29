package devhomelab

// Dev Homelab Stackfile
// Production-ready stack with Dokploy, Traefik, and Zero-Trust security
// Implements 3-layer architecture validation

import "github.com/kombihq/stackkits/base"

// Stack definition
#Stack: base.#StackKit & {
	// LAYER 1: FOUNDATION
	// System configuration, security, and packages
	
	metadata: {
		name:        "dev-homelab"
		version:     "2.0.0"
		description: "Production-ready homelab with Dokploy PAAS, Traefik routing, and Zero-Trust security"
		category:    "development"
		author:      "StackKits Development Team"
		license:     "MIT"
	}
	
	// LAYER 2: PLATFORM
	// Docker platform with Traefik as reverse proxy
	platform: "docker"
	
	infrastructure: {
		mode:     #Defaults.mode
		provider: #Defaults.provider
	}
	
	network: {
		defaults: {
			domain: "stack.local"
			subnet: "172.21.0.0/16"
			driver: "bridge"
		}
		
		// Internal network for databases
		internal: {
			subnet: "172.21.1.0/24"
			driver: "bridge"
		}
		
		// Traefik handles all external routing
		routing: {
			provider: "traefik"
			enabled:  true
		}
	}
	
	// LAYER 3: APPLICATIONS
	// Services with type annotations for layer validation
	
	services: {
		// -------------------------------------------------------------------------
		// PLATFORM SERVICES (Deploy first)
		// -------------------------------------------------------------------------
		
		traefik: #Services.traefik & {
			enabled: true
			labels: {
				"traefik.enable": "true"
				"traefik.http.routers.traefik.rule": "Host(`traefik.stack.local`)"
				"traefik.http.routers.traefik.service": "api@internal"
				"traefik.http.routers.traefik.entrypoints": "web"
			}
		}
		
		tinyauth: #Services.tinyauth & {
			enabled: true
			labels: {
				"traefik.enable": "true"
				"traefik.http.routers.tinyauth.rule": "Host(`auth.stack.local`)"
				"traefik.http.routers.tinyauth.entrypoints": "web"
				"traefik.http.services.tinyauth.loadbalancer.server.port": "3000"
				// ForwardAuth middleware for other services
				"traefik.http.middlewares.tinyauth.forwardauth.address": "http://tinyauth:3000/api/auth/verify"
				"traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders": "X-User,X-Email"
			}
		}
		
		// -------------------------------------------------------------------------
		// DATABASE SERVICES
		// -------------------------------------------------------------------------
		
		dokployPostgres: #Services.dokployPostgres & {
			enabled: true
			// No Traefik labels - internal network only
		}
		
		// -------------------------------------------------------------------------
		// PAAS SERVICES
		// -------------------------------------------------------------------------
		
		dokploy: #Services.dokploy & {
			enabled: true
			labels: {
				"traefik.enable": "true"
				"traefik.http.routers.dokploy.rule": "Host(`dokploy.stack.local`)"
				"traefik.http.routers.dokploy.entrypoints": "web"
				"traefik.http.routers.dokploy.service": "dokploy"
				"traefik.http.routers.dokploy.middlewares": "tinyauth@docker"
				"traefik.http.services.dokploy.loadbalancer.server.port": "3000"
			}
			// Kuma and Whoami will be deployed THROUGH Dokploy
			// after Dokploy is initialized
		}
		
		// -------------------------------------------------------------------------
		// SERVICES MANAGED BY DOKPOLOY (Configured here, deployed by Dokploy)
		// -------------------------------------------------------------------------
		
		whoami: #Services.whoami & {
			enabled: true
			// Marked as managedBy: "dokploy" in defaults
			// Dokploy will deploy this with Traefik labels
		}
		
		uptimeKuma: #Services.uptimeKuma & {
			enabled: true
			// Marked as managedBy: "dokploy" in defaults
			// Dokploy will deploy this with persistent volume and Traefik labels
		}
	}
	
	// Security layer configuration
	security: {
		// Zero-Trust Architecture
		zeroTrust: {
			enabled: true
			mtls: {
				enabled: false  // Ready for production enablement
				provider: "step-ca"
			}
			auth: {
				provider: "tinyauth"
				type: "oidc-ready"
				passkeyFirst: true
			}
		}
		
		// Container hardening
		container: {
			enabled: true
			readOnlyRootFilesystem: true
			noNewPrivileges: true
			dropAllCapabilities: true
		}
		
		// Network segmentation
		network: {
			isolatedDB: true
			noDirectAccess: true  // All services via Traefik
		}
		
		// Admin access control
		admin: {
			noAnonymousAccess: true
			requireAuthFor: [
				"dokploy",
				"traefik",
				"kuma",
				"whoami",  // Even test service requires auth
			]
		}
	}
	
	// Storage configuration
	storage: {
		persistent: true
		volumes: {
			"dokploy-data": {
				backup: "required"
			}
			"dokploy-postgres-data": {
				backup: "required"
			}
			"kuma-data": {
				backup: "required"
			}
			"tinyauth-data": {
				backup: "required"
			}
			"traefik-certs": {
				backup: "required"
			}
			"traefik-data": {
				backup: "optional"
			}
		}
	}
	
	// Testing configuration
	testing: #Defaults.testing & {
		// Additional production readiness tests
		productionReadiness: {
			// Verify all services survive restart
			persistenceTest: true
			
			// Verify Dokploy manages Kuma and Whoami
			dokployIntegration: true
			
			// Verify security - no anonymous access
			securityScan: true
			
			// Verify domains are reachable
			domainResolution: [
				"dokploy.stack.local",
				"kuma.stack.local",
				"whoami.stack.local",
				"auth.stack.local",
			]
		}
	}
}

// Export the stack
stack: #Stack
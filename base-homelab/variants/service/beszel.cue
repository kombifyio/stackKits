// Package base_homelab - Beszel variant configuration
// This variant focuses on server metrics and monitoring
package base_homelab

// #BeszelVariant defines the beszel monitoring variant
// Ideal for: Users who want detailed server metrics
#BeszelVariant: #ServiceVariant & {
	name:        "beszel"
	description: "Dokploy + Beszel - Server metrics focus"
	
	// No domain required
	requiresDomain: false

	// Core services
	services: {
		traefik: {
			enabled:     true
			description: "Reverse proxy"
			ports: [80, 443]
		}

		dozzle: {
			enabled:     true
			description: "Real-time Docker log viewer"
			port:        8888
		}

		whoami: {
			enabled:     true
			description: "HTTP echo service for testing"
			port:        9999
		}

		// Dokploy for container management
		dokploy: {
			enabled:     true
			description: "Self-hosted PaaS for Docker deployments"
			port:        3000
		}

		// Beszel for server metrics
		beszel: {
			enabled:     true
			description: "Lightweight server metrics dashboard"
			port:        8090
			config: {
				collectInterval: "10s"
				retention:       "7d"
			}
		}
	}

	// Features enabled by this variant
	features: {
		serverMetrics: true
		resourceGraph: true
		alerting:      true
	}
}

// Terraform variable mapping for beszel variant
#BeszelTFVars: {
	variant:      "beszel"
	access_mode:  "ports"
	dokploy_port: 3000
	beszel_port:  8090
	dozzle_port:  8888
}

// Package base_homelab - Default variant configuration
// This variant is for users WITHOUT their own domain
package base_homelab

// #DefaultVariant defines the default service variant
// Ideal for: Users without a domain, local network access
#DefaultVariant: #ServiceVariant & {
	name:        "default"
	description: "Dokploy + Uptime Kuma - No domain required"
	
	// No domain required
	requiresDomain: false

	// Core services (always enabled)
	services: {
		traefik: {
			enabled:     true
			description: "Reverse proxy"
			ports: [80, 443]
			config: {
				dashboard:   true
				letsencrypt: false // Not needed for local
			}
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

		// Dokploy - simpler PaaS for local use
		dokploy: {
			enabled:     true
			description: "Self-hosted PaaS for Docker deployments"
			port:        3000
			config: {
				portBasedAccess: true
			}
		}

		uptimeKuma: {
			enabled:     true
			description: "Uptime monitoring with notifications"
			port:        3001
		}
	}

	// Features enabled by this variant
	features: {
		portAccess:   true
		localNetwork: true
		simpleSetup:  true
	}
}

// Terraform variable mapping for default variant
#DefaultTFVars: {
	variant:          "default"
	access_mode:      "ports"
	enable_https:     false
	enable_letsencrypt: false
	dokploy_port:     3000
	uptime_kuma_port: 3001
	dozzle_port:      8888
}

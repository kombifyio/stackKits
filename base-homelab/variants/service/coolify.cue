// Package base_homelab - Coolify variant configuration
// This variant is for users WITH their own domain
package base_homelab

// #CoolifyVariant defines the coolify service variant
// Requires: Own domain configured for git-based deployments
#CoolifyVariant: #ServiceVariant & {
	name:        "coolify"
	description: "Coolify (PaaS) + Uptime Kuma - Requires own domain"
	
	// Domain requirement
	requiresDomain: true

	// Core services (always enabled)
	services: {
		traefik: {
			enabled:     true
			description: "Reverse proxy with Let's Encrypt"
			ports: [80, 443]
			config: {
				dashboard:  true
				letsencrypt: true
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

		// Coolify instead of Dokploy
		coolify: {
			enabled:     true
			description: "Self-hosted PaaS with Git deployments"
			port:        8000
			config: {
				gitIntegration: true
				autoDeployment: true
				webhooks:       true
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
		gitDeploy:       true
		autoSSL:         true
		webhooks:        true
		multipleApps:    true
		buildFromSource: true
	}
}

// Terraform variable mapping for coolify variant
#CoolifyTFVars: {
	variant:           "coolify"
	access_mode:       "proxy" // Always proxy mode with domain
	enable_https:      true
	enable_letsencrypt: true
	coolify_port:      8000
	uptime_kuma_port:  3001
	dozzle_port:       8888
}

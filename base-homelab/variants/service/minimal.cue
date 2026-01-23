// Package base_homelab - Minimal variant configuration
// Lightweight setup for resource-constrained systems
package base_homelab

// #MinimalVariant defines the minimal service variant
// Ideal for: Low-resource systems, minimalists, VPS with limited RAM
#MinimalVariant: #ServiceVariant & {
	name:        "minimal"
	description: "Dockge + Portainer + Netdata - Lightweight"
	
	// No domain required
	requiresDomain: false

	// Minimal resource requirements
	requirements: {
		minCpu:    2
		minMemory: 2
		minDisk:   20
	}

	// Core services - lightweight alternatives
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

		// Dockge - lightweight docker-compose manager
		dockge: {
			enabled:     true
			description: "Docker Compose stack manager"
			port:        5001
			config: {
				stacksDir: "/opt/stacks"
			}
		}

		// Portainer - container management UI
		portainer: {
			enabled:     true
			description: "Container management interface"
			port:        9000
			config: {
				edition: "ce" // Community Edition
			}
		}

		// Netdata - lightweight monitoring
		netdata: {
			enabled:     true
			description: "Real-time performance monitoring"
			port:        19999
			config: {
				claimCloud: false
				streaming:  false
			}
		}
	}

	// Features enabled by this variant
	features: {
		lightweight:       true
		lowResourceUsage:  true
		simpleManagement:  true
	}
}

// Terraform variable mapping for minimal variant
#MinimalTFVars: {
	variant:       "minimal"
	access_mode:   "ports"
	dockge_port:   5001
	portainer_port: 9000
	netdata_port:  19999
	dozzle_port:   8888
}

// Resource limits for minimal variant
#MinimalResourceLimits: {
	dockge: {
		memory: "128m"
		cpu:    0.25
	}
	portainer: {
		memory: "256m"
		cpu:    0.5
	}
	netdata: {
		memory: "256m"
		cpu:    0.5
	}
	traefik: {
		memory: "128m"
		cpu:    0.25
	}
	dozzle: {
		memory: "64m"
		cpu:    0.1
	}
}

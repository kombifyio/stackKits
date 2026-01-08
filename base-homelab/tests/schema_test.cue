// Base Homelab CUE Tests v2.0
// Validiert die Schema-Definitionen und Constraints
// 
// Tests für:
// - Default Variante (Dokploy + Uptime Kuma)
// - Beszel Variante (Dokploy + Beszel)
// - Minimal Variante (Dockge + Portainer + Netdata)
// - Deployment Modi (simple/advanced)
package tests

import (
	"kombistack.dev/stackkits/base"
	"kombistack.dev/stackkits/base-homelab"
)

// =============================================================================
// DEFAULT VARIANT TESTS (Dokploy + Uptime Kuma)
// =============================================================================

// Test: Default Variante - minimal gültige Konfiguration
_validDefaultVariant: homelab.#BaseHomelabStack & {
	meta: {
		name:    "test-homelab"
		version: "2.0.0"
	}
	variant: "default"
	nodes: [{
		id:   "node-1"
		name: "test-node"
		host: "192.168.1.100"
		compute: {
			cpuCores:  4
			ramGB:     8
			storageGB: 100
		}
	}]
	network: {
		domain:    "test.local"
		acmeEmail: "admin@test.local"
	}
	// Default Variante Services
	services: {
		traefik:     enabled: true
		dokploy:     enabled: true
		uptimeKuma:  enabled: true
		dozzle:      enabled: true
		whoami:      enabled: true
	}
}

// =============================================================================
// BESZEL VARIANT TESTS (Dokploy + Beszel)
// =============================================================================

// Test: Beszel Variante
_validBeszelVariant: homelab.#BaseHomelabStack & {
	meta: {
		name:    "beszel-homelab"
		version: "2.0.0"
	}
	variant: "beszel"
	nodes: [{
		id:   "node-1"
		name: "beszel-node"
		host: "192.168.1.101"
		compute: {
			cpuCores:  4
			ramGB:     8
			storageGB: 100
		}
	}]
	network: {
		domain:    "beszel.local"
		acmeEmail: "admin@beszel.local"
	}
	// Beszel Variante Services
	services: {
		traefik:    enabled: true
		dokploy:    enabled: true
		beszel:     enabled: true
		dozzle:     enabled: true
		whoami:     enabled: true
		uptimeKuma: enabled: false  // Nicht in Beszel Variante
	}
}

// =============================================================================
// MINIMAL VARIANT TESTS (Dockge + Portainer + Netdata)
// =============================================================================

// Test: Minimal Variante - klassischer Stack
_validMinimalVariant: homelab.#BaseHomelabStack & {
	meta: {
		name:    "minimal-homelab"
		version: "2.0.0"
	}
	variant: "minimal"
	nodes: [{
		id:   "node-1"
		name: "minimal-node"
		host: "192.168.1.102"
		compute: {
			cpuCores:  2
			ramGB:     4
			storageGB: 64
		}
	}]
	network: {
		domain:    "minimal.local"
		acmeEmail: "admin@minimal.local"
	}
	// Minimal Variante Services (klassischer Stack)
	services: {
		traefik:   enabled: true
		dockge:    enabled: true
		portainer: enabled: true
		netdata:   enabled: true
		dozzle:    enabled: true
		// Diese sind in Minimal nicht aktiv
		dokploy:    enabled: false
		uptimeKuma: enabled: false
		beszel:     enabled: false
	}
}

// =============================================================================
// COMPUTE TIER TESTS
// =============================================================================

// Test: High Compute Konfiguration
_validHighComputeConfig: homelab.#BaseHomelabStack & {
	meta: {
		name:    "high-compute-lab"
		version: "2.0.0"
	}
	variant: "default"
	computeTier: "high"
	nodes: [{
		id:   "powerful-server"
		name: "bigbox"
		host: "10.0.0.10"
		compute: {
			cpuCores:  16
			ramGB:     64
			storageGB: 2000
		}
	}]
	network: {
		domain:    "homelab.example.com"
		acmeEmail: "admin@example.com"
	}
}

// Test: Low Compute mit automatischer Varianten-Umschaltung
_validLowComputeConfig: homelab.#BaseHomelabStack & {
	meta: {
		name:    "low-compute-lab"
		version: "2.0.0"
	}
	variant: "minimal"  // Low compute empfiehlt minimal
	computeTier: "low"
	nodes: [{
		id:   "mini-pc"
		name: "minibox"
		host: "192.168.1.50"
		compute: {
			cpuCores:  2
			ramGB:     4
			storageGB: 64
		}
	}]
	network: {
		domain:    "mini.local"
		acmeEmail: "admin@mini.local"
	}
}

// =============================================================================
// DEPLOYMENT MODE TESTS
// =============================================================================

// Test: Simple Mode (OpenTofu-only)
_validSimpleModeConfig: homelab.#BaseHomelabStack & {
	meta: {
		name:    "simple-mode-lab"
		version: "2.0.0"
	}
	deploymentMode: "simple"
	variant: "default"
	nodes: [{
		id:   "simple-node"
		name: "simpleserver"
		host: "192.168.1.110"
		compute: {
			cpuCores:  4
			ramGB:     8
			storageGB: 100
		}
	}]
	network: {
		domain:    "simple.local"
		acmeEmail: "admin@simple.local"
	}
}

// Test: Advanced Mode (Terramate)
_validAdvancedModeConfig: homelab.#BaseHomelabStack & {
	meta: {
		name:    "advanced-mode-lab"
		version: "2.0.0"
	}
	deploymentMode: "advanced"
	driftDetection: enabled: true
	variant: "default"
	nodes: [{
		id:   "advanced-node"
		name: "advancedserver"
		host: "192.168.1.111"
		compute: {
			cpuCores:  8
			ramGB:     16
			storageGB: 200
		}
	}]
	network: {
		domain:    "advanced.local"
		acmeEmail: "admin@advanced.local"
	}
}

// =============================================================================
// SERVICE OUTPUT TESTS
// =============================================================================

// Test: Service-Konfiguration mit Output URLs validieren
_validServiceConfig: base.#ServiceDefinition & {
	name:        "test-service"
	displayName: "Test Service"
	category:    "test"
	type:        "application"
	enabled:     true
	image:       "nginx:latest"
	tag:         "latest"
	
	network: {
		ports: [{
			host:     8080
			container: 80
			protocol: "tcp"
		}]
		traefik: {
			enabled: true
			rule:    "Host(`test.example.com`)"
			tls:     true
			port:    80
		}
	}
	
	healthCheck: {
		enabled: true
		http: {
			path:   "/"
			port:   80
			scheme: "http"
		}
		interval: "30s"
		timeout:  "10s"
		retries:  3
	}
	
	output: {
		url:         "https://test.example.com"
		description: "Test Service"
		credentials: {
			note: "No auth required"
		}
	}
}

// Test: Node-Definition validieren
_validNodeConfig: base.#NodeDefinition & {
	id:   "test-node-001"
	name: "testserver"
	host: "192.168.1.100"
	compute: {
		cpuCores:  8
		ramGB:     32
		storageGB: 500
	}
	os: {
		family:  "debian"
		distro:  "ubuntu"
		version: "24.04"
	}
	role: "worker"
}

// =============================================================================
// NEGATIVE TESTS (commented - CUE fails on constraint violation)
// =============================================================================

// _invalidVariant: homelab.#BaseHomelabStack & {
//     variant: "unknown"  // FEHLER: muss default, beszel, oder minimal sein
// }

// _invalidNodeNoCPU: base.#NodeDefinition & {
//     id:   "invalid"
//     name: "invalid"
//     host: "192.168.1.1"
//     compute: {
//         cpuCores: 0  // FEHLER: muss >= 1 sein
//         ramGB: 8
//         storageGB: 100
//     }
// }

// _invalidServiceNoImage: base.#ServiceDefinition & {
//     name: "invalid-service"
//     enabled: true
//     // FEHLER: image ist required
// }


// =============================================================================
// VALIDATION TESTS: 3-LAYER ARCHITECTURE
// =============================================================================
// Comprehensive validation tests for the CUE schemas across all layers
//
// Run with: cue vet ./tests/validation_test.cue
// =============================================================================

package tests

import (
	"github.com/kombihq/stackkits/base"
	"github.com/kombihq/stackkits/platforms/docker"
	base_homelab "github.com/kombihq/stackkits/base-homelab"
)

// =============================================================================
// LAYER 1 (CORE) TESTS
// =============================================================================

// Test: Base packages are defined
_test_base_packages: base.#BasePackages & {
	core: ["curl", "wget", "git"]
	extra: ["htop", "vim"]
}

// Test: SSH hardening configuration
_test_ssh_hardening: base.#SSHHardening & {
	port:            22
	permitRootLogin: "no"
	passwordAuth:    false
	pubkeyAuth:      true
	maxAuthTries:    3
}

// Test: SSH with invalid permitRootLogin should fail
// Uncomment to verify validation catches errors:
// _test_ssh_invalid: base.#SSHHardening & {
//     permitRootLogin: "invalid"  // Should fail - not in allowed values
// }

// Test: Firewall policy
_test_firewall: base.#FirewallPolicy & {
	enabled:         true
	backend:         "ufw"
	defaultInbound:  "deny"
	defaultOutbound: "allow"
	rules: [
		{port: 22, protocol: "tcp", comment: "SSH"},
		{port: 80, protocol: "tcp", comment: "HTTP"},
		{port: 443, protocol: "tcp", comment: "HTTPS"},
	]
}

// Test: Node definition
_test_node: base.#NodeDefinition & {
	name: "test-node"
	role: "main"
	type: "local"
	resources: {
		cpu:    4
		memory: 8
		disk:   100
	}
}

// Test: Resource constraints (should enforce minimums)
_test_resources_min: base.#NodeResources & {
	cpu:    2  // Minimum
	memory: 4  // Minimum
	disk:   50 // Minimum
}

// =============================================================================
// LAYER 2 (PLATFORM) TESTS - DOCKER
// =============================================================================

// Test: Docker configuration
_test_docker_config: docker.#DockerConfig & {
	version:         "24.0"
	compose_version: "2.24"
	logging: {
		driver:   "json-file"
		max_size: "10m"
		max_file: "3"
	}
	storage_driver: "overlay2"
	buildkit:       true
	auto_prune: {
		enabled:    true
		schedule:   "0 4 * * 0"
		images:     true
		containers: true
		volumes:    false
		networks:   true
	}
}

// Test: Traefik configuration
_test_traefik_config: docker.#TraefikConfig & {
	enabled: true
	version: "v3.1"
	dashboard: {
		enabled:  true
		insecure: false
	}
	tls: {
		mode: "auto"
	}
	entrypoints: {
		http_port:  80
		https_port: 443
		extra: []
	}
	logging: {
		level:      "INFO"
		access_log: true
	}
}

// Test: Docker network definition
_test_docker_network: docker.#DockerNetwork & {
	name:     "kombistack"
	driver:   "bridge"
	ipv6:     false
	internal: false
}

// Test: Docker service definition
_test_docker_service: docker.#DockerService & {
	name:    "test-service"
	image:   "nginx"
	tag:     "latest"
	restart: "unless-stopped"
	networks: ["kombistack"]
	ports: [{host: 8080, container: 80}]
	volumes: []
	environment: {
		ENV: "test"
	}
	traefik: {
		enabled:      true
		rule:         "Host(`test.localhost`)"
		entrypoints:  ["websecure"]
		tls:          true
		middlewares: []
	}
	depends_on: []
}

// =============================================================================
// LAYER 3 (STACKKIT) TESTS - BASE-HOMELAB
// =============================================================================

// Test: Complete base-homelab configuration with default variant
_test_base_homelab_default: base_homelab.#BaseHomelabKit & {
	variant: "default"
	
	system: {
		timezone: "Europe/Berlin"
	}
	
	nodes: [{
		name: "homelab"
		role: "main"
		type: "local"
		os:   "ubuntu-24"
		resources: {
			cpu:    4
			memory: 8
			disk:   100
		}
		connection: {
			host:    "192.168.1.100"
			user:    "root"
			ssh_key: "/path/to/key"
		}
	}]
}

// Test: Base-homelab with beszel variant
_test_base_homelab_beszel: base_homelab.#BaseHomelabKit & {
	variant: "beszel"
	
	nodes: [{
		name: "homelab"
		role: "main"
		type: "local"
		os:   "debian-12"
		resources: {
			cpu:    2
			memory: 4
			disk:   50
		}
		connection: {
			host:    "192.168.1.100"
			user:    "root"
			ssh_key: "/path/to/key"
		}
	}]
}

// Test: Base-homelab with minimal variant
_test_base_homelab_minimal: base_homelab.#BaseHomelabKit & {
	variant: "minimal"
	
	nodes: [{
		name: "mini-homelab"
		role: "main"
		type: "local"
		os:   "ubuntu-22"
		resources: {
			cpu:    2
			memory: 4
			disk:   50
		}
		connection: {
			host:    "192.168.1.100"
			user:    "root"
			ssh_key: "/path/to/key"
		}
	}]
}

// =============================================================================
// NEGATIVE TESTS (Uncomment to verify validation catches errors)
// =============================================================================

// Test: Invalid OS should fail
// _test_invalid_os: base_homelab.#BaseHomelabKit & {
//     nodes: [{
//         os: "windows-11"  // Not in allowed values
//     }]
// }

// Test: Resources below minimum should fail
// _test_invalid_resources: base_homelab.#BaseHomelabKit & {
//     nodes: [{
//         resources: {
//             cpu: 1     // Below minimum of 2
//             memory: 2  // Below minimum of 4
//         }
//     }]
// }

// Test: Invalid variant should fail
// _test_invalid_variant: base_homelab.#BaseHomelabKit & {
//     variant: "enterprise"  // Not a valid variant
// }

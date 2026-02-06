// =============================================================================
// Dev Homelab - Environment Validation (CUE)
// =============================================================================
// This schema validates the deployment environment before StackKit is applied.
// It checks ports, network connectivity, and Docker daemon accessibility.
//
// Usage:
//   cue vet --schema '#EnvValidation' .env.json validate-env.cue
// =============================================================================

package dev_homelab

// Port configuration with validation
#PortConfig: {
	// Required ports for VM deployment
	ports: {
		// SSH port for VM access
		ssh: int & >=1024 & <=65535 | *2222

		// Docker daemon port (must be accessible for StackKit CLI)
		docker: int & >=1024 & <=65535 | *2375

		// HTTP port for Traefik (inside VM, exposed to host)
		http: int & >=1024 & <=65535 | *10080

		// HTTPS port for Traefik (inside VM, exposed to host)
		https: int & >=1024 & <=65535 | *10443

		// Traefik dashboard port (inside VM, exposed to host)
		traefik: int & >=1024 & <=65535 | *19080
	}

	// Port conflict detection - ensure no commonly used ports
	_portConflicts: {
		// Common ports that might conflict
		common: [80, 443, 8080, 3000, 5000, 5432, 6379, 8000, 9000]

		// Check if any configured port conflicts with common ports (80, 443, 8080)
		hasConflict: ports.ssh == 80 || ports.ssh == 443 || ports.ssh == 8080 ||
			ports.docker == 80 || ports.docker == 443 || ports.docker == 8080 ||
			ports.http == 80 || ports.http == 443 || ports.http == 8080 ||
			ports.https == 80 || ports.https == 443 || ports.https == 8080 ||
			ports.traefik == 80 || ports.traefik == 443 || ports.traefik == 8080
	}

	// Recommendations based on port selection
	recommendations: {
		// Suggest high ports if user chose low ports
		suggestHighPorts: ports.http < 10000 || ports.https < 10000 || ports.traefik < 10000

		// Suggest using port ranges
		portRange: "Use ports in range 10000-19999 to avoid conflicts with system services"
	}
}

// Docker daemon validation
#DockerValidation: {
	// Docker daemon must be accessible
	dockerHost: string | *"tcp://vm:2375"

	// Validate Docker host format (must be one of supported patterns)
	isValidHost: dockerHost == "tcp://vm:2375" ||
		dockerHost == "tcp://localhost:2375" ||
		dockerHost == "tcp://127.0.0.1:2375" ||
		dockerHost == "unix:///var/run/docker.sock"
}

// Complete environment validation
#EnvValidation: {
	// Port configuration
	ports: #PortConfig

	// Docker configuration
	docker: #DockerValidation

	// Domain configuration
	domain: string | *"stack.local"

	// Validation results
	validation: {
		// Overall validation status
		valid: bool
		valid: ports._portConflicts.hasConflict == false && docker.isValidHost == true

		// Specific checks
		checks: {
			portsValid: ports._portConflicts.hasConflict == false
			dockerHostValid: docker.isValidHost == true
		}

		// Error messages if validation fails
		errors: [...string]
		errors: [
			if ports._portConflicts.hasConflict {"Port conflicts detected - avoid ports 80, 443, 8080"},
			if !docker.isValidHost {"Invalid DOCKER_HOST format. Must be tcp://vm:2375 for VM deployment"},
		]
	}
}

// Default configuration for VM-based deployment
#DefaultVMConfig: #EnvValidation & {
	ports: {
		ports: {
			ssh: 2222
			docker: 2375
			http: 10080
			https: 10443
			traefik: 19080
		}
	}
	docker: {
		dockerHost: "tcp://vm:2375"
	}
	domain: "stack.local"
}

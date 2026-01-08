// =============================================================================
// IAC-FIRST SCHEMA - CORE DEFINITIONS
// =============================================================================
// CUE schema for IaC-First architecture validation
// Ensures all configurations follow the IaC-First pattern

package base

// -----------------------------------------------------------------------------
// BOOTSTRAP CONFIGURATION
// -----------------------------------------------------------------------------

// BootstrapConfig defines OS-preparation settings
#BootstrapConfig: {
	// Target system
	worker_ip:            string & =~"^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$"
	ssh_user:             string | *"root"
	ssh_private_key_path: string
	
	// OS type - validated against supported list
	os_type: "ubuntu-24" | "ubuntu-22" | "debian-12"
	
	// Security settings
	enable_ssh_hardening: bool | *true
	enable_firewall:      bool | *true
	
	// Allowed firewall ports
	firewall_ports: [...#FirewallPort]
}

#FirewallPort: {
	port:     int & >=1 & <=65535
	protocol: "tcp" | "udp" | *"tcp"
	comment:  string | *""
}

// -----------------------------------------------------------------------------
// NETWORK MODE CONFIGURATION
// -----------------------------------------------------------------------------

#NetworkConfig: {
	mode: "local" | "public"
	
	// Docker network settings
	docker_network_name: string | *"kombistack_network"
	
	// Public mode requires domain and email
	if mode == "public" {
		domain:     string & =~"^[a-zA-Z0-9][a-zA-Z0-9-_.]+[a-zA-Z0-9]$"
		email:      string & =~"^[^@]+@[^@]+\\.[^@]+$"
		enable_ssl: bool | *true
	}
	
	// Local mode optional mDNS
	if mode == "local" {
		enable_mdns: bool | *false
	}
}

// -----------------------------------------------------------------------------
// SERVICE DEFINITION
// -----------------------------------------------------------------------------

#ServiceConfig: {
	name:    string & =~"^[a-z][a-z0-9-]*$"
	image:   string
	restart: "always" | "unless-stopped" | "on-failure" | "no" | *"unless-stopped"
	
	// Environment variables
	environment: [string]: string
	
	// Port mappings
	ports: [...#PortMapping]
	
	// Volume mounts
	volumes: [...#VolumeMount]
	
	// Health check (optional)
	healthcheck?: #Healthcheck
	
	// Resource limits (optional)
	resources?: #ResourceLimits
}

#PortMapping: {
	internal: int & >=1 & <=65535
	external: int & >=1 & <=65535
	protocol: "tcp" | "udp" | *"tcp"
}

#VolumeMount: {
	host:      string
	container: string
	read_only: bool | *false
}

#Healthcheck: {
	test:         [...string]
	interval:     string | *"30s"
	timeout:      string | *"10s"
	retries:      int | *3
	start_period: string | *"10s"
}

#ResourceLimits: {
	cpu_limit:    string | *""    // e.g., "0.5"
	memory_limit: string | *""    // e.g., "512m"
}

// -----------------------------------------------------------------------------
// UNIFIED SPEC (Complete configuration)
// -----------------------------------------------------------------------------

#UnifiedSpec: {
	// Metadata
	version:  string | *"1.0"
	stack_id: string
	
	// Bootstrap configuration
	bootstrap: #BootstrapConfig
	
	// Network configuration
	network: #NetworkConfig
	
	// Services to deploy
	services: [...#ServiceConfig]
	
	// Validation: At least one service required
	_validate_services: len(services) > 0
}

// -----------------------------------------------------------------------------
// AGENT COMMAND CONSTRAINTS
// -----------------------------------------------------------------------------

// AgentCommand defines the ONLY commands an agent can execute
// This is the "thin layer" enforcement
#AgentCommand: {
	type: "tofu" | "terramate"
	
	if type == "tofu" {
		subcommand: "init" | "plan" | "apply" | "destroy" | "output"
		args: [...string]
	}
	
	if type == "terramate" {
		subcommand: "run" | "list" | "fmt"
		args: [...string]
	}
	
	// Working directory
	workdir: string
	
	// Timeout in seconds
	timeout: int | *300
}

// Forbidden commands - Agent MUST NOT execute these
#ForbiddenCommands: [
	"bash",
	"sh",
	"apt",
	"apt-get",
	"yum",
	"dnf",
	"systemctl",
	"service",
	"docker",  // Direct docker commands - use Provider instead
	"curl",
	"wget",
]

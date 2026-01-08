// Package base - Security configuration schemas
package base

// #SSHHardening defines SSH security settings
#SSHHardening: {
	// SSH port
	port: uint16 & >0 & <=65535 | *22

	// Permit root login
	permitRootLogin: "yes" | "no" | "prohibit-password" | "forced-commands-only" | *"no"

	// Password authentication
	passwordAuth: bool | *false

	// Public key authentication
	pubkeyAuth: bool | *true

	// Max authentication attempts
	maxAuthTries: int & >=1 & <=10 | *3

	// Login grace time in seconds
	loginGraceTime: int & >=10 & <=300 | *60

	// Allow TCP forwarding
	allowTcpForwarding: bool | *false

	// Allow agent forwarding
	allowAgentForwarding: bool | *false

	// X11 forwarding
	x11Forwarding: bool | *false

	// Allowed users (empty = all)
	allowUsers: [...string] | *[]

	// Allowed groups
	allowGroups: [...string] | *[]

	// Client alive interval
	clientAliveInterval: int | *300

	// Client alive count max
	clientAliveCountMax: int | *3

	// Banner message
	banner?: string

	// Additional sshd_config options
	extraConfig?: [string]: string
}

// #FirewallPolicy defines firewall rules
#FirewallPolicy: {
	// Enable firewall
	enabled: bool | *true

	// Firewall backend
	backend: "ufw" | "firewalld" | "iptables" | "nftables" | *"ufw"

	// Default inbound policy
	defaultInbound: "allow" | "deny" | *"deny"

	// Default outbound policy
	defaultOutbound: "allow" | "deny" | *"allow"

	// Default forward policy
	defaultForward: "allow" | "deny" | *"deny"

	// Firewall rules
	rules: [...#FirewallRule] | *[]

	// Rate limiting
	rateLimit?: {
		enabled:    bool | *true
		maxRetries: int | *6
		findTime:   int | *600
		banTime:    int | *600
	}
}

// #FirewallRule defines a single firewall rule
#FirewallRule: {
	// Port number
	port: uint16 & >0 & <=65535

	// Protocol
	protocol: "tcp" | "udp" | "both" | *"tcp"

	// Source (IP, CIDR, or "any")
	source: string | *"any"

	// Destination (IP, CIDR, or "any")
	destination: string | *"any"

	// Action
	action: "allow" | "deny" | "reject" | *"allow"

	// Direction
	direction: "in" | "out" | "both" | *"in"

	// Comment/description
	comment?: string

	// Rule enabled
	enabled: bool | *true
}

// #ContainerSecurityContext defines container security settings
#ContainerSecurityContext: {
	// Run as non-root
	runAsNonRoot: bool | *true

	// User ID
	runAsUser?: int

	// Group ID
	runAsGroup?: int

	// Read-only root filesystem
	readOnlyRootFilesystem: bool | *false

	// Privileged mode
	privileged: bool | *false

	// Capabilities to add
	capabilitiesAdd: [...string] | *[]

	// Capabilities to drop
	capabilitiesDrop: [...string] | *["ALL"]

	// Seccomp profile
	seccompProfile: "RuntimeDefault" | "Unconfined" | "Localhost" | *"RuntimeDefault"

	// AppArmor profile
	appArmorProfile?: string

	// No new privileges
	noNewPrivileges: bool | *true
}

// #SecretsPolicy defines how secrets are managed
#SecretsPolicy: {
	// Secrets backend
	backend: "file" | "env" | "vault" | "sops" | *"file"

	// Secrets directory
	secretsDir: string | *"/run/secrets"

	// File permissions for secrets
	fileMode: string | *"0400"

	// Vault configuration (if backend = vault)
	vault?: {
		address: string
		role:    string
		path:    string | *"secret"
	}

	// SOPS configuration (if backend = sops)
	sops?: {
		keyType: "age" | "pgp" | "kms"
		keyId:   string
	}
}

// #TLSPolicy defines TLS/SSL settings
#TLSPolicy: {
	// Minimum TLS version
	minVersion: "1.2" | "1.3" | *"1.2"

	// Require TLS for all services
	requireTLS: bool | *true

	// Certificate source
	certSource: "acme" | "self-signed" | "manual" | *"acme"

	// ACME provider
	acmeProvider: "letsencrypt" | "letsencrypt-staging" | "zerossl" | "buypass" | *"letsencrypt"

	// ACME email
	acmeEmail?: string

	// ACME challenge type
	acmeChallenge: "http" | "dns" | "tls-alpn" | *"http"

	// DNS provider for ACME DNS challenge
	acmeDnsProvider?: string

	// Certificate renewal threshold (days)
	renewalThreshold: int & >=7 & <=60 | *30

	// HSTS enabled
	hsts: bool | *true

	// HSTS max age (seconds)
	hstsMaxAge: int | *31536000

	// HSTS include subdomains
	hstsIncludeSubdomains: bool | *true

	// HSTS preload
	hstsPreload: bool | *false
}

// #AuditConfig defines audit logging settings
#AuditConfig: {
	// Enable audit logging
	enabled: bool | *false

	// Audit log path
	logPath: string | *"/var/log/audit/audit.log"

	// Max log file size (MB)
	maxLogSize: int | *50

	// Number of log files to keep
	numLogs: int | *5

	// Events to audit
	events: [...string] | *["auth", "sudo", "file-access"]

	// Syscalls to audit
	syscalls: [...string] | *[]
}

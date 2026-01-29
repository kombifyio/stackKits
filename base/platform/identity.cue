// Package base - Platform Identity schemas for Layer 2 Platform
// This file defines identity services that belong in Layer 2 (Platform)
// These are platform-level identity proxies and authentication services
// NOT Layer 1 foundational identity (LLDAP, Step-CA)
package base

// =============================================================================
// PLATFORM IDENTITY SERVICES
// =============================================================================

// #PlatformIdentityConfig is the main identity configuration block for Layer 2
#PlatformIdentityConfig: {
	// TinyAuth - Lightweight identity proxy
	tinyauth?: #TinyAuthConfig

	// PocketID - OIDC provider
	pocketid?: #PocketIDConfig

	// Authelia - Full-featured authentication server
	authelia?: #AutheliaConfig

	// Authentik - Advanced identity provider
	authentik?: #AuthentikConfig
}

// =============================================================================
// TINYAUTH CONFIGURATION
// =============================================================================

// #TinyAuthConfig defines TinyAuth identity proxy settings
#TinyAuthConfig: {
	// Enable TinyAuth
	enabled: bool | *true

	// TinyAuth version
	version: string | *"v3"

	// Docker image
	image: string | *"ghcr.io/steveiliop56/tinyauth"

	// Web UI port
	port: uint16 & >0 & <=65535 | *3000

	// Installation method
	installMethod: #InstallMethod | *"container"

	// App URL
	appUrl?: string

	// Log level
	logLevel: "debug" | "info" | "warn" | "error" | *"info"

	// Session secret (secret reference)
	sessionSecret: string | *"secret://tinyauth/session-secret"

	// User configuration
	users: {
		// Static users file
		usersFile?: string

		// Or inline user definitions
		definitions?: [...{
			// Username
			username: string

			// Password hash (bcrypt)
			passwordHash: string

			// User email
			email?: string
		}]
	}

	// OAuth providers (optional)
	oauth?: {
		// GitHub OAuth
		github?: {
			enabled: bool | *false
			clientId: string
			clientSecret: string
		}

		// Google OAuth
		google?: {
			enabled: bool | *false
			clientId: string
			clientSecret: string
		}

		// Generic OIDC
		oidc?: {
			enabled: bool | *false
			issuer: string
			clientId: string
			clientSecret: string
			scopes: [...string] | *["openid", "profile", "email"]
		}
	}

	// Traefik integration
	traefik: {
		// Enable Traefik ForwardAuth
		enabled: bool | *true

		// Middleware name
		middlewareName: string | *"tinyauth"

		// Auth URL
		authUrl?: string

		// Auth response headers to forward
		authResponseHeaders: [...string] | *["X-User", "X-Email"]
	}

	// Storage configuration
	storage: {
		// Data volume name
		dataVolume: string | *"tinyauth-data"

		// Backup enabled
		backup: bool | *true
	}

	// Resource limits
	resources?: #ResourceLimits
}

// #TinyAuthService generates a complete service definition for TinyAuth
#TinyAuthService: #ServiceDefinition & {
	name:        "tinyauth"
	displayName: "TinyAuth Identity Proxy"
	image:       "ghcr.io/steveiliop56/tinyauth"
	tag:         string | *"v3"
	type:        "auth"
	required:    false

	// TinyAuth is Layer 2 - platform identity
	labels: {
		"traefik.enable": "true"
		"stackkit.layer": "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "identity"
		"traefik.http.middlewares.tinyauth.forwardauth.address":               "http://tinyauth:3000/api/auth/verify"
		"traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders":   "X-User,X-Email"
	}

	network: {
		traefik: {
			enabled: true
			rule:    "Host(`auth.{{.domain}}`)"
			port:    3000
		}
	}

	volumes: [
		{
			source:      "tinyauth-data"
			target:      "/data"
			type:        "volume"
			backup:      true
			description: "TinyAuth data and users"
		},
	]

	environment: {
		"TZ":        "Europe/Berlin"
		"LOG_LEVEL": "info"
	}

	environmentSecrets: {
		"SECRET": "secret://tinyauth/session-secret"
	}

	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/health"]
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}

	resources: {
		memory: "128m"
		cpus:   0.1
	}

	securityContext: {
		runAsUser:              1000
		runAsGroup:             1000
		readOnlyRootFilesystem: true
		noNewPrivileges:        true
		capabilitiesDrop: ["ALL"]
	}

	needs: ["traefik"]

	config: {
		type:          "auth"
		installMethod: "container"
		layer:         "2-platform"
	}
}

// =============================================================================
// POCKETID CONFIGURATION
// =============================================================================

// #PocketIDConfig defines PocketID OIDC provider settings
#PocketIDConfig: {
	// Enable PocketID
	enabled: bool | *false

	// PocketID version
	version: string | *"latest"

	// Docker image
	image: string | *"stonith404/pocket-id"

	// Web UI port
	port: uint16 & >0 & <=65535 | *3000

	// Installation method
	installMethod: #InstallMethod | *"container"

	// Public app URL
	publicAppUrl: string

	// Database configuration
	database: {
		// Database type
		type: "sqlite" | "postgres" | *"sqlite"

		// SQLite configuration
		sqlite?: {
			// Data path
			path: string | *"/app/data/pocket-id.db"
		}

		// PostgreSQL configuration
		postgres?: {
			// Connection string
			connectionString: string
		}
	}

	// SMTP configuration for notifications
	smtp?: {
		// Enable SMTP
		enabled: bool | *false

		// SMTP host
		host: string

		// SMTP port
		port: uint16 | *587

		// SMTP user
		user: string

		// SMTP password (secret reference)
		password: string

		// From address
		from: string

		// TLS mode
		tls: "starttls" | "tls" | "none" | *"starttls"
	}

	// OIDC configuration
	oidc: {
		// Issuer URL
		issuerUrl?: string

		// Default scopes
		defaultScopes: [...string] | *["openid", "profile", "email"]

		// Access token lifetime (minutes)
		accessTokenLifetime: int | *60

		// Refresh token lifetime (days)
		refreshTokenLifetime: int | *30
	}

	// LDAP configuration (for user import/sync)
	ldap?: {
		// Enable LDAP sync
		enabled: bool | *false

		// LDAP server URL
		url: string

		// Bind DN
		bindDn: string

		// Bind password (secret reference)
		bindPassword: string

		// Base DN for user search
		baseDn: string

		// User filter
		userFilter: string | *"(objectClass=person)"

		// Sync interval (minutes)
		syncInterval: int | *60
	}

	// Traefik integration
	traefik: {
		// Enable Traefik routing
		enabled: bool | *true

		// Host rule for web UI
		host?: string

		// Use TLS
		tls: bool | *true
	}

	// Storage configuration
	storage: {
		// Data volume name
		dataVolume: string | *"pocketid-data"

		// Backup enabled
		backup: bool | *true
	}

	// Resource limits
	resources?: #ResourceLimits
}

// #PocketIDService generates a complete service definition for PocketID
#PocketIDService: #ServiceDefinition & {
	name:        "pocketid"
	displayName: "PocketID OIDC Provider"
	image:       "stonith404/pocket-id"
	tag:         string | *"latest"
	type:        "auth"
	required:    false

	// PocketID is Layer 2 - platform identity
	labels: {
		"traefik.enable":      "true"
		"stackkit.layer":      "2-platform"
		"stackkit.managed-by": "terraform"
		"stackkit.category":   "identity"
	}

	network: {
		ports: [
			{host: 3002, container: 3000, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`id.{{.domain}}`)"
			tls:     true
			port:    3000
		}
	}

	volumes: [
		{
			source:      "pocketid-data"
			target:      "/app/data"
			type:        "volume"
			backup:      true
			description: "PocketID database and config"
		},
	]

	environment: {
		"TZ": "Europe/Berlin"
	}

	environmentSecrets: {
		"DB_CONNECTION_STRING": "secret://pocketid/db-connection"
	}

	healthCheck: {
		test:     ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/health"]
		interval: "30s"
		timeout:  "5s"
		retries:  3
	}

	resources: {
		memory: "256m"
		cpus:   0.2
	}

	securityContext: {
		runAsUser:              1000
		runAsGroup:             1000
		readOnlyRootFilesystem: false
		noNewPrivileges:        true
		capabilitiesDrop: ["ALL"]
	}

	needs: ["traefik"]

	config: {
		type:          "auth"
		installMethod: "container"
		layer:         "2-platform"
		protocol:      "oidc"
	}
}

// =============================================================================
// AUTHELIA CONFIGURATION (Advanced Option)
// =============================================================================

// #AutheliaConfig defines Authelia authentication server settings
#AutheliaConfig: {
	// Enable Authelia
	enabled: bool | *false

	// Authelia version
	version: string | *"latest"

	// Docker image
	image: string | *"authelia/authelia"

	// Web UI port
	port: uint16 & >0 & <=65535 | *9091

	// Installation method
	installMethod: #InstallMethod | *"container"

	// Log level
	logLevel: "debug" | "info" | "warn" | "error" | *"info"

	// Authentication backend
	authentication: {
		// Backend type
		backend: "file" | "ldap" | *"file"

		// File backend configuration
		file?: {
			// Path to users database
			path: string | *"/config/users_database.yml"
		}

		// LDAP backend configuration
		ldap?: {
			// LDAP URL
			url: string

			// Base DN
			baseDn: string

			// Additional LDAP settings
			user?: string
		}
	}

	// Session configuration
	session: {
		// Secret (secret reference)
		secret: string

		// Session name
		name: string | *"authelia_session"

		// Session lifetime
		lifetime: string | *"1h"

		// Domain
		domain: string
	}

	// Storage configuration
	storage: {
		// Storage type
		type: "sqlite" | "postgres" | "mysql" | *"sqlite"

		// SQLite path
		sqlite?: {
			path: string | *"/config/db.sqlite3"
		}
	}

	// Access control rules
	accessControl: {
		// Default policy
		defaultPolicy: "deny" | "one_factor" | "two_factor" | *"deny"

		// Rules
		rules?: [...{
			// Domain pattern
			domain: string

			// Policy
			policy: "bypass" | "one_factor" | "two_factor"

			// Subject (user/group)
			subject?: [...string]
		}]
	}

	// Traefik integration
	traefik: {
		// Enable Traefik ForwardAuth
		enabled: bool | *true

		// Middleware name
		middlewareName: string | *"authelia"
	}

	// Resource limits
	resources?: #ResourceLimits
}

// =============================================================================
// AUTHENTIK CONFIGURATION (Enterprise Option)
// =============================================================================

// #AuthentikConfig defines Authentik identity provider settings
#AuthentikConfig: {
	// Enable Authentik
	enabled: bool | *false

	// Authelia version
	version: string | *"latest"

	// Docker compose project (Authentik is multi-container)
	composeProject: string | *"authentik"

	// Web UI port
	port: uint16 & >0 & <=65535 | *9443

	// Installation method
	installMethod: #InstallMethod | *"container"

	// Database configuration
	database: {
		// Use bundled PostgreSQL
		bundled: bool | *true

		// External connection (if not bundled)
		externalConnection?: string
	}

	// Redis configuration
	redis: {
		// Use bundled Redis
		bundled: bool | *true
	}

	// Secret key (secret reference)
	secretKey: string

	// Bootstrap password (secret reference)
	bootstrapPassword?: string

	// Traefik integration
	traefik: {
		// Enable Traefik routing
		enabled: bool | *true

		// Host rule
		host?: string
	}

	// Resource limits
	resources?: {
		server?: #ResourceLimits
		worker?: #ResourceLimits
	}
}

// =============================================================================
// PLATFORM IDENTITY SERVICE DISCRIMINATED UNION
// =============================================================================

// #PlatformIdentityService is a discriminated union for platform identity services
#PlatformIdentityService: {
	// Service type
	serviceType: "tinyauth" | "pocketid" | "authelia" | "authentik"

	// Service configuration based on type
	service: {
		if serviceType == "tinyauth" {
			#TinyAuthConfig
		}
		if serviceType == "pocketid" {
			#PocketIDConfig
		}
		if serviceType == "authelia" {
			#AutheliaConfig
		}
		if serviceType == "authentik" {
			#AuthentikConfig
		}
	}
}

// Package modern_homelab - Service Definitions
// 
// Modern Homelab = Multi-server Docker setup with:
// - Coolify (PaaS for multi-node deployments)
// - Headscale (VPN overlay for node communication)
// - Full monitoring stack (Prometheus/Grafana/Loki)
// - Public/remote access capabilities
//
// KEY DIFFERENCE FROM BASE-HOMELAB:
// - Multi-node Docker (not single-node)
// - Coolify instead of Dokploy (better multi-node support)
// - VPN overlay required for hybrid setups
// - Public access is default, not optional

package modern_homelab

import "github.com/kombihq/stackkits/base"

// =============================================================================
// CORE SERVICES (Always Required)
// =============================================================================

// #TraefikService - Reverse Proxy (same as base-homelab but with cloud config)
#TraefikService: base.#ServiceDefinition & {
	name:        "traefik"
	displayName: "Traefik"
	category:    "core"
	type:        "reverse-proxy"
	required:    true
	image:       "traefik"
	tag:         "v3.1"
	status:      "planned"
	description: "Modern reverse proxy with automatic HTTPS - deployed on cloud entry node"

	// Deployed on cloud node (public entry point)
	placement: {
		nodeType: "cloud"
		strategy: "entry-point"
	}

	network: {
		ports: [
			{host: 80, container: 80, protocol: "tcp", description: "HTTP"},
			{host: 443, container: 443, protocol: "tcp", description: "HTTPS"},
			{host: 8080, container: 8080, protocol: "tcp", description: "Dashboard"},
		]
		mode: "bridge"
	}

	config: {
		dashboard:    bool | *true
		acme:         bool | *true
		acmeEmail:    string
		acmeProvider: "letsencrypt" | "letsencrypt-staging" | *"letsencrypt"
	}
}

// =============================================================================
// VPN OVERLAY (Required for hybrid setups)
// =============================================================================

// #HeadscaleService - Self-hosted Tailscale control server
#HeadscaleService: base.#ServiceDefinition & {
	name:        "headscale"
	displayName: "Headscale"
	category:    "network"
	type:        "vpn"
	required:    true  // Required for modern-homelab
	image:       "headscale/headscale"
	tag:         "latest"
	status:      "planned"
	description: "Self-hosted Tailscale control server for VPN overlay"

	// Deployed on cloud node (coordination server)
	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 8085, container: 8080, protocol: "tcp", description: "Web UI"},
			{host: 443, container: 443, protocol: "tcp", description: "DERP/Coordination"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`hs.{{.domain}}`)"
			tls:     true
		}
	}

	volumes: [
		{
			source:      "headscale-data"
			target:      "/var/lib/headscale"
			type:        "volume"
			backup:      true
			description: "Headscale database and config"
		},
	]

	config: {
		serverUrl:      string  // https://hs.domain.com
		baseDomain:     string  // domain.com
		derpEnabled:    bool | *true
		magicDns:       bool | *true
		nameservers:    [...string] | *["1.1.1.1", "8.8.8.8"]
	}
}

// #TailscaleAgent - Tailscale client on each node
#TailscaleAgent: base.#ServiceDefinition & {
	name:        "tailscale"
	displayName: "Tailscale Agent"
	category:    "network"
	type:        "vpn-client"
	required:    true
	image:       "tailscale/tailscale"
	tag:         "stable"
	status:      "planned"
	description: "Tailscale client connecting to Headscale - runs on ALL nodes"

	// Deployed on every node
	placement: {
		nodeType: "all"
		strategy: "daemonset"  // One per node
	}

	network: {
		mode: "host"  // Needs host networking for VPN
	}

	config: {
		authKey:     string  // Pre-auth key from Headscale
		controlUrl:  string  // https://hs.domain.com
		hostname:    string  // Node hostname
		advertiseRoutes: [...string]  // Local subnets to advertise
	}
}

// =============================================================================
// PLATFORM: COOLIFY (PaaS)
// =============================================================================

// #CoolifyService - Self-hosted PaaS for multi-node deployments
#CoolifyService: base.#ServiceDefinition & {
	name:        "coolify"
	displayName: "Coolify"
	category:    "platform"
	type:        "paas"
	required:    true
	image:       "coollabsio/coolify"
	tag:         "latest"
	status:      "planned"
	description: "Self-hosted Heroku/Vercel alternative with multi-server support"
	needs:       ["traefik", "headscale"]

	// Deployed on cloud node (management plane)
	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 8000, container: 8000, protocol: "tcp", description: "Web UI"},
			{host: 6001, container: 6001, protocol: "tcp", description: "Websockets"},
			{host: 6002, container: 6002, protocol: "tcp", description: "Terminal"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`coolify.{{.domain}}`)"
			tls:     true
			port:    8000
		}
	}

	volumes: [
		{
			source:      "/var/run/docker.sock"
			target:      "/var/run/docker.sock"
			type:        "bind"
			readOnly:    false
			backup:      false
			description: "Docker socket for container management"
		},
		{
			source:      "coolify-data"
			target:      "/data/coolify"
			type:        "volume"
			backup:      true
			description: "Coolify application data"
		},
		{
			source:      "/data/coolify/ssh"
			target:      "/data/coolify/ssh"
			type:        "bind"
			backup:      true
			description: "SSH keys for remote node access"
		},
	]

	config: {
		appUrl:           string  // https://coolify.domain.com
		pushEnabled:      bool | *true
		autoUpdate:       bool | *false
		instanceSettings: {
			isRegistrationEnabled:    bool | *false
			isAutoUpdateEnabled:      bool | *false
		}
	}

	// Multi-node feature: Coolify can manage remote Docker hosts
	multiNode: {
		enabled: true
		// Remote nodes connect via VPN (Tailscale IP addresses)
		remoteHosts: [...{
			name:     string
			address:  string  // Tailscale IP (100.x.x.x)
			user:     string | *"root"
			port:     int | *22
		}]
	}
}

// =============================================================================
// MONITORING (Full Stack)
// =============================================================================

// #PrometheusService - Metrics collection
#PrometheusService: base.#ServiceDefinition & {
	name:        "prometheus"
	displayName: "Prometheus"
	category:    "monitoring"
	type:        "metrics"
	required:    false
	enabled:     true
	image:       "prom/prometheus"
	tag:         "v2.48.0"
	status:      "planned"
	description: "Time-series database for metrics collection"
	needs:       ["traefik"]

	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 9090, container: 9090, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`prometheus.{{.domain}}`)"
			tls:     true
		}
	}

	volumes: [
		{
			source:      "prometheus-data"
			target:      "/prometheus"
			type:        "volume"
			backup:      true
			description: "Prometheus TSDB data"
		},
	]

	config: {
		retention:       string | *"15d"
		scrapeInterval:  string | *"15s"
		alertmanager:    bool | *true
	}
}

// #GrafanaService - Dashboards
#GrafanaService: base.#ServiceDefinition & {
	name:        "grafana"
	displayName: "Grafana"
	category:    "monitoring"
	type:        "dashboards"
	required:    false
	enabled:     true
	image:       "grafana/grafana"
	tag:         "10.2.3"
	status:      "planned"
	description: "Visualization and dashboards for metrics and logs"
	needs:       ["prometheus", "traefik"]

	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 3000, container: 3000, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`grafana.{{.domain}}`)"
			tls:     true
		}
	}

	volumes: [
		{
			source:      "grafana-data"
			target:      "/var/lib/grafana"
			type:        "volume"
			backup:      true
			description: "Grafana dashboards and config"
		},
	]

	config: {
		adminUser:      string | *"admin"
		adminPassword:  string  // Generated
		anonymousAccess: bool | *false
		datasources: {
			prometheus: bool | *true
			loki:       bool | *true
		}
	}
}

// #LokiService - Log aggregation
#LokiService: base.#ServiceDefinition & {
	name:        "loki"
	displayName: "Loki"
	category:    "monitoring"
	type:        "logging"
	required:    false
	enabled:     true
	image:       "grafana/loki"
	tag:         "2.9.3"
	status:      "planned"
	description: "Log aggregation system - like Prometheus but for logs"
	needs:       ["traefik"]

	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 3100, container: 3100, protocol: "tcp", description: "HTTP API"},
		]
	}

	volumes: [
		{
			source:      "loki-data"
			target:      "/loki"
			type:        "volume"
			backup:      true
			description: "Loki index and chunks"
		},
	]

	config: {
		retention: string | *"168h"  // 7 days
	}
}

// #PromtailService - Log shipping agent
#PromtailAgent: base.#ServiceDefinition & {
	name:        "promtail"
	displayName: "Promtail"
	category:    "monitoring"
	type:        "log-shipper"
	required:    false
	enabled:     true
	image:       "grafana/promtail"
	tag:         "2.9.3"
	status:      "planned"
	description: "Log shipping agent - runs on ALL nodes"
	needs:       ["loki"]

	// Deployed on every node
	placement: {
		nodeType: "all"
		strategy: "daemonset"
	}

	volumes: [
		{
			source:      "/var/log"
			target:      "/var/log"
			type:        "bind"
			readOnly:    true
			description: "System logs"
		},
		{
			source:      "/var/lib/docker/containers"
			target:      "/var/lib/docker/containers"
			type:        "bind"
			readOnly:    true
			description: "Docker container logs"
		},
	]

	config: {
		lokiUrl: string  // http://loki:3100 or via Tailscale IP
	}
}

// #UptimeKumaService - Status monitoring (basic)
#UptimeKumaService: base.#ServiceDefinition & {
	name:        "uptime-kuma"
	displayName: "Uptime Kuma"
	category:    "monitoring"
	type:        "uptime"
	required:    false
	enabled:     true
	image:       "louislam/uptime-kuma"
	tag:         "1"
	status:      "planned"
	description: "Self-hosted uptime monitoring"
	needs:       ["traefik"]

	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 3001, container: 3001, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`status.{{.domain}}`)"
			tls:     true
		}
	}

	volumes: [
		{
			source:      "uptime-kuma-data"
			target:      "/app/data"
			type:        "volume"
			backup:      true
			description: "Uptime Kuma database"
		},
	]
}

// #BeszelService - Alternative lightweight monitoring
#BeszelService: base.#ServiceDefinition & {
	name:        "beszel"
	displayName: "Beszel"
	category:    "monitoring"
	type:        "metrics"
	required:    false
	enabled:     false  // Not default, use in beszel variant
	image:       "henrygd/beszel"
	tag:         "latest"
	status:      "planned"
	description: "Lightweight server monitoring with Docker stats"

	placement: {
		nodeType: "cloud"
		strategy: "single"
	}

	network: {
		ports: [
			{host: 8090, container: 8090, protocol: "tcp", description: "Web UI"},
		]
		traefik: {
			enabled: true
			rule:    "Host(`monitoring.{{.domain}}`)"
			tls:     true
		}
	}

	volumes: [
		{
			source:      "beszel-data"
			target:      "/beszel_data"
			type:        "volume"
			backup:      true
			description: "Beszel database"
		},
	]
}

// =============================================================================
// SERVICE COLLECTIONS (Variants)
// =============================================================================

// Default variant: Full stack
#DefaultServices: {
	traefik:     #TraefikService
	headscale:   #HeadscaleService
	tailscale:   #TailscaleAgent
	coolify:     #CoolifyService
	prometheus:  #PrometheusService
	grafana:     #GrafanaService
	loki:        #LokiService
	promtail:    #PromtailAgent
	uptimeKuma:  #UptimeKumaService
}

// Minimal variant: Basic setup
#MinimalServices: {
	traefik:     #TraefikService
	headscale:   #HeadscaleService
	tailscale:   #TailscaleAgent
	coolify:     #CoolifyService
	uptimeKuma:  #UptimeKumaService
}

// Beszel variant: Lightweight monitoring
#BeszelServices: {
	traefik:     #TraefikService
	headscale:   #HeadscaleService
	tailscale:   #TailscaleAgent
	coolify:     #CoolifyService
	beszel:      #BeszelService & {enabled: true}
}

// =============================================================================
// NODE TOPOLOGY HELPERS
// =============================================================================

// #NodePlacement defines where services run
#NodePlacement: {
	// Cloud nodes: Public IP, entry point for internet traffic
	cloud: [...string]
	
	// Local nodes: Behind NAT, accessed via VPN
	local: [...string]
	
	// Services that run on all nodes
	daemonset: [...string]
}

// Default placement for modern-homelab
#DefaultPlacement: #NodePlacement & {
	cloud: ["traefik", "headscale", "coolify", "prometheus", "grafana", "loki", "uptime-kuma"]
	local: []  // Local nodes run workloads via Coolify
	daemonset: ["tailscale", "promtail"]
}

// Package modern_homelab - Default Values
// 
// Tier-specific defaults for Modern Homelab
// These are sensible production-ready defaults for a hybrid Docker setup.

package modern_homelab

// =============================================================================
// NODE DEFAULTS
// =============================================================================

// Default cloud node specs (VPS sizing)
#CloudNodeDefaults: {
	// Hetzner Cloud example (cheapest production-ready)
	provider: {
		type:   "hetzner"
		region: "fsn1"  // Falkenstein, Germany
		size:   "cx21"  // 2 vCPU, 4 GB RAM
		image:  "debian-12"
	}
	
	docker: {
		version:  "24.0"
		dataRoot: "/var/lib/docker"
	}
	
	// Cloud nodes should have swap disabled
	system: {
		swapEnabled: false
		swapSize:    0
	}
}

// Default local node specs (on-premises)
#LocalNodeDefaults: {
	provider: {
		type: "bare-metal"
	}
	
	docker: {
		version:  "24.0"
		dataRoot: "/var/lib/docker"
	}
	
	// Local nodes can have swap
	system: {
		swapEnabled: true
		swapSize:    4096  // 4GB
	}
}

// =============================================================================
// VPN DEFAULTS (Headscale)
// =============================================================================

#VpnDefaults: {
	enabled:     true
	provider:    "headscale"
	derpEnabled: true
	derpRegions: ["default"]
	magicDns:    true
}

// =============================================================================
// SERVICE DEFAULTS
// =============================================================================

// Traefik defaults
#TraefikDefaults: {
	dashboard:    true
	acme:         true
	acmeProvider: "letsencrypt"
	
	// Log level for production
	logLevel: "INFO"
	
	// Access log (for monitoring)
	accessLog: {
		enabled:  true
		filePath: "/var/log/traefik/access.log"
	}
	
	// Metrics for Prometheus
	metrics: {
		prometheus: true
		entrypoint: "metrics"
	}
}

// Coolify defaults
#CoolifyDefaults: {
	autoUpdate:  false
	pushEnabled: true
	
	instanceSettings: {
		isRegistrationEnabled: false
		isAutoUpdateEnabled:   false
	}
	
	// Default resource limits for Coolify-managed containers
	resources: {
		cpuLimit:    "2.0"
		memoryLimit: "2048m"
	}
}

// Monitoring defaults (PLG Stack)
#MonitoringDefaults: {
	prometheus: {
		retention:      "15d"
		scrapeInterval: "15s"
		alertmanager:   true
		
		// Remote write disabled by default
		remoteWrite: {
			enabled: false
		}
	}
	
	grafana: {
		anonymousAccess: false
		plugins: [
			"grafana-piechart-panel",
			"grafana-clock-panel",
		]
		
		// Dashboards to provision
		dashboards: {
			nodeExporter: true
			docker:       true
			traefik:      true
		}
	}
	
	loki: {
		retention: "168h"  // 7 days
		
		// Limits
		ingestionRateLimit:   "4MB"
		ingestionBurstSize:   "6MB"
		maxQueryLookback:     "168h"
	}
}

// =============================================================================
// VARIANT DEFAULTS
// =============================================================================

// Default variant: Full monitoring + VPN + Coolify
#VariantDefault: {
	services: {
		traefik:     {enabled: true, config: #TraefikDefaults}
		headscale:   {enabled: true, config: #VpnDefaults}
		coolify:     {enabled: true, config: #CoolifyDefaults}
		prometheus:  {enabled: true, config: #MonitoringDefaults.prometheus}
		grafana:     {enabled: true, config: #MonitoringDefaults.grafana}
		loki:        {enabled: true, config: #MonitoringDefaults.loki}
		promtail:    {enabled: true}
		uptimeKuma:  {enabled: true}
	}
}

// Minimal variant: Just Coolify + VPN + basic uptime
#VariantMinimal: {
	services: {
		traefik:     {enabled: true, config: #TraefikDefaults}
		headscale:   {enabled: true, config: #VpnDefaults}
		coolify:     {enabled: true, config: #CoolifyDefaults}
		prometheus:  {enabled: false}
		grafana:     {enabled: false}
		loki:        {enabled: false}
		promtail:    {enabled: false}
		uptimeKuma:  {enabled: true}
	}
}

// Beszel variant: Lightweight monitoring alternative
#VariantBeszel: {
	services: {
		traefik:     {enabled: true, config: #TraefikDefaults}
		headscale:   {enabled: true, config: #VpnDefaults}
		coolify:     {enabled: true, config: #CoolifyDefaults}
		prometheus:  {enabled: false}
		grafana:     {enabled: false}
		loki:        {enabled: false}
		promtail:    {enabled: false}
		uptimeKuma:  {enabled: false}
		beszel:      {enabled: true}
	}
}

// =============================================================================
// NETWORK DEFAULTS
// =============================================================================

#NetworkDefaults: {
	// Default Docker network for services
	serviceBridge: {
		name:    "kombistack"
		driver:  "bridge"
		subnet:  "172.20.0.0/16"
		gateway: "172.20.0.1"
	}
	
	// Tailscale network range (assigned by Headscale)
	tailscale: {
		subnet: "100.64.0.0/10"  // CGNAT range
	}
	
	// Port ranges
	ports: {
		reserved: [22, 80, 443]  // SSH, HTTP, HTTPS
		traefik:  [80, 443, 8080]
		coolify:  [8000, 6001, 6002]
		monitoring: {
			prometheus: 9090
			grafana:    3000
			loki:       3100
		}
	}
}

// =============================================================================
// SECURITY DEFAULTS
// =============================================================================

#SecurityDefaults: {
	// Firewall rules (applied via OpenTofu)
	firewall: {
		inbound: [
			{port: 22, protocol: "tcp", source: "0.0.0.0/0", description: "SSH"},
			{port: 80, protocol: "tcp", source: "0.0.0.0/0", description: "HTTP"},
			{port: 443, protocol: "tcp", source: "0.0.0.0/0", description: "HTTPS"},
			{port: 41641, protocol: "udp", source: "0.0.0.0/0", description: "Tailscale"},
		]
		outbound: [
			{port: 0, protocol: "all", destination: "0.0.0.0/0", description: "Allow all outbound"},
		]
	}
	
	// SSH hardening
	ssh: {
		permitRootLogin:        "prohibit-password"
		passwordAuthentication: false
		pubkeyAuthentication:   true
	}
	
	// Docker security
	docker: {
		liverestore:    true
		userlandProxy:  false
		iptables:       true
	}
}

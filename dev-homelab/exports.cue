package dev_homelab

// Exports for 3-Layer Validation
// This file provides the top-level fields required for layer validation

// LAYER 1: FOUNDATION
system: {
	timezone: "UTC"
	locale:   "en_US.UTF-8"
	hostname: "dev-homelab"
}

packages: {
	manager: "apt"
	base: [
		"curl",
		"wget",
		"ca-certificates",
		"gnupg",
		"lsb-release",
		"apt-transport-https",
		"software-properties-common",
	]
	tools: [
		"htop",
		"btop",
		"tmux",
		"jq",
		"tree",
		"ncdu",
	]
	extra: []
	remove: []
}

security: {
	ssh: {
		port:                 22
		permitRootLogin:      "no"
		passwordAuth:         false
		pubkeyAuth:           true
		maxAuthTries:         3
		loginGraceTime:       60
		allowTcpForwarding:   false
		allowAgentForwarding: false
		x11Forwarding:        false
		allowUsers:           []
		allowGroups:          []
		clientAliveInterval:  300
		clientAliveCountMax:  3
	}
	firewall: {
		enabled:         true
		backend:         "ufw"
		defaultInbound:  "deny"
		defaultOutbound: "allow"
		defaultForward:  "deny"
		rules: [{
			port:        22
			protocol:    "tcp"
			source:      "any"
			action:      "allow"
			direction:   "in"
			comment:     "SSH access"
			enabled:     true
		}, {
			port:        80
			protocol:    "tcp"
			source:      "any"
			action:      "allow"
			direction:   "in"
			comment:     "HTTP"
			enabled:     true
		}, {
			port:        443
			protocol:    "tcp"
			source:      "any"
			action:      "allow"
			direction:   "in"
			comment:     "HTTPS"
			enabled:     true
		}]
	}
}

// LAYER 2: PLATFORM
platform: "docker"

container: {
	engine:          "docker"
	rootless:        false
	liveRestore:     true
	logDriver:       "json-file"
	networkDriver:   "bridge"
	storageDriver:   "overlay2"
	dataRoot:        "/var/lib/docker"
	composeFile:     "docker-compose.yml"
}

network: {
	defaults: {
		domain: "local"
		subnet: "172.21.0.0/16"
		driver: "bridge"
		mtu:    1500
		ipv6:   false
		dhcp:   true
	}
	dns: {
		servers:           ["1.1.1.1", "8.8.8.8"]
		search:            []
		localResolver:     false
		localResolverPort: 53
		doh:               false
	}
	ntp: {
		enabled: true
		servers: ["time.cloudflare.com", "time.google.com"]
		client:  "systemd-timesyncd"
	}
	vpn: {
		enabled: false
		type:    "none"
	}
	proxy: {
		enabled: false
		noProxy: ["localhost", "127.0.0.1", "::1"]
	}
}

// LAYER 3: APPLICATIONS
services: {
	dokploy: {
		name:        "dokploy"
		image:       "dokploy/dokploy:latest"
		description: "Open-source PAAS for deploying applications"
		role:        "paas"
		type:        "paas"
		enabled:     true
		needs:       []
		node:        "main"
		network: {
			mode: "bridge"
			ports: [{
				host:      3000
				container: 3000
				protocol:  "tcp"
			}]
			traefik: {
				enabled: false
			}
		}
		volumes: [{
			source:   "dokploy-data"
			target:   "/etc/dokploy"
			type:     "volume"
			readOnly: false
			backup:   true
		}]
		restartPolicy: "unless-stopped"
	}

	uptimeKuma: {
		name:        "uptime-kuma"
		image:       "louislam/uptime-kuma:1"
		description: "Self-hosted monitoring tool for uptime and health checks"
		role:        "monitoring"
		type:        "monitoring"
		enabled:     true
		needs:       []
		node:        "main"
		network: {
			mode: "bridge"
			ports: [{
				host:      3001
				container: 3001
				protocol:  "tcp"
			}]
			traefik: {
				enabled: false
			}
		}
		volumes: [{
			source:   "kuma-data"
			target:   "/app/data"
			type:     "volume"
			readOnly: false
			backup:   true
		}]
		restartPolicy: "unless-stopped"
	}

	whoami: {
		name:        "whoami"
		image:       "traefik/whoami:latest"
		description: "Simple HTTP service for deployment testing"
		role:        "test-endpoint"
		type:        "utility"
		enabled:     true
		needs:       []
		node:        "main"
		network: {
			mode: "bridge"
			ports: [{
				host:      9080
				container: 80
				protocol:  "tcp"
			}]
			traefik: {
				enabled: false
			}
		}
		restartPolicy: "unless-stopped"
	}
}

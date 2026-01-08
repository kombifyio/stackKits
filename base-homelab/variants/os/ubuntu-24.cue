// Package base_homelab - Ubuntu 24.04 LTS variant
package base_homelab

// #Ubuntu24Variant provides Ubuntu 24.04 LTS specific configuration
#Ubuntu24Variant: #OSVariant & {
	os: {
		family:       "debian"
		distribution: "ubuntu"
		version:      "24.04"
		codename:     "noble"
		eol:          "2034-04"
		lts:          true
	}

	packages: {
		manager: "apt"
		updateCmd: [
			"apt-get update",
			"apt-get upgrade -y",
		]

		// System packages
		base: [
			"apt-transport-https",
			"ca-certificates",
			"curl",
			"gnupg",
			"lsb-release",
			"software-properties-common",
		]

		// Modern CLI tools (Ubuntu 24.04 has these in repos)
		tools: [
			"bat",
			"eza",          // Renamed from exa
			"fd-find",
			"ripgrep",
			"htop",
			"btop",
			"tmux",
			"jq",
			"ncdu",
		]

		// Tool aliases (Ubuntu-specific binary names)
		toolAliases: {
			"bat":     "batcat"
			"fd-find": "fdfind"
		}

		// Docker installation
		docker: {
			repo:       "https://download.docker.com/linux/ubuntu"
			keyUrl:     "https://download.docker.com/linux/ubuntu/gpg"
			keyring:    "/etc/apt/keyrings/docker.gpg"
			sourcelist: "/etc/apt/sources.list.d/docker.list"
			packages: [
				"docker-ce",
				"docker-ce-cli",
				"containerd.io",
				"docker-buildx-plugin",
				"docker-compose-plugin",
			]
		}
	}

	// Firewall
	firewall: {
		backend: "ufw"
		package: "ufw"
		commands: {
			enable:   "ufw --force enable"
			disable:  "ufw disable"
			status:   "ufw status verbose"
			allow:    "ufw allow"
			deny:     "ufw deny"
			delete:   "ufw delete"
			reset:    "ufw --force reset"
			reload:   "ufw reload"
			logging:  "ufw logging"
		}
		defaultRules: [
			"ufw default deny incoming",
			"ufw default allow outgoing",
			"ufw allow OpenSSH",
		]
	}

	// Systemd services
	services: {
		docker: {
			name:    "docker.service"
			enabled: true
			started: true
		}
		containerd: {
			name:    "containerd.service"
			enabled: true
			started: true
		}
		ssh: {
			name:    "ssh.service"
			enabled: true
			started: true
		}
		firewall: {
			name:    "ufw.service"
			enabled: true
			started: true
		}
		timesyncd: {
			name:    "systemd-timesyncd.service"
			enabled: true
			started: true
		}
	}

	// Paths
	paths: {
		sshConfig:    "/etc/ssh/sshd_config"
		sshConfigDir: "/etc/ssh/sshd_config.d"
		dockerConfig: "/etc/docker/daemon.json"
		hostsFile:    "/etc/hosts"
		sudoersDir:   "/etc/sudoers.d"
		aptSources:   "/etc/apt/sources.list.d"
		aptKeyrings:  "/etc/apt/keyrings"
	}

	// Ubuntu 24.04 specific kernel parameters
	sysctl: {
		// Enable IP forwarding for Docker
		"net.ipv4.ip_forward":                 1
		"net.ipv6.conf.all.forwarding":        1
		// Increase connection tracking
		"net.netfilter.nf_conntrack_max":      262144
		// Optimize for containers
		"vm.max_map_count":                    262144
		"fs.inotify.max_user_watches":         524288
		"fs.inotify.max_user_instances":       512
	}

	// Bootstrap script sections
	bootstrap: {
		preInstall: """
			#!/bin/bash
			set -euo pipefail
			
			# Update package lists
			apt-get update
			
			# Install prerequisites
			apt-get install -y \\
			    apt-transport-https \\
			    ca-certificates \\
			    curl \\
			    gnupg \\
			    lsb-release
			"""

		installDocker: """
			#!/bin/bash
			set -euo pipefail
			
			# Add Docker's official GPG key
			install -m 0755 -d /etc/apt/keyrings
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \\
			    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
			chmod a+r /etc/apt/keyrings/docker.gpg
			
			# Add the repository to Apt sources
			echo \\
			    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \\
			    https://download.docker.com/linux/ubuntu \\
			    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \\
			    tee /etc/apt/sources.list.d/docker.list > /dev/null
			
			# Install Docker
			apt-get update
			apt-get install -y \\
			    docker-ce \\
			    docker-ce-cli \\
			    containerd.io \\
			    docker-buildx-plugin \\
			    docker-compose-plugin
			
			# Enable and start Docker
			systemctl enable docker
			systemctl start docker
			"""

		configureFirewall: """
			#!/bin/bash
			set -euo pipefail
			
			# Install UFW if not present
			apt-get install -y ufw
			
			# Reset firewall rules
			ufw --force reset
			
			# Set default policies
			ufw default deny incoming
			ufw default allow outgoing
			
			# Allow SSH
			ufw allow OpenSSH
			
			# Allow HTTP/HTTPS
			ufw allow 80/tcp
			ufw allow 443/tcp
			
			# Enable firewall
			ufw --force enable
			"""

		postInstall: """
			#!/bin/bash
			set -euo pipefail
			
			# Install modern CLI tools
			apt-get install -y \\
			    bat \\
			    eza \\
			    fd-find \\
			    ripgrep \\
			    htop \\
			    btop \\
			    tmux \\
			    jq \\
			    ncdu \\
			    micro
			
			# Set up shell aliases
			cat >> /etc/profile.d/kombi-aliases.sh << 'EOF'
			alias cat='batcat'
			alias ls='eza'
			alias ll='eza -la'
			alias fd='fdfind'
			EOF
			
			# Create stacks directory
			mkdir -p /opt/stacks
			chmod 755 /opt/stacks
			"""
	}
}

// #OSVariant base definition for all OS variants
#OSVariant: {
	os: {
		family:       string
		distribution: string
		version:      string
		codename:     string
		eol:          string
		lts:          bool
	}

	packages: {
		manager:   string
		updateCmd: [...string]
		base:      [...string]
		tools:     [...string]
		toolAliases?: [string]: string
		docker: {
			repo:       string
			keyUrl:     string
			keyring:    string
			sourcelist: string
			packages:   [...string]
		}
	}

	firewall: {
		backend:      string
		package:      string
		commands:     [string]: string
		defaultRules: [...string]
	}

	services: [string]: {
		name:    string
		enabled: bool
		started: bool
	}

	paths: [string]: string

	sysctl: [string]: int | string

	bootstrap: {
		preInstall:        string
		installDocker:     string
		configureFirewall: string
		postInstall:       string
	}
}

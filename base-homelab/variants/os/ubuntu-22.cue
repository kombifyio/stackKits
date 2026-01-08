// Ubuntu 22.04 LTS Variant
// OS-spezifische Konfiguration für Ubuntu 22.04 (Jammy Jellyfish)
package variants

import "kombistack.dev/stackkits/base"

// Ubuntu 22.04 LTS Variante
#Ubuntu22Variant: base.#SystemConfig & {
	os: {
		family:  "debian"
		distro:  "ubuntu"
		version: "22.04"
		codename: "jammy"
	}

	// Package-Manager
	packageManager: "apt"

	// Base-Packages für Ubuntu 22.04
	basePackages: [
		"apt-transport-https",
		"ca-certificates",
		"curl",
		"gnupg",
		"lsb-release",
		"software-properties-common",
		"unattended-upgrades",
		"ufw",
		"fail2ban",
		"htop",
		"vim",
		"git",
		"jq",
	]

	// Docker-Installation für Ubuntu 22.04
	docker: {
		installMethod: "official"
		packages: [
			"docker-ce",
			"docker-ce-cli",
			"containerd.io",
			"docker-buildx-plugin",
			"docker-compose-plugin",
		]
		repository: {
			url:     "https://download.docker.com/linux/ubuntu"
			keyUrl:  "https://download.docker.com/linux/ubuntu/gpg"
			keyring: "/etc/apt/keyrings/docker.gpg"
			// Ubuntu 22.04: jammy
			suite:   "jammy"
			components: ["stable"]
		}
	}

	// Firewall-Konfiguration
	firewall: {
		backend: "ufw"
		defaultPolicy: {
			incoming: "deny"
			outgoing: "allow"
		}
		rules: [
			{port: 22, proto: "tcp", comment: "SSH"},
			{port: 80, proto: "tcp", comment: "HTTP"},
			{port: 443, proto: "tcp", comment: "HTTPS"},
		]
	}

	// Systemd-Units
	systemd: {
		enabled: [
			"docker.service",
			"containerd.service",
			"ufw.service",
			"fail2ban.service",
			"unattended-upgrades.service",
		]
		disabled: [
			"snapd.service",
			"snapd.socket",
		]
	}

	// Kernel-Parameter (sysctl)
	sysctl: {
		// Docker-bezogen
		"net.ipv4.ip_forward": "1"
		"net.bridge.bridge-nf-call-iptables": "1"
		"net.bridge.bridge-nf-call-ip6tables": "1"
		
		// Security
		"net.ipv4.conf.all.rp_filter": "1"
		"net.ipv4.conf.default.rp_filter": "1"
		"net.ipv4.icmp_echo_ignore_broadcasts": "1"
	}

	// Ubuntu 22.04 spezifische Hinweise
	notes: """
		Ubuntu 22.04 LTS (Jammy Jellyfish)
		- Support bis April 2027 (Standard) / April 2032 (ESM)
		- Kernel 5.15 LTS mit HWE verfügbar
		- Snap vorinstalliert (wird für Homelab deaktiviert)
		- AppArmor standardmäßig aktiviert
		"""
}

// Bootstrap-Script für Ubuntu 22.04
#Ubuntu22Bootstrap: {
	// Script für cloud-init / user-data
	script: """
		#!/bin/bash
		set -euo pipefail

		export DEBIAN_FRONTEND=noninteractive

		echo "=== KombiStack Bootstrap: Ubuntu 22.04 ==="

		# System aktualisieren
		apt-get update
		apt-get upgrade -y

		# Basis-Pakete installieren
		apt-get install -y \\
			apt-transport-https \\
			ca-certificates \\
			curl \\
			gnupg \\
			lsb-release \\
			software-properties-common \\
			unattended-upgrades \\
			ufw \\
			fail2ban \\
			htop \\
			vim \\
			git \\
			jq

		# Docker Repository hinzufügen
		install -m 0755 -d /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		chmod a+r /etc/apt/keyrings/docker.gpg

		echo \\
			"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \\
			$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

		# Docker installieren
		apt-get update
		apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

		# Docker starten und aktivieren
		systemctl enable docker
		systemctl start docker

		# UFW konfigurieren
		ufw default deny incoming
		ufw default allow outgoing
		ufw allow 22/tcp comment 'SSH'
		ufw allow 80/tcp comment 'HTTP'
		ufw allow 443/tcp comment 'HTTPS'
		echo "y" | ufw enable

		# Fail2ban aktivieren
		systemctl enable fail2ban
		systemctl start fail2ban

		# Snap deaktivieren (optional, für Homelab-Optimierung)
		systemctl disable snapd.service || true
		systemctl disable snapd.socket || true

		# Sysctl für Docker
		cat >> /etc/sysctl.d/99-kombistack.conf << 'EOF'
		net.ipv4.ip_forward = 1
		net.bridge.bridge-nf-call-iptables = 1
		net.bridge.bridge-nf-call-ip6tables = 1
		net.ipv4.conf.all.rp_filter = 1
		EOF
		sysctl --system

		# Stacks-Verzeichnis erstellen
		mkdir -p /opt/stacks
		chmod 755 /opt/stacks

		echo "=== Bootstrap abgeschlossen ==="
		"""
}

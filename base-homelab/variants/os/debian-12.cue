// Debian 12 (Bookworm) Variant
// OS-spezifische Konfiguration für Debian 12
package variants

import "kombistack.dev/stackkits/base"

// Debian 12 Variante
#Debian12Variant: base.#SystemConfig & {
	os: {
		family:   "debian"
		distro:   "debian"
		version:  "12"
		codename: "bookworm"
	}

	// Package-Manager
	packageManager: "apt"

	// Base-Packages für Debian 12
	basePackages: [
		"apt-transport-https",
		"ca-certificates",
		"curl",
		"gnupg",
		"lsb-release",
		"unattended-upgrades",
		"nftables",
		"fail2ban",
		"htop",
		"vim",
		"git",
		"jq",
	]

	// Docker-Installation für Debian 12
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
			url:     "https://download.docker.com/linux/debian"
			keyUrl:  "https://download.docker.com/linux/debian/gpg"
			keyring: "/etc/apt/keyrings/docker.gpg"
			// Debian 12: bookworm
			suite:      "bookworm"
			components: ["stable"]
		}
	}

	// Firewall-Konfiguration - Debian 12 nutzt nftables
	firewall: {
		backend: "nftables"
		defaultPolicy: {
			incoming: "drop"
			outgoing: "accept"
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
			"nftables.service",
			"fail2ban.service",
			"unattended-upgrades.service",
		]
		disabled: []
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
		"kernel.dmesg_restrict": "1"
	}

	// Debian 12 spezifische Hinweise
	notes: """
		Debian 12 (Bookworm)
		- Support bis Juni 2026 (Security) / Juni 2028 (LTS)
		- Kernel 6.1 LTS
		- nftables als Standard-Firewall (iptables als Legacy)
		- AppArmor verfügbar, aber nicht standardmäßig aktiviert
		- Minimales System ohne Bloatware
		"""
}

// nftables Konfiguration für Debian 12
#Debian12NftablesConfig: {
	config: """
		#!/usr/sbin/nft -f
		
		# KombiStack nftables configuration
		flush ruleset
		
		table inet filter {
			chain input {
				type filter hook input priority filter; policy drop;
				
				# Established/related connections
				ct state established,related accept
				
				# Loopback
				iif "lo" accept
				
				# ICMP
				ip protocol icmp accept
				ip6 nexthdr icmpv6 accept
				
				# SSH
				tcp dport 22 accept comment "SSH"
				
				# HTTP/HTTPS
				tcp dport { 80, 443 } accept comment "Web Traffic"
				
				# Drop invalid
				ct state invalid drop
			}
			
			chain forward {
				type filter hook forward priority filter; policy accept;
				
				# Docker forward rules
				ct state established,related accept
			}
			
			chain output {
				type filter hook output priority filter; policy accept;
			}
		}
		"""
}

// Bootstrap-Script für Debian 12
#Debian12Bootstrap: {
	script: """
		#!/bin/bash
		set -euo pipefail

		export DEBIAN_FRONTEND=noninteractive

		echo "=== KombiStack Bootstrap: Debian 12 ==="

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
			unattended-upgrades \\
			nftables \\
			fail2ban \\
			htop \\
			vim \\
			git \\
			jq

		# Docker Repository hinzufügen
		install -m 0755 -d /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		chmod a+r /etc/apt/keyrings/docker.gpg

		echo \\
			"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \\
			$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

		# Docker installieren
		apt-get update
		apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

		# Docker starten und aktivieren
		systemctl enable docker
		systemctl start docker

		# nftables konfigurieren
		cat > /etc/nftables.conf << 'EOF'
		#!/usr/sbin/nft -f
		flush ruleset

		table inet filter {
			chain input {
				type filter hook input priority filter; policy drop;
				ct state established,related accept
				iif "lo" accept
				ip protocol icmp accept
				ip6 nexthdr icmpv6 accept
				tcp dport 22 accept comment "SSH"
				tcp dport { 80, 443 } accept comment "Web"
				ct state invalid drop
			}
			chain forward {
				type filter hook forward priority filter; policy accept;
				ct state established,related accept
			}
			chain output {
				type filter hook output priority filter; policy accept;
			}
		}
		EOF

		systemctl enable nftables
		systemctl start nftables

		# Fail2ban aktivieren
		systemctl enable fail2ban
		systemctl start fail2ban

		# Sysctl für Docker
		cat >> /etc/sysctl.d/99-kombistack.conf << 'EOF'
		net.ipv4.ip_forward = 1
		net.bridge.bridge-nf-call-iptables = 1
		net.bridge.bridge-nf-call-ip6tables = 1
		net.ipv4.conf.all.rp_filter = 1
		kernel.dmesg_restrict = 1
		EOF
		sysctl --system

		# Stacks-Verzeichnis erstellen
		mkdir -p /opt/stacks
		chmod 755 /opt/stacks

		echo "=== Bootstrap abgeschlossen ==="
		"""
}

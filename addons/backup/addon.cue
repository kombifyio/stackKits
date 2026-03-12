// Package backup - Backup Add-On
//
// Encrypted, deduplicated backups following the 3-2-1 rule:
//   - 3 copies of data
//   - 2 different storage types
//   - 1 offsite copy
//
// Uses Restic for backup engine with SOPS + age for secrets.
//
// License:
//   - Restic: BSD-2-Clause
//
// Offsite providers:
//   - Backblaze B2 (cheapest object storage)
//   - Hetzner Storage Box
//   - Any S3-compatible endpoint
//
// Usage:
//   addons: backup: backup.#Config & {
//       schedule: "0 2 * * *"
//       targets: offsite: enabled: true
//   }

package backup

// #Config defines backup add-on configuration
#Config: {
	_addon: {
		name:        "backup"
		displayName: "Backup"
		version:     "1.0.0"
		layer:       "INFRASTRUCTURE"
		description: "Restic-based encrypted backups with 3-2-1 strategy"
	}

	_compatibility: {
		stackkits: ["base-kit", "dev-homelab", "modern-homelab", "ha-kit"]
		contexts:  ["local", "cloud", "pi"]
		requires:  []
		conflicts: []
	}

	enabled: bool | *true

	// Backup engine
	provider: *"restic" | "borgmatic"

	// Backup schedule (cron)
	schedule: string | *"0 2 * * *"

	// Retention policy
	retention: #RetentionPolicy

	// Backup targets
	targets: #BackupTargets

	// Notification on backup failure
	notify?: #NotifyConfig
}

#RetentionPolicy: {
	keepDaily:   int | *7
	keepWeekly:  int | *4
	keepMonthly: int | *6
	keepYearly:  int | *0
}

#BackupTargets: {
	// Local backup (same machine or NAS)
	local: {
		enabled: bool | *true
		path:    string | *"/backup/restic"
	}

	// Offsite backup (cloud storage)
	offsite: {
		enabled:  bool | *false
		provider: *"b2" | "hetzner-storagebox" | "s3"

		if provider == "b2" {
			b2: {
				bucket:    string
				accountId: =~"^secret://"
				accountKey: =~"^secret://"
			}
		}

		if provider == "hetzner-storagebox" {
			hetzner: {
				host:     string
				user:     string
				password: =~"^secret://"
				path:     string | *"/backup"
			}
		}

		if provider == "s3" {
			s3: {
				endpoint:  string
				bucket:    string
				accessKey: =~"^secret://"
				secretKey: =~"^secret://"
				region:    string | *"us-east-1"
			}
		}
	}
}

#NotifyConfig: {
	// Notification on failure
	onFailure: bool | *true

	// Notification channels
	channels: [...#NotifyChannel]
}

#NotifyChannel: {
	type: "email" | "webhook" | "gotify"
	url:  string
}

// Service definitions

#ResticAgentService: {
	name:        "restic-agent"
	displayName: "Restic Backup Agent"
	image:       "restic/restic:0.17.3"
	category:    "backup"

	placement: {
		nodeType: "all"
		strategy: "daemonset"
	}

	volumes: [
		{host: "/backup", path: "/backup", type: "bind"},
		{host: "/var/lib/docker/volumes", path: "/source/docker-volumes", type: "bind", readOnly: true},
		{name: "restic-cache", path: "/root/.cache/restic", type: "volume"},
	]

	environment: {
		RESTIC_REPOSITORY: string
		RESTIC_PASSWORD:   string | *""
	}
}

// #Outputs defines what this add-on exports
#Outputs: {
	localRepoPath:   string | *"/backup/restic"
	offsiteEnabled:  bool
	lastBackup?:     string
	nextScheduled?:  string
}

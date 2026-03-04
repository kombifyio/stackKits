// Package pocketid — PocketID OIDC identity provider module.
//
// Self-hosted OpenID Connect provider for SSO.
// Requires Traefik for ingress routing.
package pocketid

import "github.com/kombifyio/stackkits/base"

Contract: base.#ModuleContract & {
	metadata: {
		name:        "pocketid"
		displayName: "PocketID"
		version:     "1.0.0"
		layer:       "L2-platform-identity"
		description: "Self-hosted OIDC provider for single sign-on with passkeys"
	}

	requires: {
		services: {
			traefik: {
				minVersion: "3.0"
				provides: ["reverse-proxy"]
			}
		}
		infrastructure: {
			docker:            true
			persistentStorage: true
			network:           "shared"
		}
	}

	provides: {
		capabilities: {
			"oidc":              true
			"identity-provider": true
			"sso":               true
			"passkeys":          true
		}
		endpoints: {
			ui: {
				url:         "https://id.{{.domain}}"
				description: "PocketID admin and login UI"
			}
			wellknown: {
				url:         "http://pocketid:80/.well-known/openid-configuration"
				internal:    true
				description: "OIDC discovery endpoint"
			}
		}
	}

	settings: {
		perma: {
			encryptionKey: string
		}
		flexible: {
			trustProxy: *true | bool
			logLevel:   *"info" | "debug" | "warn" | "error"
		}
	}

	contexts: {
		local: {
			_trustProxy: true
		}
		cloud: {
			_trustProxy: true
		}
		pi: {
			_trustProxy: true
		}
	}

	services: pocketid: base.#ServiceDefinition & {
		name:     "pocketid"
		type:     "auth"
		image:    "ghcr.io/pocket-id/pocket-id"
		tag:      "v1"
		required: false
		status:   "implemented"
		needs: ["traefik"]

		placement: {
			nodeType: "all"
			strategy: "single"
		}

		network: {
			traefik: {
				enabled: true
				rule:    "Host(`id.{{.domain}}`)"
				port:    80
			}
			networks: ["base_net"]
		}

		volumes: [
			{
				source:      "pocketid-data"
				target:      "/app/backend/data"
				type:        "volume"
				backup:      true
				description: "PocketID database and config"
			},
		]

		environment: {
			TZ:             "{{.timezone}}"
			PUBLIC_APP_URL: "https://id.{{.domain}}"
			TRUST_PROXY:    "true"
		}

		healthCheck: {
			enabled: true
			http: {
				path:   "/api/health"
				port:   80
				scheme: "http"
			}
			interval: "30s"
			timeout:  "5s"
			retries:  3
		}

		resources: {
			memory:    "256m"
			memoryMax: "512m"
			cpus:      0.5
		}

		security: {
			noNewPrivileges: true
			capDrop: ["ALL"]
		}

		labels: {
			"traefik.enable":                                          "true"
			"traefik.http.routers.pocketid.rule":                      "Host(`id.{{.domain}}`)"
			"traefik.http.routers.pocketid.entrypoints":               "web"
			"traefik.http.services.pocketid.loadbalancer.server.port": "80"
		}

		output: {
			url:         "https://id.{{.domain}}"
			description: "PocketID OIDC provider"
		}
	}
}

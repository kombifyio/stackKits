# kombify.me Integration Guide

> For coding agents and developers integrating StackKits or kombify Stack services with kombify.me.

## What is kombify.me?

kombify.me is a wildcard subdomain tunnel service — the kombify equivalent of traefik.me or ngrok. It gives any homelab service a permanent, publicly reachable HTTPS URL at `*.kombify.me` without requiring the user to manage domains, certificates, or port forwarding.

**Architecture:**
- **Gateway** (`ca-kombify-me-prod`, Azure Container App): receives all `*.kombify.me` traffic, manages tunnel registry
- **Agent** (binary on homelab/VPS): opens a WebSocket control channel to the gateway, forwards HTTP requests to local services

---

## Subdomain Naming Convention

### Auto-registered (via API)

| Kind | Pattern | Example |
|------|---------|---------|
| SaaS base | `{homelab}-{userid}.kombify.me` | `mylab-u8f3k2.kombify.me` |
| SaaS service | `{homelab}-{userid}-{service}.kombify.me` | `mylab-u8f3k2-grafana.kombify.me` |
| Self-hosted base | `sh-{homelab}-{fingerprint}.kombify.me` | `sh-mylab-a1b2c3.kombify.me` |
| Self-hosted service | `sh-{homelab}-{fingerprint}-{service}.kombify.me` | `sh-mylab-a1b2c3-grafana.kombify.me` |

Rules:
- Max 63 characters total
- Lowercase alphanumeric + hyphens only
- Reserved names blocked: `api`, `www`, `admin`, `mail`, `status`, `docs`, `app`, `dashboard`, etc.

---

## API Reference

**Base URL:** `https://ca-kombify-me-prod.gentlemoss-1ad74075.westeurope.azurecontainerapps.io/_kombify/api`

> Note: once `kombify.me` bare domain DNS is pointed at AFD, use `https://kombify.me/_kombify/api`

**Via Kong (kombify Stack internal):** `https://api.kombify.io/v1/subdomains/*`

### Register a user account

```bash
curl -X POST {BASE_URL}/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"secret","name":"My Lab"}'
```

Response includes `api_key` — **returned only once, store it immediately**.

### Login

```bash
curl -X POST {BASE_URL}/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"secret"}'
```

Response includes `token` (JWT) and `user_id`.

### Auto-register a subdomain

```bash
curl -X POST {BASE_URL}/auto-register \
  -H "X-Kombify-API-Key: kbi_<your_api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "homelab_name": "mylab",
    "kind": "saas",
    "user_id_suffix": "u8f3k2"
  }'
```

`kind` values: `saas` | `selfhosted`

Response:
```json
{
  "subdomain": "mylab-u8f3k2",
  "full_domain": "mylab-u8f3k2.kombify.me",
  "target_type": "tunnel",
  "status": "active"
}
```

### Register a service subdomain

```bash
curl -X POST {BASE_URL}/auto-register-service \
  -H "X-Kombify-API-Key: kbi_<your_api_key>" \
  -H "Content-Type: application/json" \
  -d '{
    "base_subdomain": "mylab-u8f3k2",
    "service_name": "grafana",
    "expose": true
  }'
```

Response includes `full_domain: "mylab-u8f3k2-grafana.kombify.me"`.

### List subdomains

```bash
curl {BASE_URL}/subdomains \
  -H "X-Kombify-API-Key: kbi_<your_api_key>"
```

### Get subdomain info

```bash
curl {BASE_URL}/subdomains/mylab-u8f3k2 \
  -H "X-Kombify-API-Key: kbi_<your_api_key>"
```

### Update subdomain (expose/hide a service)

```bash
curl -X PUT {BASE_URL}/subdomains/mylab-u8f3k2-grafana \
  -H "X-Kombify-API-Key: kbi_<your_api_key>" \
  -H "Content-Type: application/json" \
  -d '{"exposed": true, "status": "active"}'
```

`status` values: `active` | `inactive`

---

## Agent Setup

### Download / build

```bash
# Pre-built Linux amd64 (from kombify-Me repo)
curl -L https://github.com/KombiverseLabs/kombify-Me/releases/latest/download/agent-linux-amd64 -o agent
chmod +x agent

# Or build from source (requires Go 1.24+)
go build -o agent ./cmd/agent
```

### Config file (`agent.yaml`)

```yaml
# Gateway WebSocket endpoint — do NOT include /_kombify/tunnel (agent appends it)
gateway_url: wss://ca-kombify-me-prod.gentlemoss-1ad74075.westeurope.azurecontainerapps.io

# API key from registration (kbi_ prefix)
api_key: kbi_<your_api_key>

tunnels:
  - subdomain: mylab-u8f3k2         # must already exist in the registry
    local_addr: http://127.0.0.1:80  # where the local service listens
    protocol: http

  - subdomain: mylab-u8f3k2-grafana
    local_addr: http://127.0.0.1:3000
    protocol: http
```

**Critical**: `gateway_url` must NOT include `/_kombify/tunnel` — the agent appends it automatically. Using the wrong URL causes a doubled path and connection failure.

### Run

```bash
./agent -config agent.yaml
```

Expected startup logs:
```
INF connecting to gateway url=wss://.../_kombify/tunnel
INF connected to gateway tunnels=2
```

### Systemd service (Linux)

```ini
# ~/.config/systemd/user/kombify-agent.service
[Unit]
Description=kombify.me Agent
After=network.target

[Service]
ExecStart=/home/user/agent -config /home/user/agent.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now kombify-agent
loginctl enable-linger $USER   # persist after logout
```

---

## How Traffic Flows

```
Browser → https://mylab-u8f3k2.kombify.me/path
  → AFD (afd-kombify-prod, wildcard *.kombify.me)
  → Container App ca-kombify-me-prod (gateway)
    → looks up subdomain "mylab-u8f3k2" in DB
    → sends HTTP request over WebSocket tunnel
      → Agent on homelab receives request
      → forwards to http://127.0.0.1:80/path
      → returns response up through tunnel
  → Browser receives response
```

The `Host` header the agent receives is always `{subdomain}.kombify.me` (canonical form), regardless of what AFD sends to the origin. The agent matches requests using `strings.HasPrefix(req.Host, subdomain+".")`.

---

## Security Model

- **API keys**: prefixed `kbi_`, hashed (SHA-256) at rest. Returned only once at registration — not recoverable.
- **Service subdomains**: `exposed: false` by default — traffic returns 403 until explicitly exposed.
- **Body size limit**: 10 MB per tunnelled request.
- **Tunnel timeout**: 30 seconds per request.

---

## StackKit Integration Pattern

When a StackKit is deployed and needs a public URL:

1. **On first deploy**: call `/auto-register` with `homelab_name` + `user_id_suffix` derived from the stack's metadata → get base subdomain
2. **For each service**: call `/auto-register-service` with `service_name` matching the StackKit service definition → set `expose: true`
3. **Write `agent.yaml`**: generated from the subdomain list, injected into the homelab as a StackKit config file
4. **Start agent**: run as a systemd user service alongside the stack

The base subdomain (`mylab-u8f3k2.kombify.me`) can serve as the stack's management dashboard URL. Individual services get their own subdomain (`mylab-u8f3k2-grafana.kombify.me`, etc.).

---

## Health Check

```bash
curl https://ca-kombify-me-prod.gentlemoss-1ad74075.westeurope.azurecontainerapps.io/_kombify/health
# {"status":"ok","active_tunnels":N}
```

---

## Live Demo

`https://demolab-e2etest-demo.kombify.me` — a Node.js service running on `srv1161760` via systemd, tunnelled through kombify.me. Shows the accessed URL, host, protocol, and demonstrates Zitadel PKCE auth flow.

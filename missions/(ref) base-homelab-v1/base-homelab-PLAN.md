# Base Homelab StackKit - Planning Document

> **Last Updated:** 2026-01-29  
> **Status:** Living Document  
> **Purpose:** Brainstorming, improvement ideas, and development planning  
> **Related:** [base-homelab-DEFINITION.md](./base-homelab-DEFINITION.md) (golden template)

---

## 1. Current Functionality Overview

### 1.1 What Base Homelab Does Today

The **base-homelab** StackKit enables users to deploy a complete single-server homelab environment with:

| Capability | Description |
|------------|-------------|
| **Single-Node Deployment** | One server (local or cloud VPS) running all services |
| **Docker-Based Platform** | All services run as Docker containers |
| **Reverse Proxy** | Traefik v3 with automatic HTTPS (Let's Encrypt) |
| **PaaS Platform** | Dokploy or Coolify for deploying user applications |
| **Monitoring** | Uptime Kuma (uptime) or Beszel (metrics) |
| **Container Management** | Dozzle (logs), Dockge (compose), Portainer (full management) |
| **Infrastructure-as-Code** | OpenTofu for provisioning and state management |
| **Pre-Validated Configs** | CUE schemas prevent invalid configurations |

### 1.2 Supported Variants

| Variant | PaaS | Monitoring | Best For |
|---------|------|------------|----------|
| **default** | Dokploy | Uptime Kuma | No domain, local network |
| **coolify** | Coolify | Uptime Kuma | Own domain, Git deploys |
| **beszel** | Dokploy | Beszel | Server metrics focus |
| **minimal** | None (Dockge) | Netdata | Classic Docker management |

### 1.3 Deployment Modes

| Mode | Engine | Use Case |
|------|--------|----------|
| **simple** | OpenTofu only | Quick deployments, single-stack |
| **advanced** | OpenTofu + Terramate | Drift detection, multi-stack orchestration |

---

## 2. End User Value Proposition

### 2.1 Target Users

| Persona | Description | Needs |
|---------|-------------|-------|
| **Homelab Beginner** | First homelab, wants to self-host | Simple setup, good defaults |
| **Developer** | Needs staging/dev environment | Fast iteration, app deployment |
| **Self-Hoster** | Runs personal services | Reliability, monitoring, backups |
| **Small Team** | 2-5 people sharing services | Easy management, access control |

### 2.2 What Users Achieve

1. **5-Minute Setup** - From zero to running homelab in 5 minutes
2. **Deploy Applications** - Use Dokploy/Coolify like Vercel/Heroku
3. **Monitor Services** - Know when things break before users complain
4. **Secure Access** - HTTPS everywhere with valid certificates
5. **No Expertise Required** - No need to learn Docker, Terraform, Traefik in depth

### 2.3 Key Differentiators

| Traditional Approach | StackKits Approach |
|---------------------|-------------------|
| Learn Docker, Compose, Traefik, SSL | Use pre-built templates |
| Copy configs from GitHub, adapt manually | `stackkit init`, customize YAML |
| Debug SSL issues, port conflicts | Pre-validated configurations |
| No monitoring unless you set it up | Monitoring included by default |
| Hours/days to get working | Minutes to deploy |

---

## 3. Current Limitations

### 3.1 Technical Limitations

| Limitation | Impact | Mitigation Path |
|------------|--------|-----------------|
| Single-node only | No HA, single point of failure | ha-homelab StackKit (v1.2) |
| No cloud providers | Can't provision cloud VMs | Add Hetzner, DO in v1.1 |
| No VPN overlay | Services LAN-only or public | Tailscale/Headscale add-on |
| Docker only | No Kubernetes option | K8s in v2.0 |

### 3.2 Operational Limitations

| Limitation | Impact | Mitigation Path |
|------------|--------|-----------------|
| No drift detection | Manual sync required | Wire Terramate (v1.1) |
| No rollback | Recovery is manual | State-based rollback |
| No updates | Manual container updates | Auto-update add-on |
| No backups | Data loss risk | Backup add-on |

---

## 4. Suggested Improvements and Extensions

### 4.1 Short-Term Improvements (v1.0 → v1.0.1)

#### 4.1.1 CLI Enhancements

| Improvement | Effort | Impact |
|-------------|--------|--------|
| Better error messages | Low | High UX improvement |
| `--json` output for all commands | Low | Automation friendly |
| `stackkit list` command | Low | Discoverability |
| Progress indicators | Low | Better feedback |

#### 4.1.2 Template Improvements

| Improvement | Effort | Impact |
|-------------|--------|--------|
| Add resource labels | Low | Better organization |
| Add container restart policies | Low | Reliability |
| Standardize volume paths | Low | Consistency |
| Add log rotation config | Low | Disk management |

#### 4.1.3 Documentation Improvements

| Improvement | Effort | Impact |
|-------------|--------|--------|
| Step-by-step user guide | Medium | Reduces support burden |
| Troubleshooting guide | Medium | Self-service debugging |
| Video walkthrough | Medium | Different learning styles |
| FAQ section | Low | Common questions |

---

### 4.2 Medium-Term Improvements (v1.1)

#### 4.2.1 Add-On System

Create modular add-ons that extend base functionality:

| Add-On | Description | Priority |
|--------|-------------|----------|
| **backup** | Automated backups with Restic/Borg | High |
| **auth** | Centralized auth with Authelia/Authentik | High |
| **vpn** | Tailscale/Headscale overlay | High |
| **notifications** | Alerts via Telegram/Discord/Slack | Medium |
| **dns** | Pi-hole/AdGuard Home | Medium |
| **logging** | Loki + Promtail stack | Medium |

#### 4.2.2 Drift Detection

| Feature | Description |
|---------|-------------|
| `stackkit drift` | Detect infrastructure drift |
| Auto-remediation | Option to auto-fix drift |
| Scheduled checks | Cron-based drift detection |
| Notifications | Alert on drift detected |

#### 4.2.3 Multi-Variant Testing

| Feature | Description |
|---------|-------------|
| CI variant matrix | Test all variants in CI |
| Variant migration | Switch variants without redeploy |
| Variant comparison | Document trade-offs |

---

### 4.3 Long-Term Improvements (v1.2+)

#### 4.3.1 High Availability Path

| Feature | Target |
|---------|--------|
| Docker Swarm support | v1.2 |
| Multi-node deployment | v1.2 |
| Shared storage (NFS/GlusterFS) | v1.2 |
| Load balancing | v1.2 |

#### 4.3.2 Kubernetes Path

| Feature | Target |
|---------|--------|
| K3s platform layer | v2.0 |
| Kubernetes service definitions | v2.0 |
| Migration tooling (Docker → K8s) | v2.0 |

#### 4.3.3 API Module

| Feature | Target |
|---------|--------|
| REST API server | v2.0 |
| Remote management | v2.0 |
| Multi-tenant support | v2.0 |
| Web UI backend | v2.0 |

---

## 5. Service Expansion Ideas

### 5.1 New Service Categories

| Category | Services | Priority |
|----------|----------|----------|
| **AI/ML** | Ollama, LocalAI, Open WebUI | High (trending) |
| **Media** | Jellyfin, Plex, *arr stack | Medium |
| **Productivity** | Nextcloud, Immich, Paperless | Medium |
| **Dev Tools** | Gitea, DroneCI, n8n | Medium |
| **Smart Home** | Home Assistant, Node-RED | Low |
| **Gaming** | Game servers, Pterodactyl | Low |

### 5.2 Service Definition Improvements

| Improvement | Description |
|-------------|-------------|
| Version pinning | Pin specific versions, not `latest` |
| Update channels | stable/beta/canary per service |
| Resource profiles | low/medium/high resource configs |
| Custom health checks | Service-specific health validation |

---

## 6. User Experience Improvements

### 6.1 Setup Experience

| Current | Proposed |
|---------|----------|
| Edit YAML manually | Interactive wizard |
| Copy-paste passwords | Auto-generate secrets |
| Manual IP entry | Network discovery |
| Read README | Guided tour in CLI |

### 6.2 Ongoing Operations

| Current | Proposed |
|---------|----------|
| `docker ps` for status | `stackkit status` with health |
| Manual log checking | Centralized logging view |
| No alerts | Built-in alerting |
| Manual updates | `stackkit update` command |

### 6.3 Recovery Experience

| Current | Proposed |
|---------|----------|
| Manual rollback | `stackkit rollback` |
| No backup | Built-in backup schedule |
| No disaster recovery | DR runbook + automation |

---

## 7. Integration Ideas

### 7.1 External Integrations

| Integration | Type | Description |
|-------------|------|-------------|
| **GitHub Actions** | CI/CD | Auto-deploy on push |
| **VS Code Extension** | Dev | Edit specs with IntelliSense |
| **Terraform Cloud** | State | Remote state management |
| **Prometheus** | Monitoring | Metrics federation |
| **Grafana Cloud** | Dashboards | Hosted dashboards |

### 7.2 Platform Integrations

| Platform | Integration Type |
|----------|-----------------|
| **Hetzner Cloud** | Provision VMs |
| **DigitalOcean** | Provision Droplets |
| **Proxmox** | Provision VMs/LXC |
| **Tailscale** | VPN overlay |
| **Cloudflare** | DNS + Tunnel |

---

## 8. Technical Debt to Address

### 8.1 Code Quality

| Item | Location | Priority |
|------|----------|----------|
| Structured logging | `internal/*` | High |
| Error handling consistency | `cmd/stackkit` | High |
| Context propagation | All packages | Medium |
| Test coverage | All packages | High |

### 8.2 Schema Quality

| Item | Location | Priority |
|------|----------|----------|
| Fix coolify variant | `stackfile.cue` | High |
| Complete observability schema | `base/observability.cue` | Medium |
| Add addon schema | `base/addon.cue` | Medium |
| Standardize comments | All CUE files | Low |

### 8.3 Template Quality

| Item | Location | Priority |
|------|----------|----------|
| Add lifecycle rules | `main.tf` | Medium |
| Add tagging strategy | `main.tf` | Low |
| Remote state config | New file | Medium |
| Terramate setup | `templates/advanced/` | Medium |

---

## 9. Brainstorming: Future Directions

### 9.1 AI-Powered Features

- **Auto-configuration** - AI suggests optimal settings based on resources
- **Troubleshooting assistant** - AI helps diagnose issues
- **Capacity planning** - AI predicts resource needs
- **Service recommendations** - AI suggests services based on usage

### 9.2 Community Features

- **Stack sharing** - Share configurations publicly
- **Template marketplace** - Community-contributed variants
- **Integration library** - Community add-ons
- **Success stories** - Case studies and examples

### 9.3 Enterprise Features

- **Multi-environment** - Dev/staging/prod pipelines
- **RBAC** - Role-based access control
- **Audit logging** - Compliance-ready logs
- **Policy engine** - OPA-based policy enforcement

---

## 10. Open Questions

### 10.1 Architecture Questions

1. Should we support multiple PaaS simultaneously? (Dokploy + Coolify)
2. How do we handle service conflicts? (Same port, same name)
3. Should variants be composable? (default + beszel monitoring)
4. How do we version service definitions separately from StackKit?

### 10.2 User Experience Questions

1. What's the right balance between simplicity and flexibility?
2. Should we auto-detect optimal settings or ask users?
3. How do we handle upgrades between StackKit versions?
4. What's the support model for community vs. official services?

### 10.3 Technical Questions

1. Should we generate Docker Compose OR OpenTofu, not both?
2. How do we handle secrets in a secure, portable way?
3. Should CUE validation run at runtime or only at generation time?
4. How do we test infrastructure changes without affecting production?

---

## 11. Success Metrics

### 11.1 User Success

| Metric | Target | Current |
|--------|--------|---------|
| Time to first deploy | < 5 min | ~10 min |
| First-try success rate | > 90% | Unknown |
| Documentation rating | 4.5/5 | Unknown |
| Support ticket volume | < 10/week | Unknown |

### 11.2 Technical Success

| Metric | Target | Current |
|--------|--------|---------|
| Test coverage | > 80% | < 40% |
| CI pass rate | > 95% | ~90% |
| CUE validation errors | 0 | 0 ✅ |
| Critical bugs | 0 | Unknown |

### 11.3 Adoption Success

| Metric | Target | Current |
|--------|--------|---------|
| GitHub stars | 1000 | N/A |
| Active deployments | 500 | N/A |
| Community contributors | 10 | N/A |
| StackKits created | 5 | 3 |

---

## 12. Roadmap Alignment

| This Planning | Roadmap Target |
|---------------|----------------|
| Short-term improvements | v1.0 Release |
| Add-on system | v1.1 |
| Drift detection | v1.1 |
| Multi-node | v1.2 |
| Kubernetes | v2.0 |
| API module | v2.0 |

See [ROADMAP.md](../../ROADMAP.md) for full release schedule.

---

## Appendix: Related Documents

- [base-homelab-DEFINITION.md](./base-homelab-DEFINITION.md) - Golden template (source of truth)
- [base-homelab-REVIEW.md](./base-homelab-REVIEW.md) - Current state assessment
- [base-homelab-VALIDATION.md](./base-homelab-VALIDATION.md) - Validation requirements
- [../../ROADMAP.md](../../ROADMAP.md) - Release roadmap
- [../../TARGET_STATE.md](../../TARGET_STATE.md) - Product vision

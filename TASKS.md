# StackKits — Master Task List

> **Last Updated**: 2026-02-23
> **Focus**: Base Kit production-readiness
> **Architecture**: v4 (StackKit + Context + Add-Ons)

Status: `[ ]` open, `[~]` in progress, `[x]` done, `[!]` blocked

---

## EPIC 0: Cleanup & Doc Hygiene (DONE)

> **Goal**: Remove outdated/contradictory docs. Single source of truth per topic.

### E0.1: Delete Outdated Docs

Files **deleted** (2026-02-23):

- [x] `docs/NETWORKING_STANDARDS.md` — Outdated, superseded by Traefik-first domain routing
- [x] `docs/TARGET_STATE.md` — Pre-v4, superseded by ARCHITECTURE_V4 + ROADMAP
- [x] `docs/Cleanup-Plan.md` — Completed, superseded by TASKS.md
- [x] `docs/ADMIN_MIGRATION_PLAN.md` — Pre-v4, no longer relevant
- [x] `docs/AZURE_WEBSITE_DEPLOYMENT.md` — Not StackKits scope
- [x] `docs/Das Digitale Zuhause*.md` — Content preserved in Use Case Epics (UC1-UC10) below
- [x] `docs/EVALUATION_REPORT_2026-02-07.md` — Historical, findings absorbed into ROADMAP
- [x] `docs/templates.md` — References old variant-based templates
- [x] `docs/_archive/` — Entire directory (30+ pre-v4 files)
- [x] `docs/business/` — Business docs, not StackKits scope

### E0.2: Update Implementation Status in Architecture Docs

- [ ] **IDENTITY-STACKKITS.md** Appendix — Update to reflect 25% completion
- [ ] **NETWORK-SECURITY-STACKKITS_1.md** Appendix B — Update to reflect 25% completion

### E0.3: Update Active Docs

- [ ] `docs/ROADMAP.md` — Mark completed items
- [ ] `docs/TESTING.md` — Update for module test infrastructure
- [ ] `docs/README.md` — Update doc index

---

## EPIC 1: Foundation — Modular Architecture (DONE)

### E1.1: CUE Module Contract
- [x] Define `#ModuleContract` schema in `base/module.cue`
- [x] Define metadata, requires, provides, settings, contexts, services
- [ ] Formalize `#DependencySpec` validation (cross-module reference checks)
- [ ] Formalize `#SettingsClassification` (perma vs flexible enforcement)
- [x] Validate schema: `cue vet ./base/...`

### E1.2: Module Directory Structure (12 Modules)
- [x] `modules/traefik/` (module.cue + reference-compose + integration test)
- [x] `modules/tinyauth/` (module.cue + reference-compose + integration test)
- [x] `modules/pocketid/` (module.cue + reference-compose + integration test)
- [x] `modules/dokploy/` (module.cue + reference-compose + integration test, 3 services)
- [x] `modules/uptime-kuma/` (module.cue + reference-compose + integration test)
- [x] `modules/dozzle/` (module.cue + reference-compose + integration test)
- [x] `modules/whoami/` (module.cue + reference-compose + integration test)
- [x] `modules/dashboard/` (module.cue + reference-compose + integration test)
- [x] `modules/socket-proxy/` (module.cue + reference-compose + integration test, 11 tests)
- [x] `modules/crowdsec/` (module.cue + reference-compose + integration test, 10 tests)
- [x] `modules/lldap/` (module.cue + reference-compose + integration test, 11 tests)
- [x] `modules/step-ca/` (module.cue + reference-compose + integration test, 14 tests)

### E1.3: Reference Compose + Integration Tests
- [x] All 8 modules have reference-compose + integration tests
- [x] `modules/_integration/full-stack-compose.yml` (all modules together)
- [x] `modules/_integration/integration_test.sh` (~25 tests)

### E1.4: TinyAuth v4 (VERIFIED E2E 2026-02-22)
- [x] ForwardAuth 401 for API clients, 307 redirect for browsers
- [x] Docker socket mount for label-based access control
- [x] Health check works, configuration proven in E2E

---

## EPIC 2: L1 Foundation — Host OS Security (0% implemented)

> **Goal**: Secure the host OS before any containers run. Per NETWORK-SECURITY-STACKKITS_1.md §4.1, §5, §10.
> **Layer**: L1 Foundation — always deployed, CUE-driven via `base/security.cue`

### E2.1: SSH Hardening
- [ ] CUE schema in `base/security.cue`: SSH config block
  - `permit_root_login: false`
  - `password_authentication: false` (key-only)
  - `max_auth_tries: 3`
  - `x11_forwarding: false`, `allow_agent_forwarding: false`
  - `client_alive_interval: 300`, `client_alive_count_max: 2`
- [ ] OpenTofu template: write `/etc/ssh/sshd_config` + restart sshd
- [ ] Integration test: verify SSH config applied after `stackkit apply`

### E2.2: Firewall (Context-Dependent)
- [ ] CUE schema: firewall rules per context (`local`, `cloud`, `pi`)
- [ ] `local` context: UFW + ufw-docker, bind container ports to `127.0.0.1`
- [ ] `cloud` context: UFW + DOCKER-USER iptables chain (deny all, allow 80/443)
- [ ] `pi` context: UFW + bind-to-localhost
- [ ] Docker-UFW bypass fix (NETWORK-SECURITY §4.1 — critical vulnerability)
- [ ] Integration test: verify firewall rules active, Docker bypass mitigated

### E2.3: Docker Daemon Hardening
- [ ] CUE schema: daemon.json settings
  - `icc: false` (disable inter-container communication on default bridge)
  - `no-new-privileges: true`
  - `userland-proxy: false`
  - `live-restore: true`
  - `default-address-pools: [172.20.0.0/14, /24]` (avoid VLAN/VPN conflicts)
  - Log config: `json-file`, `max-size: 10m`, `max-file: 3`
- [ ] OpenTofu template: write `/etc/docker/daemon.json` + restart Docker
- [ ] Integration test: verify daemon config applied

### E2.4: Automatic Security Updates
- [ ] CUE schema: unattended-upgrades config
  - `security_only: true`
  - `auto_reboot: false` (operator controls reboot)
  - Notification via ntfy or email
- [ ] OpenTofu template: install + configure unattended-upgrades
- [ ] Integration test: verify unattended-upgrades active

### E2.5: Fail2ban (SSH Protection)
- [ ] CUE schema: Fail2ban config
  - `sshd: enabled, maxretry: 3, bantime: 3600, findtime: 600`
- [ ] OpenTofu template: install + configure Fail2ban
- [ ] Integration test: verify Fail2ban running, SSH jail active

---

## EPIC 3: L2 Platform Security (DONE 2026-02-23)

> **Goal**: Implement platform-level security controls. Per NETWORK-SECURITY-STACKKITS_1.md §4.2, §6, §7.
> **Layer**: L2 Platform — always deployed alongside services

### E3.1: Docker Socket Proxy (DONE 2026-02-23)
> **Priority**: P0 — Eliminates root-equivalent socket exposure
- [x] Module CUE definition: `modules/socket-proxy/module.cue` (Tecnativa, read-only API)
- [x] Reference compose + integration test (11 tests)
- [x] Traefik uses socket-proxy (`--providers.docker.endpoint=tcp://socket-proxy:2375`)
- [x] TinyAuth uses socket-proxy (`DOCKER_HOST=tcp://socket-proxy:2375`)
- [x] Dozzle uses socket-proxy (`DOCKER_HOST=tcp://socket-proxy:2375`)
- [x] Dokploy keeps direct docker.sock (needs POST/EXEC for container management)
- [x] Socket-proxy is the ONLY service mounting docker.sock (except Dokploy)
- [x] Full-stack composition test updated

### E3.2: Container Hardening Defaults (DONE 2026-02-23)
> **Priority**: P0 — All containers must have security constraints
- [x] `security_opt: no-new-privileges` on ALL 11 containers
- [x] `cap_drop: ALL` on ALL 11 containers
- [x] `cap_add: NET_BIND_SERVICE` only on Traefik
- [x] `read_only: true` on 7 services (socket-proxy, traefik, tinyauth, dozzle, whoami, dashboard, redis)
- [x] `mem_limit` on ALL 11 containers
- [x] `tmpfs` where needed for read-only containers
- [x] Full-stack composition test: 11 no-new-privileges tests + 11 cap_drop tests + 7 read_only tests + 11 mem_limit tests
- [x] Define in CUE `base/security.cue` (formalize hardening schema) — `#ContainerSecurityContext`, `#ContainerResourceLimits`
- [x] Apply to all individual module reference-composes (all 11 modules hardened)

### E3.3: Network Isolation (DONE 2026-02-23)
> **Priority**: P0 — Prevent lateral movement
- [x] Three networks: `frontend` (bridge), `backend` (internal), `socket-proxy-net` (internal)
- [x] Postgres + Redis on `backend` only (not reachable from frontend)
- [x] Socket-proxy on `socket-proxy-net` only (not reachable from frontend directly)
- [x] TinyAuth, Dozzle, Traefik bridge frontend + socket-proxy-net
- [x] Dokploy bridges frontend + backend
- [x] Full-stack composition test: 7 network isolation tests
- [ ] Define standard networks in CUE `base/network.cue` (formalize network schema — lower priority)

### E3.4: Security Headers Middleware (DONE 2026-02-23)
> **Priority**: P1
- [x] Middleware defined via Traefik labels (per NETWORK-SECURITY §7.1):
  - HSTS (31536000s, includeSubdomains, preload)
  - Content-Type-Nosniff, Frame-Deny
  - Referrer-Policy: strict-origin-when-cross-origin
  - Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()
  - COOP: same-origin, CORP: same-origin
  - X-Permitted-Cross-Domain-Policies: none
- [x] Applied to ALL routes via middleware chain
- [x] Integration test: 7 header verification tests
- [ ] Formalize in CUE `base/network.cue` (middleware schema)

### E3.5: Rate Limiting (DONE 2026-02-23)
> **Priority**: P1
- [x] Traefik rate-limit middleware via labels: `average: 100, burst: 200, period: 1s`
- [x] Applied to ALL routes via middleware chain
- [x] Middleware chain order: rate-limit → security-headers → tinyauth (per §7.4)
- [ ] Formalize in CUE `base/network.cue` (middleware schema)

### E3.6: CrowdSec Integration (IDS + WAF) (DONE 2026-02-23)
> **Priority**: P1 — Behavioral intrusion detection
- [x] Module CUE definition: `modules/crowdsec/module.cue`
  - CrowdSec container + Traefik bouncer plugin
  - Collections: traefik, linux, sshd, http-cve, appsec-virtual-patching, appsec-generic-rules
- [x] Reference compose + integration test (10 tests: health, LAPI, bouncer, collections, routing, hardening)
- [x] Middleware chain order: CrowdSec → rate-limit → security-headers → TinyAuth (per §7.4)
- [x] Traefik bouncer plugin config via labels
- [x] AppSec WAF endpoint (port 7422)
- [ ] Integrate into full-stack compose (when ready for production testing)

---

## EPIC 4: L2 Platform Identity (75% implemented)

> **Goal**: Complete the identity stack. Per IDENTITY-STACKKITS.md §2, §3.
> **Working**: TinyAuth (ForwardAuth) + PocketID (OIDC + passkeys) + LLDAP (directory) + Step-CA (PKI)
> **Remaining**: Integration tests (LLDAP→PocketID→TinyAuth chain), mTLS middleware

### E4.1: LLDAP Module (Directory Service) (DONE 2026-02-23)
> Source of truth for users & groups. Required for RBAC.
- [x] Module CUE definition: `modules/lldap/module.cue`
  - Layer: L1-foundation
  - Image: lldap/lldap
  - Provides: `directory`, `user-groups`, `ldap`, `user-storage`
  - Requires: traefik (for web UI routing)
  - Settings perma: admin password, JWT secret, base DN
  - Settings flexible: LDAP port, HTTP port, LDAPS port
- [x] Reference compose + integration test (11 tests: health, web UI, LDAP port, admin auth, hardening, routing)
- [ ] Default groups: `homelab_owner`, `homelab_operator`, `homelab_developer`, `homelab_viewer`
- [ ] Integration with PocketID: LDAP user sync
- [ ] Integration with TinyAuth: LLDAP group claims in OIDC tokens
- [ ] Full-stack test: create user in LLDAP -> login via PocketID -> TinyAuth sees group claims

### E4.2: Step-CA Module (PKI & mTLS) (DONE 2026-02-23)
> Certificate authority for inter-service mTLS and device trust.
- [x] Module CUE definition: `modules/step-ca/module.cue`
  - Layer: L1-foundation
  - Image: smallstep/step-ca
  - Provides: `pki`, `certificate-authority`, `acme`, `mtls`
  - Requires: nothing (foundational)
  - Settings perma: CA name, password, DNS names
  - Settings flexible: ACME enabled, cert lifetime
- [x] Reference compose + integration test (14 tests: health, CA certs, ACME directory, provisioners, config, hardening, routing)
- [ ] Auto-issue certificates for inter-service communication
- [ ] Traefik integration: ACME resolver with step-ca (TLS termination)
- [ ] Integration test: service-to-service mTLS verified

### E4.3: SOPS + age (Secrets Management) (DONE 2026-02-23)
> Encrypted secrets in Git, no server component needed.
- [x] CUE schema: `#SecretsPolicy`, `#SOPSAgeConfig`, `#SOPSCreationRule`, `#GitleaksConfig` in `base/security.cue`
  - Provider: `sops-age` (default for homelab)
  - age key file location, encrypted file dir, creation rules
- [ ] `stackkit generate` decrypts secrets for deployment (depends on E6: CUE Pipeline)
- [ ] Gitleaks pre-commit hook: prevent accidental secret commits
- [ ] Integration test: encrypted secret -> decrypted at deploy time (depends on E6)

---

## EPIC 5: DNS Security

> **Goal**: Secure DNS resolution. Per NETWORK-SECURITY-STACKKITS_1.md §9.
> **Layer**: L2 Platform

### E5.1: AdGuard Home Module
- [ ] Module CUE definition: `modules/adguard-home/module.cue`
  - DNS filtering, ad/malware blocking
  - Local DNS rewrites (`*.stack.local` -> internal IPs)
  - DNS rebinding protection (critical)
- [ ] Reference compose + integration test
- [ ] Context-dependent upstream: Unbound (local/cloud) or Cloudflare DoH (pi)

### E5.2: Unbound Module
- [ ] Module CUE definition: `modules/unbound/module.cue`
  - Recursive DNS resolver, DNSSEC validation
  - No third-party DNS dependency
- [ ] Reference compose + integration test
- [ ] Chain: AdGuard Home -> Unbound -> root servers

---

## EPIC 6: CUE-Driven Generation Pipeline

> **Goal**: `stackkit generate` reads modules/ and produces per-module OpenTofu fragments.

### E6.1: Bridge Rewrite
- [ ] Rewrite `internal/cue/bridge.go` to read `#ModuleContract` from modules
- [ ] Extract service definitions, dependencies, settings from CUE
- [ ] Generate per-module OpenTofu fragments (not monolithic main.tf)
- [ ] Export `terraform.tfvars.json` from CUE values
- [ ] Remove legacy variant-based extraction

### E6.2: Generator Refactor
- [ ] Refactor `cmd/stackkit/commands/generate.go` to use CUE bridge
- [ ] Generate per-module .tf fragments into `deploy/modules/`
- [ ] Generate shared infrastructure (`providers.tf`, `networks.tf`, `variables.tf`)
- [ ] Validate dependency graph before generation

### E6.3: Composition Engine
- [ ] Read enabled modules from StackKit CUE definition
- [ ] Resolve dependency graph (topological sort)
- [ ] Detect missing/circular dependencies with clear error messages
- [ ] Compute resource requirements (RAM/CPU sum vs node capacity)

---

## EPIC 7: Testing Infrastructure (MOSTLY DONE 2026-02-23)

### E7.1: mise Dev Environment
- [x] `mise run test:module <name>`, `test:modules`, `test:compose`, `test:cue`, `test:all`
- [ ] `mise run test:e2e` (VM-based full deployment)

### E7.2: 4-Level Test Pyramid
- [x] Level 1: CUE schema tests per module (all 12 modules validated)
- [x] Level 2: Reference compose tests per module (all 12 modules have integration tests)
- [x] Security hardening tests in ALL module integration tests (no-new-privileges, cap_drop, mem_limit, read-only)
- [x] All 12 reference-composes have container hardening applied
- [ ] Level 3: Composition tests (`stackkit validate` + `generate` + `tofu plan`)
- [ ] Level 4: E2E tests (`stackkit apply` on VM, full verification)

### E7.3: CI/CD Pipeline
- [x] CUE validation on every PR (base/, base-homelab/, modern-homelab/, all modules/)
- [x] Module integration tests — 12-module matrix (traefik, tinyauth, pocketid, dokploy, uptime-kuma, dozzle, whoami, dashboard, socket-proxy, crowdsec, lldap, step-ca)
- [x] Full-stack composition test (all base kit modules together, ~60 tests)
- [x] ci-passed gate: lint + test + cue-validation + module-tests + composition-test
- [ ] E2E test on main branch (scheduled, needs VM runner)

---

## EPIC 8: StackKit Composition

### E8.1: base-homelab Refactor
> **Depends on**: E6 (CUE generation pipeline)
- [ ] Rewrite `base-homelab/stackfile.cue` to import from `modules/`
- [ ] Update `base-homelab/services.cue` to reference module definitions
- [ ] Verify full deploy: `stackkit generate` + `stackkit apply`

### E8.2: Remove Monolithic Template
- [ ] Delete `base-homelab/templates/simple/main.tf` (1352-line monolith)
- [ ] Replace with per-module fragment templates

---

## EPIC 9: Context System

### E9.1: Context Definitions
- [x] `base/context.cue` — `#ContextDefinition` schema exists
- [ ] `contexts/local.cue` — Local network defaults (Dokploy, self-signed TLS)
- [ ] `contexts/cloud.cue` — Cloud/VPS defaults (Coolify, Let's Encrypt)
- [ ] `contexts/pi.cue` — Raspberry Pi defaults (ARM64, reduced resources)

### E9.2: Context Integration
- [ ] Module context overrides (resource limits, TLS settings)
- [ ] CLI: `stackkit init --context local`
- [ ] Context-driven PaaS selection (Dokploy vs Coolify)

---

## UC1: Private Memories (Photo Gallery)

> **The Product**: A personal photo gallery that feels like Google Photos but runs on your own hardware. Terabytes of space, no subscriptions. Hybrid mode lets you share albums securely via the Cloud Gateway while originals stay home.

### UC1.1: Immich Module
- [ ] Module CUE definition: `modules/immich/module.cue`
  - Layer: L3-application
  - Services: immich-server, immich-machine-learning, immich-redis, immich-postgres
  - Requires: traefik, tinyauth (ForwardAuth protection)
  - Provides: `photo-gallery`, `photo-backup`
  - Settings perma: DB password, upload path
  - Settings flexible: ML model, thumbnail quality, external library paths
- [ ] Reference compose + integration test
- [ ] Storage: local volume for photos + DB volume for metadata
- [ ] GPU passthrough support (optional, for ML acceleration)
- [ ] Mobile app compatibility (Immich app connects to `photos.{domain}`)
- [ ] Intent dependency: user selects "I want photo management" -> system resolves: traefik + tinyauth + immich + storage

### UC1.2: Backup Integration
- [ ] Automated backup of photo library (Restic target)
- [ ] Backup of Immich DB (pg_dump schedule)

---

## UC2: Personal AI (Local LLM)

> **The Product**: A genius assistant that knows your documents but never phones home. Run your own AI with your GPU. Ask "When does the dishwasher warranty expire?" and it finds the answer in your PDFs. Your data never leaves your house.

### UC2.1: Ollama Module
- [ ] Module CUE definition: `modules/ollama/module.cue`
  - Layer: L3-application
  - Image: ollama/ollama
  - Requires: traefik
  - Provides: `llm-inference`, `ai-backend`
  - Settings: model list, GPU device, VRAM limits
- [ ] Reference compose + integration test
- [ ] GPU passthrough: NVIDIA (nvidia-container-toolkit), AMD (ROCm)
- [ ] Context-dependent: `local` with GPU = full models, `pi` = small models only, `cloud` = CPU-only or rented GPU

### UC2.2: Open WebUI Module
- [ ] Module CUE definition: `modules/open-webui/module.cue`
  - Layer: L3-application
  - Requires: traefik, tinyauth, ollama
  - Provides: `ai-chat-ui`
  - Settings: RAG config, document upload path
- [ ] Reference compose + integration test
- [ ] RAG pipeline: upload documents -> vectorize -> query via chat
- [ ] OIDC integration: login via PocketID
- [ ] Intent dependency: "I want local AI" -> ollama + open-webui + traefik + tinyauth

---

## UC3: Private Streaming (Media Server)

> **The Product**: Your own Netflix. Stream your movie collection in 4K to your TV, live-transcode to your tablet on the train. You are the program director. No geo-blocking, no disappearing content.

### UC3.1: Jellyfin Module
- [ ] Module CUE definition: `modules/jellyfin/module.cue`
  - Layer: L3-application
  - Image: jellyfin/jellyfin
  - Requires: traefik, tinyauth
  - Provides: `media-streaming`, `transcoding`
  - Settings: media library paths, hardware transcoding (VAAPI/NVENC), subtitle config
- [ ] Reference compose + integration test
- [ ] GPU passthrough for hardware transcoding
- [ ] External access via tunnel (Cloudflare/Pangolin) or VPN

### UC3.2: Media Automation (*arr Stack)
- [ ] Module CUE definition: `modules/media-automation/module.cue`
  - Services: sonarr, radarr, prowlarr (indexer manager)
  - Layer: L3-application
  - Requires: traefik, tinyauth, jellyfin
  - Provides: `media-management`, `media-automation`
- [ ] Reference compose + integration test
- [ ] Shared media volume between *arr stack and Jellyfin
- [ ] Intent dependency: "I want media streaming" -> jellyfin + (optional: sonarr + radarr + prowlarr) + traefik + tinyauth

---

## UC4: Family Safe (File Sharing & Cloud Storage)

> **The Product**: The central meeting point for all family data. Homework, tax docs, shared projects. Send friends a link to the vacation video — from your own server. Feels like Dropbox, but belongs to you.

### UC4.1: File Sharing Module
- [ ] Module CUE definition: `modules/file-sharing/module.cue`
  - Layer: L3-application
  - Provider selection: Nextcloud (full suite) | OpenCloud (modern, lighter) | Cloudreve (simple)
  - Requires: traefik, tinyauth
  - Provides: `file-sharing`, `cloud-storage`, `webdav`
  - Settings perma: storage backend, DB
  - Settings flexible: max upload size, quota, sharing config
- [ ] Reference compose + integration test (for each provider variant)
- [ ] WebDAV support for desktop/mobile sync
- [ ] Share links with expiration + password
- [ ] OIDC integration with PocketID
- [ ] Intent dependency: "I want file sharing" -> file-sharing + traefik + tinyauth + (postgres or mariadb)

---

## UC5: Digital Fortress (Password Manager)

> **The Product**: Host your own password vault. Devices sync via encrypted connections on your WiFi — or securely tunneled when away. Even if someone steals the server, without your master key it's data salad.

### UC5.1: Vaultwarden Module
- [ ] Module CUE definition: `modules/vaultwarden/module.cue`
  - Layer: L3-application
  - Image: vaultwarden/server
  - Requires: traefik (HTTPS mandatory for WebCrypto API)
  - Provides: `password-manager`, `totp`, `passkey-storage`
  - Settings perma: admin token (hashed), domain
  - Settings flexible: signups enabled/disabled, org creation, SMTP for email
- [ ] Reference compose + integration test
- [ ] WebSocket support (live sync requires WS)
- [ ] Bitwarden client compatibility (browser extension, mobile app, desktop)
- [ ] TLS required (Vaultwarden refuses to serve without HTTPS)
- [ ] Intent dependency: "I want a password manager" -> vaultwarden + traefik

---

## UC6: House Command (Smart Home Hub)

> **The Product**: Control your smart home locally. When the internet goes down, your lights still work. Commands stay in the house — instant response, no cloud detour. Control heating from the office via VPN, but Alexa isn't listening.

### UC6.1: Home Assistant Module
- [ ] Module CUE definition: `modules/home-assistant/module.cue`
  - Layer: L3-application
  - Image: homeassistant/home-assistant
  - Requires: traefik, tinyauth
  - Provides: `smart-home`, `home-automation`
  - Settings: zigbee device path, bluetooth device, network mode
  - Special: may need `network_mode: host` or `privileged` for hardware access (USB, Zigbee, Bluetooth)
- [ ] Reference compose + integration test

### UC6.2: Zigbee2MQTT Module
- [ ] Module CUE definition: `modules/zigbee2mqtt/module.cue`
  - Requires: home-assistant (optional, can work standalone)
  - Provides: `zigbee-bridge`
  - Device passthrough: USB Zigbee coordinator
- [ ] Reference compose + integration test

### UC6.3: Mosquitto Module (MQTT Broker)
- [ ] Module CUE definition: `modules/mosquitto/module.cue`
  - Requires: nothing (foundational for IoT)
  - Provides: `mqtt-broker`
- [ ] Reference compose + integration test
- [ ] Intent dependency: "I want smart home" -> home-assistant + mosquitto + (optional: zigbee2mqtt) + traefik + tinyauth

---

## UC7: Multiplayer Arena (Game Servers)

> **The Product**: Host persistent game worlds for friends. Best performance on your hardware, professional DDoS protection via the hybrid architecture. Friends connect through the Cloud Gateway — your home IP stays hidden.

### UC7.1: Game Server Framework Module
- [ ] Module CUE definition: `modules/gameserver/module.cue`
  - Layer: L3-application
  - Generic framework: game-specific images selected via settings
  - Requires: traefik (for web panel), network access (direct UDP/TCP for game traffic)
  - Provides: `game-server`
  - Settings: game type (minecraft, palworld, valheim, etc.), server config, resource limits
- [ ] Reference compose + integration test (Minecraft as reference game)
- [ ] Port management: game servers need direct port exposure (not just HTTP via Traefik)
- [ ] DDoS mitigation via Cloud Gateway/tunnel
- [ ] Intent dependency: "I want game servers" -> gameserver + (optional: traefik for web panel)

---

## UC8: Code Lab (Developer Platform)

> **The Product**: Your own dev sandbox. Describe your wish, and containers spin up. Git hosting, CI/CD, container registry. Develop like Silicon Valley, on your own hardware. Time Travel lets you reset at any time.

### UC8.1: Gitea Module
- [ ] Module CUE definition: `modules/gitea/module.cue`
  - Layer: L3-application
  - Image: gitea/gitea
  - Requires: traefik, tinyauth
  - Provides: `git-hosting`, `container-registry`
  - Settings: SSH port, LFS, built-in container registry
- [ ] Reference compose + integration test
- [ ] OIDC integration with PocketID (SSO)
- [ ] Built-in CI (Gitea Actions) or external CI

### UC8.2: Woodpecker CI Module
- [ ] Module CUE definition: `modules/woodpecker/module.cue`
  - Layer: L3-application
  - Requires: traefik, tinyauth, gitea (webhook integration)
  - Provides: `ci-cd`, `build-pipeline`
  - Services: woodpecker-server, woodpecker-agent
- [ ] Reference compose + integration test
- [ ] Docker-in-Docker or socket access for building images
- [ ] Intent dependency: "I want a dev platform" -> gitea + woodpecker + traefik + tinyauth

---

## UC9: Office Anywhere (Remote Desktop)

> **The Product**: Stream your full workstation to any device. Sitting in a cafe with a thin laptop but need to render a 4K video? Your homelab streams the computing power directly to your screen. High-performance office in your backpack.

### UC9.1: Apache Guacamole Module
- [ ] Module CUE definition: `modules/guacamole/module.cue`
  - Layer: L3-application
  - Services: guacamole (web frontend), guacd (connection broker), guacamole-postgres
  - Requires: traefik, tinyauth
  - Provides: `remote-desktop`, `vnc-gateway`, `rdp-gateway`
  - Settings: connection targets (RDP/VNC/SSH hosts), recording, MFA
- [ ] Reference compose + integration test
- [ ] OIDC integration with PocketID
- [ ] Protocol support: RDP, VNC, SSH, Telnet
- [ ] Intent dependency: "I want remote desktop" -> guacamole + traefik + tinyauth

---

## UC10: Your Corner of the Internet (Personal Website)

> **The Product**: Publish a portfolio, blog, or project landing page. Host it yourself — your Homelab serves the content, the world sees your professional domain via the Cloud VPS. Total freedom, no platform restrictions, no ads. Your home network stays invisible.

### UC10.1: Web Hosting Module
- [ ] Module CUE definition: `modules/webhost/module.cue`
  - Layer: L3-application
  - Provider selection: static (nginx/caddy) | CMS (Ghost, WordPress) | wiki (WikiJS, BookStack)
  - Requires: traefik
  - Provides: `web-hosting`, `blog`, `static-site`
  - Settings: site type, domain, TLS (Let's Encrypt), build command (for static site generators)
- [ ] Reference compose + integration test
- [ ] Public access: no TinyAuth on this route (public website!)
- [ ] Let's Encrypt auto-cert via Traefik ACME
- [ ] Intent dependency: "I want a website" -> webhost + traefik (no auth)

---

## EPIC 10: Add-On System

> **Goal**: Framework for composable extensions on top of the Base Kit.
> **Depends on**: E6 (Composition Engine)

### E10.1: Add-On Framework
- [ ] Define `#AddOnContract` extending `#ModuleContract` with addon metadata
- [ ] CLI commands: `stackkit addon add/list/remove`
- [ ] Dependency resolution against base kit modules

### E10.2: Monitoring Add-On
- [ ] `addons/monitoring/` — Prometheus + Grafana
- [ ] Integration test: base-homelab + monitoring add-on

### E10.3: Backup Add-On
- [ ] `addons/backup/` — Restic + targets
- [ ] Per-module backup definitions (what to back up per service)

---

## EPIC 11: Demo & Portal (MOSTLY DONE)

### E11.1: Portal
- [x] Portal reworked as end-user deployment dashboard
- [x] Dynamic content via `/api/portal/deployment` and `/api/portal/health`
- [x] Live health polling, services grouped by layer

### E11.2: Orchestrator
- [x] Dev/demo management UI, VM terminal, demo controls

### E11.3: Demo Environment
- [ ] One-command demo launch verified
- [ ] Pre-populated monitoring data
- [ ] Screenshots for marketing

---

## EPIC 12: Multi-Node (Future)

### E12.1: Modern Homelab Kit
- [ ] Docker multi-node, hybrid (local + cloud), Compose per node (no Swarm)

### E12.2: HA Homelab Kit
- [ ] Docker Swarm, 3+ nodes, Keepalived VIP, quorum consensus

---

## EPIC 13: kombify Stack Integration (Future)

### E13.1: Module Packages for Unifier
- [ ] Export `#ModuleContract` as consumable CUE package

### E13.2: Runtime Intelligence
- [ ] Health monitoring + drift detection per module

---

## Priority Order (Production-Readiness Path)

```
E0 (Cleanup)                ← DONE: single source of truth
    |
E2 (L1 Foundation: Host)   ← SSH, firewall, Docker daemon, auto-updates
E3 (L2 Platform Security)  ← Socket proxy, hardening, network isolation, CrowdSec
E4 (L2 Platform Identity)  ← LLDAP, Step-CA, SOPS+age
E5 (DNS Security)           ← AdGuard Home, Unbound
    |
    |  (these ^ secure the platform, then build use cases on top)
    |
UC5 (Password Manager)     ← Simplest use case, 1 container, high value
UC1 (Photos)                ← High demand, complex (4 containers)
UC2 (AI)                    ← High demand, GPU complexity
UC3 (Media)                 ← High demand, transcoding complexity
UC4 (File Sharing)          ← High demand, provider variants
UC10 (Website)              ← Simple, public-facing (no auth)
UC5-UC9 (remaining)         ← Smart Home, Gameserver, Dev, Remote Desktop
    |
E6 (CUE Pipeline)          ← Bridge rewrite, per-module generation
E8 (Composition)            ← base-homelab imports from modules/
E9 (Contexts)               ← local/cloud/pi differentiation
E10 (Add-Ons)               ← Composable extensions
```

E7 (Testing) runs parallel to everything.
Use Cases can start as soon as L2 Platform (E3) is stable.

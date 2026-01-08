# StackKit Architecture Plan v2.1

> **Status:** Draft - Major Revision  
> **Last Updated:** 2025-01-14  
> **Version:** 2.1 (IaC-First Architecture)  
> **Authors:** KombiStack Team

---

## 🚨 ARCHITECTURE DECISION: IaC-FIRST

> **Decision Date:** 2025-01-14  
> **Status:** ✅ APPROVED  
> **Reference:** [IAC_FIRST_ARCHITECTURE.md](IAC_FIRST_ARCHITECTURE.md)

### Core Principle

**Der Worker-Agent ist KEINE Config-Management-Engine**, sondern nur ein "thin layer" der OpenTofu und Terramate Befehle ausführt.

```
┌─────────────────────────────────────────────────────────────┐
│                    FORBIDDEN (Agent-First)                   │
│  ❌ Agent mit SSH-Tunnel → Remote Shell Commands            │
│  ❌ Agent installiert Docker, konfiguriert Firewall         │
│  ❌ Agent führt eigene Health-Checks durch                  │
│  ❌ Drift-Detection via Agent-Logik                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    REQUIRED (IaC-First)                      │
│  ✅ Agent führt NUR aus: tofu init|plan|apply               │
│  ✅ Agent führt NUR aus: terramate run|list                 │
│  ✅ OS-Prep via null_resource + remote-exec                 │
│  ✅ Services via kreuzwerker/docker Provider                │
│  ✅ Drift via tofu plan -detailed-exitcode                  │
└─────────────────────────────────────────────────────────────┘
```

### Warum IaC-First?

| Aspekt | Agent-First (❌) | IaC-First (✅) |
|--------|------------------|----------------|
| State Management | Custom DB | OpenTofu State |
| Drift Detection | Custom Polling | `tofu plan -detailed-exitcode` |
| Rollback | Re-run Scripts | `tofu destroy` / Git History |
| Provider Ecosystem | N/A | 3000+ Terraform Provider |
| Day-2 Operations | Custom Code | Terramate Orchestration |
| Wartung | Eigene Logik | Community-maintained |

### Agent Command Whitelist

```go
// ONLY these commands are allowed
var AllowedCommands = []string{
    "tofu init",
    "tofu plan",
    "tofu apply",
    "tofu destroy",
    "tofu output",
    "terramate run",
    "terramate list",
}
```

### Implementation Reference

- **Templates:** [base/bootstrap/](../base/bootstrap/) - OS-prep, services, variables
- **Schema:** [base/schema/iac_first.cue](../base/schema/iac_first.cue) - CUE validation
- **Network:** [base/network/](../base/network/) - Local and public mode templates
- **Lifecycle:** [base/lifecycle/](../base/lifecycle/) - Drift detection via Terramate

---

## 📋 Executive Summary

Dieses Dokument definiert die **dreistufige StackKit-Architektur** für KombiStack:

```
┌─────────────────────────────────────────────────────────┐
│                    Layer 1: CORE                         │
│  Bootstrap, Security, Users, Network Fundamentals        │
│  (Shared across ALL StackKits)                          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                 Layer 2: PLATFORM                        │
│  ┌─────────────────┐    ┌─────────────────┐             │
│  │     Docker      │    │   Kubernetes    │             │
│  │  apply-only     │    │  apply+orch.    │             │
│  │  local/public   │    │  local/public   │             │
│  └─────────────────┘    └─────────────────┘             │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│               Layer 3: SERVICES + HEALTH                 │
│  Service Definitions, Health Checks, Outputs             │
│  (Platform-specific implementations)                     │
└─────────────────────────────────────────────────────────┘
```

Diese Architektur ermöglicht:
- **Wiederverwendung:** Core-Logic einmal schreiben, überall nutzen
- **Klarheit:** Docker ≠ Kubernetes sind fundamental verschieden
- **Skalierbarkeit:** Vom Single-Node bis zum HA-Cluster
- **User Experience:** Seamless Rollout ohne manuelle Schritte

---

## 🔴 Kritische Issues (Aktueller Stand)

### Issue 1: Service URLs ohne Domain
**Problem:** Aktuelle Templates setzen eine öffentliche Domain voraus.
```cue
output: {
    url: "https://traefik.{{.domain}}"  // Funktioniert nur mit Domain
}
```
**Impact:** Lokale Homelabs ohne Domain können nicht deployt werden.

### Issue 2: Keine OS-Vorbereitung
**Problem:** OpenTofu Templates gehen davon aus, dass Docker bereits installiert ist.
```terraform
provider "docker" {
  host = "unix:///var/run/docker.sock"  // Woher kommt Docker?
}
```
**Impact:** User muss manuell Docker installieren → keine seamless Experience.

### Issue 3: Keine Pre-Flight Checks
**Problem:** Vor dem Rollout wird nicht geprüft ob:
- Ports frei sind
- Genug Ressourcen vorhanden
- OS kompatibel ist
- SSH-Zugang funktioniert

### Issue 4: Keine Post-Rollout Verification
**Problem:** Nach dem Rollout:
- Keine Health-Checks der Services
- Keine Validierung dass alles läuft
- Kein Rollback bei Fehler

### Issue 5: CUE-Definitionen sind "Papier-Tiger"
**Problem:** ~80% der CUE-Definitionen (Security, Firewall, Users, Backup) sind definiert aber nirgends implementiert.

---

## 📊 IST-Analyse: Variabilität & Konfigurierbarkeit

| # | Bereich | Status | Details |
|---|---------|--------|---------|
| 1 | OS Support | ⚠️ Definiert | `ubuntu-24`, `ubuntu-22`, `debian-12` - keine OS-spezifische Logik |
| 2 | Monitoring Tools | ✅ Implementiert | Varianten: Uptime Kuma, Beszel, Netdata |
| 3 | Deployment Modi | ⚠️ Teilweise | Simple (OpenTofu) implementiert, Advanced (Terramate) nicht |
| 4 | Orchestration nach Rollout | ❌ Fehlt | Keine Day-2 Operations |
| 5 | Drift Detection | ❌ Fehlt | Nur als Feature beschrieben |
| 6 | Netzwerk-Modi | ❌ Minimal | Nur Bridge, VPN disabled |
| 7 | TLS/SSL Modi | ❌ Minimal | Nur Let's Encrypt, kein Local Mode |
| 8 | DNS Setup | ❌ Fehlt | Nicht vorhanden |
| 9 | Compute Tiers | ⚠️ Teilweise | Nur Memory-Limits, keine echte Logik |
| 10 | Backup | ❌ Fehlt | Definiert aber nicht implementiert |
| 11 | SSH Hardening | ❌ Fehlt | Definiert aber nicht implementiert |
| 12 | Firewall | ❌ Fehlt | Definiert aber nicht implementiert |
| 13 | User Setup | ❌ Fehlt | Definiert aber nicht implementiert |

---

## 📋 SOLL-Spezifikation: Konfigurierbare Parameter

### Phase 1: Bootstrap (OS-Vorbereitung)

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `bootstrap.mode` | `ssh`, `cloud-init`, `agent` | `agent` | P0 |
| `bootstrap.ssh.user` | string | `root` | P0 |
| `bootstrap.ssh.port` | int | `22` | P0 |
| `bootstrap.ssh.keyPath` | string | `~/.ssh/id_ed25519` | P0 |
| `bootstrap.os.update` | `full`, `security`, `none` | `security` | P1 |
| `bootstrap.os.reboot` | bool | `true` (if kernel update) | P1 |

### Phase 2: System-Konfiguration

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `system.hostname` | string | auto-generated | P0 |
| `system.timezone` | IANA TZ | `UTC` | P1 |
| `system.locale` | string | `en_US.UTF-8` | P2 |
| `system.swap` | `auto`, `2G`, `none` | `auto` | P2 |
| `system.users.admin.name` | string | `kombi` | P0 |
| `system.users.admin.sshKeys` | []string | REQUIRED | P0 |

### Phase 3: Netzwerk

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `network.mode` | `local`, `public`, `hybrid` | `local` | P0 |
| `network.domain` | string | `null` (IP-based) | P0 |
| `network.tls.mode` | `acme`, `self-signed`, `none` | auto-detect | P0 |
| `network.tls.acme.email` | string | required if acme | P0 |
| `network.tls.acme.staging` | bool | `false` | P1 |
| `network.dns.provider` | `cloudflare`, `manual`, `none` | `none` | P1 |
| `network.firewall.enabled` | bool | `true` | P0 |
| `network.firewall.backend` | `ufw`, `firewalld`, `iptables` | auto | P1 |

### Phase 4: Container Runtime

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `container.runtime` | `docker`, `podman` | `docker` | P1 |
| `container.registryMirror` | string | `null` | P2 |
| `container.logDriver` | `json-file`, `journald` | `json-file` | P2 |

### Phase 5: Services

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `services.variant` | `default`, `beszel`, `minimal` | `default` | P0 |
| `services.reverseProxy` | `traefik`, `caddy`, `nginx` | `traefik` | P1 |
| `services.platform` | `dokploy`, `dockge`, `portainer` | per variant | P1 |
| `services.monitoring` | `uptime-kuma`, `beszel`, `netdata` | per variant | P1 |

### Phase 6: Observability

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `observability.logs.retention` | duration | `7d` | P1 |
| `observability.metrics.enabled` | bool | `true` | P1 |
| `observability.backup.enabled` | bool | `true` | P1 |
| `observability.backup.schedule` | cron | `0 3 * * *` | P1 |
| `observability.backup.target` | `local`, `s3`, `b2` | `local` | P1 |

### Phase 7: Security

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `security.ssh.permitRoot` | bool | `false` | P0 |
| `security.ssh.passwordAuth` | bool | `false` | P0 |
| `security.fail2ban.enabled` | bool | `true` | P1 |
| `security.autoUpdates` | `security`, `all`, `none` | `security` | P1 |

### Phase 8: Lifecycle

| Parameter | Optionen | Default | Priorität |
|-----------|----------|---------|-----------|
| `lifecycle.driftDetection` | bool | `false` | P1 |
| `lifecycle.driftSchedule` | cron | `0 */6 * * *` | P2 |
| `lifecycle.autoRemediate` | bool | `false` | P2 |
| `lifecycle.healthChecks.enabled` | bool | `true` | P0 |
| `lifecycle.healthChecks.interval` | duration | `60s` | P1 |

---

## 🏗️ NEU: Dreistufige Architektur (Layer-Konzept)

### Warum dreistufig?

**Problem:** Docker und Kubernetes sind fundamental verschiedene Paradigmen:

| Aspekt | Docker | Kubernetes |
|--------|--------|------------|
| **Deployments** | `docker compose up` | `kubectl apply` / Helm / Flux |
| **Networking** | Bridge + Traefik | CNI + Ingress Controller |
| **Service Discovery** | Container-Names | DNS + Services |
| **Orchestration** | Manual / Swarm | Built-in |
| **Storage** | Volumes | PV/PVC |
| **Scaling** | Manual | HPA/VPA |
| **Health Checks** | Healthcheck in Compose | Probes (liveness/readiness) |

**Konsequenz:** Service-Definitionen können NICHT platform-agnostisch sein!

### Layer 1: CORE (Platform-Agnostisch)

```cue
// base/core.cue - Shared across ALL platforms

#CoreLayer: {
    // Bootstrap: OS-Vorbereitung (immer gleich)
    bootstrap: #BootstrapConfig
    
    // System: Users, SSH, Firewall (immer gleich)
    system: #SystemConfig
    
    // Network Fundamentals: IP, DNS, Firewall (immer gleich)
    network: #NetworkConfig
    
    // Security: SSH-Hardening, Fail2ban (immer gleich)
    security: #SecurityConfig
}
```

**Was gehört in Core:**
- SSH-Key Setup, User-Management
- Firewall (UFW/Firewalld)
- System Updates & Packages
- Fail2ban, SSH-Hardening
- DNS-Config (systemd-resolved)
- Timezone, Locale

### Layer 2: PLATFORM (Docker vs. Kubernetes)

```cue
// platform/docker.cue

#DockerPlatform: {
    type: "docker"
    
    // Docker-spezifische Config
    runtime: {
        version: string | *"latest"
        rootless: bool | *false
        registryMirror?: string
        logDriver: "json-file" | "journald" | *"json-file"
    }
    
    // Orchestration Mode
    mode: "standalone" | "swarm" | *"standalone"
    
    // Network Mode für Services
    networkMode: "bridge" | "host" | *"bridge"
    
    // Reverse Proxy (Docker-native)
    reverseProxy: "traefik" | "caddy" | "nginx-proxy" | *"traefik"
}

// platform/kubernetes.cue

#KubernetesPlatform: {
    type: "kubernetes"
    
    distribution: "k3s" | "k0s" | "microk8s" | "kubeadm" | *"k3s"
    
    controlPlane: {
        count: 1 | 3 | 5 | *1
        etcd: "embedded" | "external" | *"embedded"
    }
    
    cni: "flannel" | "cilium" | "calico" | *"flannel"
    
    ingress: "traefik" | "nginx" | "kong" | *"traefik"
    
    loadBalancer: "none" | "metallb" | "kube-vip" | *"none"
    
    gitops?: {
        enabled: bool
        tool: "flux" | "argocd"
    }
}
```

### Layer 3: SERVICES + HEALTH (Platform-Specific)

```cue
// services/docker/dokploy.cue

#DokployDocker: {
    _platform: "docker"
    
    name: "dokploy"
    image: "dokploy/dokploy:latest"
    
    compose: {
        services: dokploy: {
            image: image
            ports: ["3000:3000"]
            volumes: [
                "/var/run/docker.sock:/var/run/docker.sock",
                "dokploy-data:/app/.next/cache"
            ]
            healthcheck: {
                test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
                interval: "30s"
                timeout: "10s"
                retries: 3
            }
        }
    }
    
    // Platform-specific outputs
    output: {
        url: _network.mode == "local" ? 
            "https://\(_node.ip):3000" : 
            "https://dokploy.\(_domain)"
    }
}

// services/kubernetes/dokploy.cue  

#DokployKubernetes: {
    _platform: "kubernetes"
    
    name: "dokploy"
    
    // Helm Chart oder raw manifests
    helm?: {
        chart: "dokploy/dokploy"
        version: "1.0.0"
        values: {...}
    }
    
    manifests?: [...#KubernetesManifest]
    
    // K8s-specific health
    probes: {
        liveness: {
            httpGet: { path: "/api/health", port: 3000 }
            periodSeconds: 30
        }
        readiness: {
            httpGet: { path: "/api/ready", port: 3000 }
            periodSeconds: 10
        }
    }
}
```

---

## 🔄 Bootstrap-Prozess: Erweiterte Analyse

### Aktueller Flow (IST)

```
1. User konfiguriert im Wizard
2. Stack wird erstellt (POST /stacks)
3. Provisioning Job startet
4. OpenTofu apply (PROBLEM: Server muss schon existieren!)
5. Bootstrap Script (PROBLEM: Wie kommt es auf den Server?)
6. Agent Registration
7. Services Deploy
```

**Kritische Lücke:** Zwischen Schritt 3 und 4 fehlt die Worker-Validation!

### Neuer Flow (SOLL) - Agent-First Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: CONFIGURATION                                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1.1 User konfiguriert im Wizard                                        │
│      ├── Wählt StackKit (Base Homelab, Modern, HA)                      │
│      ├── Wählt Variant (default, beszel, minimal)                       │
│      └── Konfiguriert Optionen (network.mode, domain, etc.)             │
│                                                                          │
│  1.2 Unifier (Analyze Phase)                                            │
│      ├── Validiert IntentSpec gegen CUE-Schema                          │
│      ├── Wählt/Bestätigt StackKit                                       │
│      ├── Berechnet RequirementsSpec:                                    │
│      │   ├── Min. Worker: 1                                             │
│      │   ├── Min. RAM: 4GB                                              │
│      │   ├── Min. Disk: 20GB                                            │
│      │   ├── Ports: [80, 443, 5261]                                     │
│      │   └── OS: [ubuntu-22, ubuntu-24, debian-12]                      │
│      └── Output: RequirementsSpec + Registration Token                   │
│                                                                          │
│  1.3 UI zeigt User:                                                     │
│      ├── "Dein Homelab braucht: 1 Server mit min. 4GB RAM"             │
│      ├── One-Liner für Worker-Registration                              │
│      └── Status: "Warte auf Worker..."                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: WORKER REGISTRATION                                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  2.1 User führt One-Liner auf Server aus:                               │
│      curl -fsSL https://get.kombistack.io | TOKEN=abc123 bash           │
│                                                                          │
│  2.2 Bootstrap Script (scripts/bootstrap-worker.sh):                    │
│      ├── System-Detection (OS, Arch, RAM, Disk, Ports)                  │
│      ├── NICHT: Docker Installation (kommt später!)                     │
│      ├── KombiStack Agent Installation                                  │
│      └── Agent startet mit Registration Token                           │
│                                                                          │
│  2.3 Agent → Core (gRPC Register):                                      │
│      {                                                                   │
│        "hostname": "server-1",                                           │
│        "os": "ubuntu-24.04",                                             │
│        "arch": "amd64",                                                  │
│        "ram_mb": 8192,                                                   │
│        "disk_gb": 100,                                                   │
│        "ports_free": [80, 443, 5261],                                   │
│        "docker_installed": false,                                        │
│        "existing_containers": []                                         │
│      }                                                                   │
│                                                                          │
│  2.4 Core speichert Worker in DB (status: "pending_approval")           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: VALIDATION & ADJUSTMENT                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  3.1 Core vergleicht Worker-Info mit RequirementsSpec:                  │
│                                                                          │
│      if (worker.ram_mb < requirements.min_ram):                         │
│          → UI: "⚠️ Server hat nur 2GB RAM, empfohlen: 4GB"              │
│          → Option: "Trotzdem fortfahren" oder "Anderen Server nutzen"   │
│                                                                          │
│      if (workers.count > requirements.min_workers):                      │
│          → UI: "ℹ️ Du hast 2 Server registriert, Base Homelab braucht 1"│
│          → Option: "StackKit upgraden zu Modern Homelab?"               │
│          → Option: "Zweiten Server als Backup-Node nutzen?"             │
│                                                                          │
│      if (!worker.ports_free.includes(443)):                              │
│          → UI: "❌ Port 443 ist belegt. Bitte freigeben."               │
│          → Blockiert Rollout                                             │
│                                                                          │
│  3.2 User kann reagieren:                                               │
│      ├── Weitere Server registrieren                                     │
│      ├── Server austauschen                                              │
│      ├── StackKit ändern                                                 │
│      ├── Add-ons hinzufügen (z.B. "external-storage")                   │
│      └── Warnings akzeptieren                                           │
│                                                                          │
│  3.3 Validation-Status:                                                 │
│      ├── ✅ READY: Alle Requirements erfüllt                            │
│      ├── ⚠️ WARNINGS: Erfüllt mit Einschränkungen                      │
│      └── ❌ BLOCKED: Kritische Requirements nicht erfüllt               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: UNIFY & PREPARE                                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  4.1 User bestätigt Rollout (Button: "Homelab ausrollen")               │
│                                                                          │
│  4.2 Unifier (Unify Phase):                                             │
│      IntentSpec + Workers + Credentials → UnifiedSpec                    │
│      ├── Service-Placement (welcher Service auf welchen Worker)         │
│      ├── Network-Config (IP-Adressen, Ports)                            │
│      ├── Secrets-Generation (Passwörter, API-Keys)                      │
│      └── Output: UnifiedSpec (StackKit-spezifisches Format)             │
│                                                                          │
│  4.3 Generator:                                                          │
│      UnifiedSpec → IaC                                                   │
│      ├── Simple Mode: OpenTofu templates                                │
│      └── Advanced Mode: Terramate + OpenTofu                            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: ROLLOUT                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  5.1 Core queued Commands an Worker via gRPC CommandStream:             │
│                                                                          │
│      Command 1: PREPARE_SYSTEM                                          │
│      ├── apt update && apt upgrade                                      │
│      ├── Install required packages                                      │
│      ├── Configure firewall (UFW)                                       │
│      ├── Configure SSH hardening                                        │
│      └── Create admin user                                              │
│                                                                          │
│      Command 2: INSTALL_PLATFORM                                        │
│      ├── Docker Mode: Install Docker + Docker Compose                   │
│      └── K8s Mode: Install k3s + kubectl                               │
│                                                                          │
│      Command 3: DEPLOY_SERVICES                                         │
│      ├── Docker: docker compose up -d                                   │
│      └── K8s: kubectl apply / helm install                             │
│                                                                          │
│      Command 4: VERIFY_HEALTH                                           │
│      ├── Check all services responding                                  │
│      ├── Check TLS working                                              │
│      └── Report final status                                            │
│                                                                          │
│  5.2 UI zeigt Progress:                                                 │
│      [████████░░░░░░░░░░░░] 40% - Installing Docker...                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: VERIFICATION & HANDOVER                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  6.1 Post-Rollout Health Checks:                                        │
│      ├── HTTP GET auf alle Service-URLs                                 │
│      ├── TLS-Zertifikat gültig?                                        │
│      ├── DNS auflösbar (wenn public)?                                   │
│      └── All containers/pods running?                                   │
│                                                                          │
│  6.2 Bei Erfolg:                                                        │
│      ├── Stack-Status: "running"                                        │
│      ├── UI zeigt: "🎉 Dein Homelab ist bereit!"                        │
│      ├── UI zeigt: Service URLs + Initial Credentials                   │
│      └── Agent wechselt in Monitoring-Mode (Heartbeat)                  │
│                                                                          │
│  6.3 Bei Fehler:                                                        │
│      ├── Stack-Status: "failed"                                         │
│      ├── UI zeigt: "❌ Rollout fehlgeschlagen"                          │
│      ├── UI zeigt: Fehler-Details + Logs                                │
│      └── Option: "Retry" oder "Rollback"                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Integration: Wo passiert was?

### Komponenten-Mapping

| Phase | Komponente | Location |
|-------|------------|----------|
| 1.1 Wizard | Frontend | `app/src/routes/stacks/wizard/` |
| 1.2 Analyze | Unifier | `pkg/unifier/analyze.go` |
| 1.3 Requirements UI | Frontend | `app/src/routes/stacks/+page.svelte` |
| 2.1-2.2 Bootstrap | Script | `scripts/bootstrap-worker.sh` |
| 2.3 Registration | gRPC | `pkg/grpcserver/server.go` |
| 3.1-3.3 Validation | Core | `pkg/unifier/validator.go` (NEU) |
| 4.2 Unify | Unifier | `pkg/unifier/unify.go` |
| 4.3 Generate | Generator | `pkg/tofu/generator_advanced.go` |
| 5.1 Commands | Orchestrator | `pkg/orchestrator/` (NEU) |
| 5.2 Progress | SSE | `internal/routes/sse.go` |
| 6.1-6.3 Health | Agent | `cmd/kombistack/agent/` |

### Was gehört in StackKits vs. Core?

| Verantwortung | Location | Beispiel |
|---------------|----------|----------|
| Service-Definitionen | StackKit | `services.cue`, Compose-Files |
| Service-Placement | Core | Worker-Matching Algorithm |
| OS-Packages | Core | apt install docker.io |
| Platform-Install | Core + StackKit | Core: Script, StackKit: Version/Config |
| Health-Check Logic | StackKit | Welche Endpoints prüfen |
| Health-Check Execution | Core/Agent | HTTP-Requests durchführen |
| TLS-Config | StackKit | ACME vs Self-Signed |
| TLS-Provisioning | Core | certbot / mkcert |

---

## 📊 StackKit-Übersicht (Aktualisiert)

### Base Homelab (Docker-Only)

```yaml
name: base-homelab
platform: docker
mode: standalone
network: local | public
nodes: 1
```

**Services:**
- Traefik (Reverse Proxy)
- Dokploy (PaaS) oder Dockge/Portainer
- Uptime Kuma oder Beszel (Monitoring)
- Dozzle (Logs)

### Modern Homelab (Docker Multi-Node)

```yaml
name: modern-homelab  
platform: docker
mode: standalone | swarm
network: local | public | hybrid
nodes: 2-5
```

**Zusätzliche Services:**
- NFS/Longhorn für Shared Storage
- Headscale für VPN
- Prometheus + Grafana (optional)

### HA Homelab (Kubernetes)

```yaml
name: ha-homelab
platform: kubernetes
distribution: k3s
mode: ha
network: public | hybrid
nodes: 3+
```

**Platform-Stack:**
- k3s mit embedded etcd
- MetalLB oder kube-vip
- Traefik Ingress
- Longhorn Storage
- FluxCD für GitOps

---

## 🏗️ Architektur: Core vs. StackKit-Specific

### Core (Shared für alle StackKits)

```
base/
├── bootstrap/           # OS-Preparation
│   ├── ssh.cue          # SSH Bootstrap Logic
│   ├── cloud-init.cue   # Cloud-Init Templates
│   └── packages.cue     # Package Installation
│
├── system/              # System Configuration
│   ├── users.cue        # User Management
│   ├── security.cue     # SSH, Firewall, Fail2ban
│   ├── timezone.cue     # Time/Locale
│   └── sysctl.cue       # Kernel Parameters
│
├── network/             # Network Fundamentals
│   ├── modes.cue        # local/public/hybrid
│   ├── tls.cue          # ACME/Self-signed/None
│   ├── firewall.cue     # UFW/Firewalld
│   └── dns.cue          # DNS Configuration
│
├── container/           # Container Runtime
│   ├── docker.cue       # Docker Installation & Config
│   └── podman.cue       # Podman Alternative
│
├── lifecycle/           # Operations
│   ├── health.cue       # Health Check Framework
│   ├── backup.cue       # Backup Framework
│   ├── drift.cue        # Drift Detection
│   └── rollback.cue     # Rollback Mechanics
│
└── service/             # Service Framework
    ├── definition.cue   # Service Schema
    ├── network.cue      # Service Networking
    └── output.cue       # URL/Credential Output
```

### StackKit-Specific (base-homelab)

```
base-homelab/
├── stackkit.yaml        # Metadata & Variants
├── stackfile.cue        # Extends base.#BaseStackKit
│
├── services/            # Service Definitions
│   ├── traefik.cue      # Reverse Proxy
│   ├── dokploy.cue      # PaaS Platform
│   ├── monitoring.cue   # Uptime Kuma, Beszel, Netdata
│   └── logging.cue      # Dozzle
│
├── variants/            # Pre-configured Sets
│   ├── default.cue      # Dokploy + Uptime Kuma
│   ├── beszel.cue       # Dokploy + Beszel
│   └── minimal.cue      # Dockge + Portainer
│
└── templates/
    ├── simple/          # OpenTofu-only
    └── advanced/        # Terramate + OpenTofu
```

---

## 🔄 Multi-Server Architektur

### StackKit Comparison

| Aspekt | Base Homelab | Modern Homelab | HA Homelab |
|--------|--------------|----------------|------------|
| **Nodes** | 1 | 2-5 | 3+ |
| **Container** | Docker | Docker/k3s | k3s HA |
| **Networking** | Bridge | Bridge/CNI | CNI + MetalLB |
| **Storage** | Local | Local/NFS | Distributed |
| **Service Mesh** | None | Optional | Optional |
| **GitOps** | None | Optional | FluxCD |
| **HA Control Plane** | N/A | N/A | 3+ Masters |

### Core-Erweiterungen für Multi-Node

```cue
#ClusterConfig: {
    type: "standalone" | "multi-node" | "k3s" | "k3s-ha"
    
    nodes: [...#NodeDefinition]
    
    controlPlane?: {
        count: 1 | 3 | 5
        etcd: "embedded" | "external"
    }
    
    cni?: "bridge" | "flannel" | "cilium"
    loadBalancer?: "none" | "metallb" | "kube-vip"
}
```

---

## 🧩 Add-On Konzept

### Klassifizierung

| Aktion | Typ | Beschreibung |
|--------|-----|--------------|
| Service hinzufügen | **Service** | Erweitert Config |
| Worker Node hinzufügen | **Add-On** | Ändert Topologie |
| Storage Node hinzufügen | **Add-On** | Ändert Architektur |
| Version updaten | **Update** | Lifecycle-Op |
| Variant wechseln | **Migration** | Potentieller Datenverlust |

### Add-On Schema

```cue
#AddOn: {
    name: string
    targetStackKit: string
    type: "node" | "storage" | "service-pack" | "feature"
    
    requires: {
        minVersion?: string
        features?: [...string]
        existingNodes?: int
    }
    
    adds: {
        nodes?: [...#NodeDefinition]
        services?: [...#ServiceDefinition]
        config?: {...}
    }
    
    idempotent: bool
    rollbackable: bool
}
```

---

## � Challenge: Offene Fragen & Entscheidungen

### Frage 1: Terramate - Wann genau?

**Aktueller Stand:** Terramate ist als "Advanced Mode" definiert, aber unklar wann genau.

**Optionen:**

| Option | Pro | Contra |
|--------|-----|--------|
| A) Terramate nur für Multi-Node | Einfacher Start | Zwei Code-Pfade |
| B) Terramate immer (auch Single-Node) | Einheitlich | Overkill für 1 Server |
| C) Terramate nur für Day-2 Ops | Clear Separation | Komplexität |

**Empfehlung:** Option C - OpenTofu für Initial-Rollout, Terramate für Drift/Updates.

### Frage 2: OpenTofu vs. Agent Commands

**Problem:** Wer macht was beim Rollout?

```
Option A: OpenTofu-Centric
  OpenTofu → SSH → Server → Install Docker → Deploy

Option B: Agent-Centric (Empfohlen)
  Agent registered → Core queues Commands → Agent executes
```

**Empfehlung:** Agent-Centric, weil:
- Kein SSH-Key-Management nötig
- Echtzeit-Feedback via gRPC Stream
- Agent kann Pre-Checks lokal ausführen
- Bidirektionale Kommunikation

### Frage 3: Wo leben Service-Definitionen?

**Aktuell:** `services.cue` mit Docker-Compose-ähnlicher Struktur.

**Problem:** Kubernetes braucht komplett andere Struktur.

**Lösung:**

```
stackkits/base-homelab/
├── services/
│   ├── docker/          # Docker Compose files
│   │   ├── traefik.yml
│   │   └── dokploy.yml
│   └── kubernetes/      # K8s manifests (falls needed)
│       ├── traefik/
│       └── dokploy/
```

### Frage 4: Self-Signed TLS Workflow

**Problem:** Let's Encrypt braucht Domain + Port 80 offen. Lokale Homelabs haben das oft nicht.

**Lösung:**

```
network:
  mode: local
  tls:
    mode: self-signed
    # Generiert CA + Certs beim Rollout
    # User kann CA in Browser importieren
```

**Implementierung:**
1. Agent generiert mkcert CA auf erstem Start
2. CA wird an Core gemeldet
3. UI bietet CA-Download an
4. User importiert CA in Browser/Geräte

---

## 📈 Implementation Roadmap (Erweitert)

### Sprint 1: Foundation (Woche 1-2)

**Ziel:** Local-Only Deployment funktioniert

- [ ] **1.1** Network-Mode Logik in StackKits
  - `network.mode: local` → IP-basierte URLs
  - `network.mode: public` → Domain-basierte URLs
  
- [ ] **1.2** Self-Signed TLS Support
  - mkcert Integration in Agent
  - CA-Download in UI
  
- [ ] **1.3** Bootstrap Script Cleanup
  - Nur Agent-Installation
  - System-Info Collection
  - KEIN Docker-Install

- [ ] **1.4** Worker-Validation in Core
  - RequirementsSpec Matching
  - UI-Feedback für Warnings/Errors

### Sprint 2: Agent-Driven Rollout (Woche 3-4)

**Ziel:** Rollout via Agent Commands statt SSH

- [ ] **2.1** Command-Types definieren
  - `PREPARE_SYSTEM` (packages, firewall)
  - `INSTALL_PLATFORM` (docker/k3s)
  - `DEPLOY_SERVICES` (compose up)
  - `VERIFY_HEALTH` (health checks)

- [ ] **2.2** Command-Queue in Core
  - Job → Commands → Worker Queue
  - Progress Tracking via SSE

- [ ] **2.3** Agent Command-Execution
  - Shell-Executor mit Timeout
  - Structured Output
  - Error-Reporting

- [ ] **2.4** Health-Verification Framework
  - HTTP-Checks
  - Port-Checks
  - Container-Status

### Sprint 3: Platform Abstraction (Woche 5-6)

**Ziel:** Docker/K8s als austauschbare Plattformen

- [ ] **3.1** Platform-Layer Schema
  - `#DockerPlatform`
  - `#KubernetesPlatform`

- [ ] **3.2** Service-Definitionen splitten
  - `services/docker/*.yml`
  - `services/kubernetes/*.yaml`

- [ ] **3.3** Generator Platform-Aware
  - Docker → Compose-Files
  - K8s → Helm/Manifests

### Sprint 4: Modern Homelab (Woche 7-8)

**Ziel:** Multi-Node Docker funktioniert

- [ ] **4.1** Node-Role Definition
  - Primary Node (Traefik, Management)
  - Worker Nodes (Services)

- [ ] **4.2** Service-Placement Algorithm
  - Resource-Based
  - Label-Based

- [ ] **4.3** Shared Storage Option
  - NFS Setup
  - Volume-Mounts

### Sprint 5: Day-2 Operations (Woche 9-10)

**Ziel:** Updates und Drift-Detection

- [ ] **5.1** Terramate Integration
  - Drift-Detection
  - Selective Updates

- [ ] **5.2** Add-On Framework
  - Node Add
  - Service-Pack Add

- [ ] **5.3** Backup-Framework
  - Restic/Borg Integration
  - Scheduled Backups

### Future: HA Homelab (TBD)

- [ ] k3s HA Setup
- [ ] etcd Cluster
- [ ] MetalLB/kube-vip
- [ ] FluxCD GitOps

---

## 🎯 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time to First Deploy | < 10 min | Von Wizard-Start bis Services laufen |
| Manual Steps | 0 | Nur One-Liner für Agent |
| Success Rate | > 95% | Erfolgreiche Rollouts ohne Retry |
| Health Check Coverage | 100% | Alle Services haben Health-Endpoint |
| Rollback Success | > 90% | Erfolgreiche Rollbacks bei Fehler |

---

## 📝 Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-08 | Initial draft |
| 2.0 | 2026-01-08 | Major revision: Dreistufige Architektur, Agent-First Bootstrap, Platform-Layer |

---

## 🔗 Related Documents

- [Unifier-Specification-Flow.md](../../KombiStack/docs/concepts/Unifier-Specification-Flow.md) - 6-Phasen Pipeline
- [Worker-Service-Matching-Algorithm.md](../../KombiStack/docs/concepts/Worker-Service-Matching-Algorithm.md) - Placement Logic
- [DECISIONS.md](../../KombiStack/DECISIONS.md) - ADRs
- [ROADMAP.md](../../KombiStack/docs/ROADMAP.md) - Project Roadmap

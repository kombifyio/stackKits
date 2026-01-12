# 🔍 Kritische StackKit Review-Analyse

## ❌ KRITISCHE ISSUES

### 1. **Service URLs Problem (wie du gesagt hast)**
```cue
output: {
    url: "https://traefik.{{.domain}}"  // FALSCH!
}
```
**Problem:** Bei lokalem Rollout existiert keine Domain. Let's Encrypt funktioniert nur mit öffentlicher Domain.

**Reality-Check:**
- User hat Server mit IP `192.168.1.100`
- User hat evtl. KEINE Domain
- ACME/Let's Encrypt braucht Port 80 + öffentlich erreichbar
- Lokales Netzwerk = self-signed Certs oder gar keine

### 2. **Keine Unterscheidung Local vs. Public Deployment**
Das StackKit nimmt an, dass:
- Eine Domain existiert
- Let's Encrypt funktioniert
- Services von außen erreichbar sind

**Fehlt:** 
- Local-only Mode (IP-based, self-signed)
- DNS-Setup Automatisierung
- Fallback auf HTTP im lokalen Netz

### 3. **Keine Pre-Flight Checks**
Vor dem Rollout prüft NICHTS ob:
- Docker installiert ist
- Port 80/443 frei sind
- SSH-Zugang funktioniert
- Genug Disk Space vorhanden
- OS kompatibel ist

### 4. **Keine Post-Rollout Verification**
Nach dem Rollout:
- Keine Health-Checks der Services
- Keine Validierung dass alles läuft
- Keine Rollback-Strategie bei Fehler

### 5. **OS-Preparation fehlt komplett**
Das OpenTofu Template geht davon aus, dass Docker schon läuft! 

```terraform
provider "docker" {
  host = "unix:///var/run/docker.sock"  // Woher kommt Docker?
}
```

**Fehlt:**
- Docker Installation
- System-Updates
- Firewall-Setup
- SSH-Hardening
- User-Setup

### 6. **Secrets Management = "file"**
```cue
secrets: base.#SecretsPolicy & {
    backend: "file"  // Unsicher!
}
```
Wo werden Passwörter generiert? Wo gespeichert?

### 7. **Keine Idempotenz-Garantie**
Was passiert bei erneutem `apply`? 
- Werden Daten überschrieben?
- Bleiben User-Änderungen erhalten?

---

## 📊 IST-Zustand: Variabilität & Konfigurierbarkeit

| # | Bereich | Aktueller Stand | Status |
|---|---------|-----------------|--------|
| 1 | **OS Support** | `ubuntu-24`, `ubuntu-22`, `debian-12` | ⚠️ Definiert aber nicht implementiert - keine OS-spezifische Logik |
| 2 | **Monitoring Tools** | Uptime Kuma, Beszel, Netdata (je Variante) | ✅ Varianten-System existiert |
| 3 | **Deployment Modi** | Simple (OpenTofu) vs Advanced (Terramate) | ⚠️ Nur Simple implementiert |
| 4 | **Orchestration nach Rollout** | Nicht vorhanden | ❌ FEHLT komplett |
| 5 | **Drift Detection** | Nur als "Feature" beschrieben | ❌ FEHLT komplett |
| 6 | **Netzwerk-Modi** | Bridge only, VPN "disabled" | ❌ Nur ein Modus |
| 7 | **TLS/SSL Modi** | Nur Let's Encrypt | ❌ Kein Local Mode |
| 8 | **DNS Setup** | Nicht vorhanden | ❌ FEHLT |
| 9 | **Compute Tiers** | high/standard/low definiert | ⚠️ Nur Memory-Limits, keine echte Logik |
| 10 | **Backup** | `restic` definiert | ❌ Nicht implementiert |
| 11 | **SSH Hardening** | Definiert in CUE | ❌ Nicht implementiert |
| 12 | **Firewall** | `ufw` definiert | ❌ Nicht implementiert |
| 13 | **User Setup** | `admin`, `service` User | ❌ Nicht implementiert |
| 14 | **Package Installation** | Liste in CUE | ❌ Nicht implementiert |

### Fazit IST-Zustand:
**~80% der CUE-Definitionen sind "Papier-Tiger"** - definiert aber nirgends verwendet!

---

## 📋 SOLL-Liste: Notwendige Konfigurierbarkeit

### Phase 1: Bootstrap (OS-Vorbereitung)

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `bootstrap.mode` | `ssh`, `cloud-init`, `agent` | `ssh` | P0 |
| `bootstrap.ssh.user` | string | `root` | P0 |
| `bootstrap.ssh.port` | int | `22` | P0 |
| `bootstrap.ssh.keyPath` | string | `~/.ssh/id_ed25519` | P0 |
| `bootstrap.os.update` | `full`, `security`, `none` | `security` | P1 |
| `bootstrap.os.reboot` | bool | `true` (if kernel update) | P1 |

### Phase 2: System-Konfiguration

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `system.hostname` | string | auto-generated | P0 |
| `system.timezone` | IANA TZ | `UTC` | P1 |
| `system.locale` | string | `en_US.UTF-8` | P2 |
| `system.swap` | `auto`, `2G`, `none` | `auto` | P2 |
| `system.users.admin.name` | string | `kombi` | P0 |
| `system.users.admin.sshKeys` | []string | REQUIRED | P0 |

### Phase 3: Netzwerk

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `network.mode` | `local`, `public`, `hybrid` | `local` | P0 |
| `network.domain` | string | `null` (IP-based) | P0 |
| `network.tls.mode` | `acme`, `self-signed`, `none` | auto | P0 |
| `network.tls.acme.email` | string | required if acme | P0 |
| `network.tls.acme.staging` | bool | `false` | P1 |
| `network.dns.provider` | `cloudflare`, `manual`, `none` | `none` | P1 |
| `network.firewall.enabled` | bool | `true` | P0 |
| `network.firewall.backend` | `ufw`, `firewalld`, `iptables` | auto | P1 |
| `network.ports.ssh` | int | `22` | P1 |
| `network.ports.http` | int | `80` | P2 |
| `network.ports.https` | int | `443` | P2 |

### Phase 4: Container Runtime

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `container.runtime` | docker, `podman` | docker | P1 |
| `container.registryMirror` | string | `null` | P2 |
| `container.logDriver` | `json-file`, `journald` | `json-file` | P2 |
| `container.storageDriver` | `overlay2`, `btrfs` | auto | P2 |

### Phase 5: Services

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `services.variant` | `default`, `beszel`, `minimal` | `default` | P0 |
| `services.reverseProxy` | `traefik`, `caddy`, `nginx` | `traefik` | P1 |
| `services.platform` | `dokploy`, `dockge`, `portainer` | per variant | P1 |
| `services.monitoring` | `uptime-kuma`, `beszel`, `netdata` | per variant | P1 |

### Phase 6: Observability

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `observability.logs.retention` | duration | `7d` | P1 |
| `observability.metrics.enabled` | bool | `true` | P1 |
| `observability.backup.enabled` | bool | `true` | P1 |
| `observability.backup.schedule` | cron | `0 3 * * *` | P1 |
| `observability.backup.target` | `local`, `s3`, `b2` | `local` | P1 |

### Phase 7: Security

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `security.ssh.permitRoot` | bool | `false` | P0 |
| `security.ssh.passwordAuth` | bool | `false` | P0 |
| `security.fail2ban.enabled` | bool | `true` | P1 |
| `security.autoUpdates` | `security`, `all`, `none` | `security` | P1 |

### Phase 8: Lifecycle & Operations

| Config | Optionen | Default | Priorität |
|--------|----------|---------|-----------|
| `lifecycle.driftDetection` | bool | `false` | P1 |
| `lifecycle.driftSchedule` | cron | `0 */6 * * *` | P2 |
| `lifecycle.autoRemediate` | bool | `false` | P2 |
| `lifecycle.healthChecks.enabled` | bool | `true` | P0 |
| `lifecycle.healthChecks.interval` | duration | `60s` | P1 |

---

## 📐 IST vs SOLL Auswertung

### Gap-Analyse

| Bereich | IST | SOLL | Gap |
|---------|-----|------|-----|
| Bootstrap/OS-Prep | 0% | 100% | **KRITISCH** |
| Netzwerk-Modi | 10% | 100% | **KRITISCH** |
| TLS/SSL Optionen | 10% | 100% | **KRITISCH** |
| Service Varianten | 60% | 100% | Medium |
| Security Hardening | 5% | 100% | **KRITISCH** |
| Lifecycle/Drift | 0% | 100% | Hoch |
| Backup | 0% | 100% | Hoch |
| Health Checks | 20% | 100% | **KRITISCH** |

### Architektur-Problem

```
AKTUELL:
kombination.yaml → Unifier → OpenTofu Template → Docker Provider
                                    ↓
                            (Keine OS-Ebene!)

SOLL:
kombination.yaml → Unifier → Bootstrap Script → OS Configuration
                                    ↓
                            OpenTofu → Docker Services
                                    ↓
                            Health Verification
```

---

## 🏗️ Core vs. StackKit-Specific

### CORE (für alle StackKits gleich)

```
base/
├── bootstrap/           # OS-Preparation
│   ├── ssh.cue          # SSH Bootstrap
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

### StackKit-SPECIFIC (base-homelab)

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

## 🔄 Multi-Server Vorbereitung

### Was unterscheidet Base von Modern/HA Homelab?

| Aspekt | Base Homelab | Modern Homelab | HA Homelab |
|--------|--------------|----------------|------------|
| **Nodes** | 1 | 2-5 | 3+ |
| **Container** | Docker | Docker | k3s HA |
| **Networking** | Bridge | Overlay, VPN oder Mesh | CNI + MetalLB |
| **Storage** | Local | TBD | Ceph/Longhorn |
| **Service Mesh** | None | Optional | Cilium/Linkerd |
| **GitOps** | None | TBD | FluxCD |
| **HA Control Plane** | N/A | Single Master | 3+ Masters |

### Core-Erweiterungen für Multi-Node

```cue
// In base/cluster/ (NEU)
#ClusterConfig: {
    // Cluster type
    type: "standalone" | "k3s" | "k3s-ha"
    
    // Node roles
    nodes: [...#NodeDefinition]
    
    // Control plane config (k3s)
    controlPlane?: {
        count: 1 | 3 | 5
        etcd: "embedded" | "external"
    }
    
    // CNI
    cni?: "flannel" | "cilium" | "calico"
    
    // Load balancer
    loadBalancer?: "metallb" | "kube-vip"
}

// Erweiterung von #NodeDefinition
#NodeDefinition: {
    // ... existing ...
    
    // Cluster role (NEU für Multi-Node)
    clusterRole?: "control-plane" | "worker" | "etcd"
    
    // Join token (NEU)
    joinToken?: =~"^secret://"
}
```

### Was bleibt Core, was wird StackKit-spezifisch?

**CORE (shared):**
- Bootstrap/SSH/Users
- Network fundamentals (firewall, DNS)
- TLS/Cert management
- Health check framework
- Backup framework

**StackKit-Specific:**
- Service-Auswahl (Traefik vs Ingress)
- Monitoring-Stack (Uptime Kuma vs Prometheus)
- Platform (Dokploy vs k8s Workloads)
- Storage-Backend (local vs distributed)

---

## 🧩 Add-On Konzept

### Was IST ein Add-On vs. was NICHT?

| Aktion | Typ | Erklärung |
|--------|-----|-----------|
| Neuen Service installieren (z.B. Grafana) | **Service** | Erweitert bestehende Config |
| Neuen Worker Node hinzufügen | **Add-On** | Ändert Cluster-Topologie |
| Zweiten Storage Node hinzufügen | **Add-On** | Ändert Storage-Architektur |
| Service-Version updaten | **Update** | Lifecycle-Operation |
| Variant wechseln (default → beszel) | **Migration** | Kann Datenverlust bedeuten |

### Add-On Schema

```cue
#AddOn: {
    // Add-On identifier
    name: string
    
    // Target StackKit
    targetStackKit: string
    
    // Type of add-on
    type: "node" | "storage" | "service-pack" | "feature"
    
    // Requirements
    requires: {
        minVersion?: string
        features?: [...string]
        existingNodes?: int
    }
    
    // What it adds
    adds: {
        nodes?: [...#NodeDefinition]
        services?: [...#ServiceDefinition]
        config?: {...}
    }
    
    // Idempotent?
    idempotent: bool
    
    // Rollback possible?
    rollbackable: bool
}

// Beispiel: Worker Node Add-On
#WorkerNodeAddOn: #AddOn & {
    name: "worker-node"
    type: "node"
    targetStackKit: "modern-homelab"
    
    requires: {
        features: ["kubernetes"]
        existingNodes: >=1
    }
    
    adds: {
        nodes: [{
            role: "worker"
            clusterRole: "worker"
            // ... config
        }]
    }
    
    idempotent: true
    rollbackable: true  // Node kann entfernt werden
}
```

### Add-On Lifecycle

```
1. User wählt Add-On im UI
2. KombiStack validiert Requirements
3. KombiStack generiert Delta-Config
4. User bestätigt Änderungen
5. KombiStack führt Add-On aus
6. Health-Check für neue Komponenten
7. Update der Stack-Dokumentation
```
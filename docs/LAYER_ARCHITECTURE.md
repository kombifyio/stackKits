# StackKits – Layer-Architektur, Varianten & Use Cases

**Version**: 1.1 (aktualisiert: Kubernetes entfernt, neue Konzepte)  
**Datum**: 2026-02-06  
**Lizenz**: Apache-2.0  
**Zielgruppe**: Entwickler, Contributor, Architekten

---

## Inhaltsverzeichnis

1. [Überblick: Die 3-Layer-Architektur](#1-überblick-die-3-layer-architektur)
2. [Layer 1: Foundation](#2-layer-1-foundation)
3. [Layer 2: Platform](#3-layer-2-platform)
4. [Layer 3: Applications](#4-layer-3-applications)
5. [StackKit-Varianten im Detail](#5-stackkit-varianten-im-detail)
6. [Use Cases & Entscheidungswege](#6-use-cases--entscheidungswege)
7. [Deployment-Modi: Simple vs Advanced](#7-deployment-modi-simple-vs-advanced)
8. [OpenTofu im Detail](#8-opentofu-im-detail)
9. [Terramate im Detail](#9-terramate-im-detail)
10. [Zusammenspiel: CUE → OpenTofu → Terramate](#10-zusammenspiel-cue--opentofu--terramate)
11. [Add-On-System](#11-add-on-system)
12. [Backend-Split: Local vs Cloud](#12-backend-split-local-vs-cloud)
13. [Persona-basierte Empfehlungen](#13-persona-basierte-empfehlungen)
14. [Unmanaged Layer](#14-unmanaged-layer)
15. [kombify Stack Integration](#15-kombify-stack-integration)
16. [Anhang: CUE-Schema-Referenz](#16-anhang-cue-schema-referenz)

---

## 1. Überblick: Die 3-Layer-Architektur

StackKits verwendet eine strikt geschichtete Architektur, bei der jeder Layer auf dem darunterliegenden aufbaut. Jeder Layer hat einen klaren Verantwortungsbereich und wird von einem spezifischen Tool verwaltet.

```
┌─────────────────────────────────────────────────────────┐
│                   LAYER 3: Applications                 │
│  • Uptime Kuma, Beszel, Whoami, Custom Apps             │
│  • Verwaltet durch: PAAS (Dokploy/Coolify)              │
│  • Deployed via: PAAS Git-Deploy oder Docker Compose     │
├─────────────────────────────────────────────────────────┤
│                   LAYER 2: Platform                     │
│  • Traefik (Ingress), PAAS (Dokploy/Coolify)            │
│  • Platform Identity (TinyAuth, PocketID)               │
│  • Docker Runtime, Networking                           │
│  • Verwaltet durch: OpenTofu/Terramate                  │
├─────────────────────────────────────────────────────────┤
│                   LAYER 1: Foundation                   │
│  • System (OS, Packages, Users)                         │
│  • Security (SSH, Firewall, Container Hardening)        │
│  • Core Identity (LLDAP, Step-CA)                       │
│  • Verwaltet durch: OpenTofu (remote-exec)              │
└─────────────────────────────────────────────────────────┘
         ▼ Physisch: Server (Bare Metal / VM / Cloud)
```

### Kernprinzipien

| Prinzip | Beschreibung |
|---------|-------------|
| **IaC-First** | Alles wird deklarativ definiert. Kein manuelles SSH zur Konfiguration. |
| **Layer-Isolation** | Jeder Layer kennt nur seine Abhängigkeiten nach unten, nie nach oben. |
| **PAAS für Apps** | Layer-3-Anwendungen werden NICHT per Terraform deployed, sondern über die PAAS-Plattform (Dokploy/Coolify). |
| **Zero-Trust-Ready** | Identity ist Pflichtkomponente in Layer 1 (LLDAP, Step-CA). |
| **Variant-basiert** | Jeder StackKit bietet Varianten, die unterschiedliche Service-Sets aktivieren. |

---

## 2. Layer 1: Foundation

### 2.1 Verantwortungsbereich

Layer 1 ist die **Betriebssystem- und Sicherheitsebene**. Sie wird beim ersten Deployment einmalig provisioniert und danach nur bei Security-Updates verändert.

### 2.2 Komponenten

#### System-Konfiguration (`base/system.cue`)

| Feld | Typ | Default | Beschreibung |
|------|-----|---------|-------------|
| `timezone` | string | `"UTC"` | IANA-Zeitzone |
| `locale` | string | `"en_US.UTF-8"` | System-Locale |
| `swap` | enum | `"auto"` | `disabled`, `auto`, `manual` |
| `unattendedUpgrades` | enum | `"security"` | `disabled`, `security`, `all` |

#### Base Packages (`base/system.cue`)

```yaml
packages:
  base: [curl, wget, ca-certificates, gnupg, ...]  # System-Grundausstattung
  tools: [htop, btop, tmux, jq, tree, ncdu]         # CLI-Werkzeuge
  extra: [...]                                        # StackKit-spezifisch
```

#### Security (`base/security.cue`)

| Modul | Schema | Default |
|-------|--------|---------|
| **SSH-Hardening** | `#SSHHardening` | Root-Login: no, Passwort-Auth: false, MaxAuth: 3 |
| **Firewall** | `#FirewallPolicy` | UFW, Default deny inbound, allow outbound |
| **Container-Security** | `#ContainerSecurityContext` | Non-root, drop ALL caps, seccomp RuntimeDefault |
| **Secrets** | `#SecretsPolicy` | File-basiert, `/run/secrets`, Mode 0400 |
| **TLS** | `#TLSPolicy` | Min TLS 1.2, ACME Let's Encrypt, HSTS |
| **Audit** | `#AuditConfig` | Disabled (opt-in) |

#### Core Identity – Zero-Trust-Fundament

**LLDAP** (`base/identity.cue` – `#LLDAPConfig`):
- Lightweight LDAP-Server für Homelab-Identity-Management
- Ports: 17170 (Web), 3890 (LDAP), 6360 (LDAPS)
- Verwaltet Benutzer, Gruppen, Zugriffsrechte
- **Pflicht** für alle StackKits (Zero-Trust-Anforderung)

**Step-CA** (`base/identity.cue` – `#StepCAConfig`):
- Interne Certificate Authority für mTLS (mutual TLS)
- Unterstützt ACME, SCEP (Device Enrollment), JWK
- Generiert kurzlebige TLS-Zertifikate für Service-to-Service-Kommunikation
- **Pflicht** für alle StackKits (ermöglicht verschlüsselte interne Kommunikation)

### 2.3 CUE-Validierung

```cue
// Layer 1 ist nur gültig wenn BEIDE Identity-Services aktiv sind:
#Layer1Foundation: {
    identity: {
        lldap:  #LLDAPConfig & { enabled: true }   // MUSS aktiv sein
        stepCA: #StepCAConfig & { enabled: true }   // MUSS aktiv sein
    }
    security: {
        ssh:      #SSHHardening      // MUSS konfiguriert sein
        firewall: #FirewallPolicy    // MUSS konfiguriert sein
    }
}
```

### 2.4 Terraform-Umsetzung (Day-1)

Layer 1 wird durch **remote-exec Provisioner** umgesetzt:

```hcl
# _bootstrap.tf.tmpl → System-Vorbereitung
resource "null_resource" "system_prep" {
  provisioner "remote-exec" {
    inline = [
      "apt-get update && apt-get upgrade -y",
      "apt-get install -y ${join(" ", var.packages)}",
      "timedatectl set-timezone ${var.timezone}",
    ]
  }
}

# _ssh.tf.tmpl → SSH-Härtung  
# _firewall.tf.tmpl → UFW-Konfiguration
# _lldap.tf.tmpl → LLDAP-Container-Deployment
# _step-ca.tf.tmpl → Step-CA-Initialisierung
```

---

## 3. Layer 2: Platform

### 3.1 Verantwortungsbereich

Layer 2 stellt die **Container-Plattform und das Routing** bereit. Es ist die Brücke zwischen dem Betriebssystem (Layer 1) und den Anwendungen (Layer 3).

### 3.2 Komponenten

#### Container Runtime (`base/system.cue` – `#ContainerRuntime`)

```yaml
container:
  engine: docker          # Docker als Standard-Runtime
  version: "27.5.1"       # Pinned Docker-Version
  rootless: false          # Rootless für Spezialfälle
  liveRestore: true        # Container überleben Docker-Restart
  logDriver: json-file     # Log-Format
  networkDriver: bridge    # Netzwerk-Modus
```

#### Ingress: Traefik v3 (Pflicht)

Traefik ist in **allen** StackKits als Reverse Proxy enthalten:
- Automatische Service-Discovery via Docker Labels
- Let's Encrypt TLS-Zertifikate (ACME)
- HTTP→HTTPS Redirect
- Dashboard auf Port 8080
- Middleware-Support (ForwardAuth für Identity)

#### PAAS-Plattform (Entscheidungslogik)

| Kriterium | → Dokploy | → Coolify |
|-----------|-----------|-----------|
| Eigene Domain? | Nein – Port-basiert | Ja – Proxy-basiert |
| Git-Deploys nötig? | Nein | Ja |
| Multi-Node? | Nein (Single-Server) | Ja |
| Zielgruppe | Einsteiger | Fortgeschrittene |

```
                    ┌───────────────────┐
                    │  Hat der User     │
                    │  eine Domain?     │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │                   │
              ┌─────┤    Nein    Ja     ├─────┐
              │     │                   │     │
              │     └───────────────────┘     │
              │                               │
     ┌────────▼────────┐           ┌──────────▼──────────┐
     │    DOKPLOY       │           │     COOLIFY          │
     │  Port-basiert    │           │  Proxy-basiert       │
     │  :3000 Web UI    │           │  Git-Deploy          │
     │  Einfach         │           │  Multi-Node          │
     └──────────────────┘           └──────────────────────┘
```

#### Platform Identity (Optional, Layer 2)

| Service | Typ | Use Case |
|---------|-----|----------|
| **TinyAuth** | Identity Proxy | Einfache Auth für Apps via Traefik ForwardAuth |
| **PocketID** | OIDC Provider | SSO (Single Sign-On) für alle Services |
| **Authelia** | Auth Server | MFA, Access Control Rules |
| **Authentik** | Full IdP | Enterprise-grade Identity Management |

### 3.3 CUE-Validierung

```cue
#Layer2Platform: {
    // Kubernetes intentionally excluded — Docker-first strategy (ADR-0002)
    platform: "docker" | "docker-swarm" | "bare-metal"
    
    // Container-Runtime nur wenn nicht bare-metal
    if platform != "bare-metal" {
        container: #ContainerRuntime
    }
    
    // PAAS optional (liefert kritische Infos für Layer 3)
    paas?: #PAASConfig
    
    // Platform Identity optional
    identity?: #PlatformIdentityConfig
    
    // Netzwerk immer erforderlich
    network: { defaults: #NetworkDefaults }
}
```

---

## 4. Layer 3: Applications

### 4.1 Verantwortungsbereich

Layer 3 enthält die **eigentlichen Benutzer-Anwendungen**. Diese werden NICHT per OpenTofu/Terraform deployed, sondern über die PAAS-Plattform aus Layer 2.

### 4.2 Managed by PAAS

```
Benutzer → Dokploy/Coolify → Docker Container auf dem Server

NICHT: Benutzer → Terraform → Docker Container
```

**Warum?** PAAS-Plattformen bieten:
- Web-UI zum Deployment
- Git-basierte Deploys
- Rolling Updates
- Log-Viewer
- Einfache Rollbacks

### 4.3 Standard-Anwendungen pro Variant

| Service | Typ | base-homelab | dev-homelab | modern-homelab |
|---------|-----|:---:|:---:|:---:|
| Uptime Kuma | Monitoring | ✅ | ✅ | ✅ |
| Beszel | Metrics | ⚪ | ⚪ | ✅ |
| Dozzle | Logs | ✅ | ✅ | ⚪ |
| Whoami | Test | ✅ | ✅ | ⚪ |
| Prometheus | Metrics | ⚪ | ⚪ | ✅ |
| Grafana | Dashboards | ⚪ | ⚪ | ✅ |
| Loki | Log-Aggregation | ⚪ | ⚪ | ✅ |

### 4.4 CUE-Validierung

```cue
#Layer3Applications: {
    services: [string]: #ServiceDefinition
    
    // Keine PAAS-Services in Layer 3 (die gehören zu Layer 2)
    _applicationServices: [
        for name, svc in services
        if svc.type != "paas" { name }
    ]
    _hasOnlyApplicationServices: len(_applicationServices) == len(services)
}
```

---

## 5. StackKit-Varianten im Detail

### 5.1 Übersicht

```
                       StackKits
          ┌──────────────┼──────────────┐
          │              │              │
    ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐ ┌───────────┐
    │   base-   │ │   dev-    │ │  modern-  │ │    ha-    │
    │  homelab  │ │  homelab  │ │  homelab  │ │  homelab  │
    │  v2.0 ✅  │ │  v2.0 🏗️  │ │  v0.1 📝  │ │  v1.0 📝  │
    └─────┬─────┘ └───────────┘ └───────────┘ └───────────┘
          │
    ┌─────┼─────────┬───────────┬───────────┐
    │     │         │           │           │
 default coolify  beszel    minimal     secure
```

### 5.2 base-homelab – "Mein erster Home-Server"

**Use Case**: Einzelner Server, lokal oder mit Domain, Docker-basiert.

| Eigenschaft | Wert |
|-------------|------|
| **Nodes** | Exakt 1 |
| **Platform** | Docker |
| **Zielgruppe** | Einsteiger bis Fortgeschrittene |
| **Maturity** | ⭐ Stable (v2.0) |

#### Service-Varianten

| Variante | PAAS | Monitoring | Identity | Extras | Domain nötig? |
|----------|------|-----------|----------|--------|:---:|
| **default** | Dokploy | Uptime Kuma | — | Dozzle, Whoami | Nein |
| **coolify** | Coolify | Uptime Kuma | — | Dozzle, Whoami | **Ja** |
| **beszel** | Dokploy | Beszel | — | Dozzle, Whoami | Nein |
| **minimal** | Dockge | Netdata | — | Portainer | Nein |
| **secure** | Dokploy | Uptime Kuma | TinyAuth | Dozzle, Whoami | Nein |

#### OS-Varianten

| OS | Firewall | Init-System | Besonderheiten |
|----|----------|-------------|----------------|
| **Ubuntu 24.04** (default) | UFW | systemd | Snap deaktiviert |
| **Ubuntu 22.04** | UFW | systemd | LTS, breite Unterstützung |
| **Debian 12** | nftables | systemd | Leichtgewichtig, weniger Overhead |

#### Compute-Tiers (automatisch erkannt)

| Tier | CPU | RAM | Max Container | Monitoring | Services |
|------|-----|-----|:---:|------------|----------|
| **Low** | 2-3 | 4-7 GB | 10 | Glances | Traefik, Dockge, Dozzle |
| **Standard** | 4-7 | 8-15 GB | 20 | Netdata | + Standard-Set |
| **High** | 8+ | 16+ GB | 50 | Prometheus+Grafana | + Full Monitoring |

### 5.3 dev-homelab – "Entwicklungsumgebung"

**Use Case**: Entwicklung und Testing der StackKit-Infrastruktur selbst.

| Eigenschaft | Wert |
|-------------|------|
| **Nodes** | 1 |
| **Platform** | Docker |
| **Zero-Trust** | Mandatorisch (TinyAuth + LLDAP + Step-CA) |
| **Maturity** | 🏗️ Beta (v2.0) |

**Besonderheiten**:
- Alle 3 Layer vollständig definiert
- TinyAuth standardmäßig aktiviert (nicht wie in base-homelab optional)
- PocketID als OIDC-Provider vorbereitet
- E2E-Test-Suite mit 549 Zeilen

### 5.4 modern-homelab – "Multi-Server Hybrid" (v1.1 geplant)

**Use Case**: Cloud + Local Nodes, VPN-Overlay, Public Access.

| Eigenschaft | Wert |
|-------------|------|
| **Nodes** | 2+ (min. 1 Cloud + 1 Local) |
| **Platform** | Docker + Coolify (Pflicht) |
| **VPN** | Headscale/Tailscale Overlay |
| **Maturity** | 📝 Alpha (v0.1) |

**Besonderheiten**:
- Erzwingt Coolify (Dokploy unterstützt kein Multi-Node)
- Headscale für sichere Node-zu-Node-Kommunikation
- PLG-Stack (Prometheus + Loki + Grafana) für Observability
- Cloud-Provider-Integration (Hetzner, DigitalOcean, Vultr, Linode, Proxmox)

### 5.5 ha-homelab – "High Availability" (v1.2 geplant)

**Use Case**: Docker Swarm Cluster mit Ausfallsicherheit.

| Eigenschaft | Wert |
|-------------|------|
| **Nodes** | 3+ (ungerade Anzahl Manager) |
| **Platform** | Docker Swarm |
| **HA** | Raft-Quorum, VIP-Failover, Shared Storage |
| **Maturity** | 📝 Scaffold (v1.0-alpha) |

**Besonderheiten**:
- Manager-Count MUSS ungerade sein (3, 5, oder 7)
- Shared Storage: GlusterFS (default), MinIO für Object Storage
- Traefik HA als replicated/global Swarm Service
- Overlay-Network-Encryption
- Enterprise-Variante mit Thanos + HAProxy
- Restic für Volume-Backups (verschlüsselt, off-site)

---

## 6. Use Cases & Entscheidungswege

### 6.1 Welcher StackKit für mich?

```
START
  │
  ├─▶ Wie viele Server?
  │     │
  │     ├─ 1 Server ──────────────▶ base-homelab
  │     │                            │
  │     │                            ├─ Eigene Domain? → coolify Variante
  │     │                            ├─ Kein Domain?   → default (Dokploy)
  │     │                            ├─ Monitoring?    → beszel Variante
  │     │                            ├─ Minimal?       → minimal Variante
  │     │                            └─ Auth nötig?    → secure Variante
  │     │
  │     ├─ 2+ Server (mixed) ─────▶ modern-homelab (v1.1)
  │     │   (Cloud + Local)
  │     │
  │     └─ 3+ Server (HA) ────────▶ ha-homelab (v1.2)
  │         (Ausfallsicher)
  │
  ├─▶ Entwicklung/Testing? ────────▶ dev-homelab
  │
  └─▶ END
```

### 6.2 Variant-Entscheidungsbaum (base-homelab)

```
base-homelab
  │
  ├─▶ Hast du eine eigene Domain?
  │     │
  │     ├─ JA ─▶ Brauchst du Git-Deploys?
  │     │         ├─ JA ──▶ ✅ coolify
  │     │         └─ NEIN ─▶ ✅ default (Dokploy, mit Domain)
  │     │
  │     └─ NEIN ─▶ Wie viel Ressourcen?
  │                 ├─ Minimal (2 CPU, 4GB) ──▶ ✅ minimal
  │                 ├─ Standard (4 CPU, 8GB) ─▶ ✅ default
  │                 └─ Viel (8+ CPU, 16GB) ───▶ ✅ default + High Tier
  │
  ├─▶ Brauchst du Server-Monitoring (CPU, RAM, Disk)?
  │     └─ JA ──▶ ✅ beszel
  │
  └─▶ Willst du Auth vor allen Services?
        └─ JA ──▶ ✅ secure
```

### 6.3 Deployment-Mode-Entscheidung

```
  ┌────────────────────────────────┐
  │  Brauchst du Drift Detection?  │
  │  Auto-Updates? Compliance?     │
  └───────────────┬────────────────┘
                  │
        ┌─────────▼─────────┐
        │                   │
   ┌────┤   NEIN      JA    ├────┐
   │    │                   │    │
   │    └───────────────────┘    │
   │                             │
   ▼                             ▼
 SIMPLE                      ADVANCED
 • OpenTofu only             • OpenTofu + Terramate
 • Day-1: init/plan/apply   • Day-1: init/plan/apply  
 • Day-2: manuell           • Day-2: drift/update/destroy
 • Schnell, einfach         • Stack-Ordering
                             • Rolling Updates
                             • Change-Sets
```

---

## 7. Deployment-Modi: Simple vs Advanced

### 7.1 Simple Mode (Default)

```
Benutzer → stackkit init → stack-spec.yaml
                              ↓
         stackkit generate → OpenTofu-Dateien (main.tf, variables.tf, ...)
                              ↓
         stackkit plan    → tofu plan (Vorschau)
                              ↓
         stackkit apply   → tofu apply (Deployment via SSH)
                              ↓
         Server ist konfiguriert ✅
```

**Lifecycle**: Plan → Apply → (manuell) Destroy. Keine automatische Drift-Detection.

### 7.2 Advanced Mode (Terramate)

```
Benutzer → stackkit init --mode advanced
                              ↓
         stackkit generate → Terramate Stacks + OpenTofu Modules
                              ↓
         ┌────────────────────┼────────────────────┐
         │                    │                    │
    Stack: network       Stack: services      Stack: apps
    (Order: 1)           (Order: 2)            (Order: 3)
    - Docker Networks    - Traefik             - Deployed via PAAS
    - DNS                - Monitoring          
                         - PAAS               
                              ↓
         terramate run -- tofu apply (geordnet, Stack für Stack)
                              ↓
         Cron: terramate run --drift-only (alle 6h)
                              ↓
         Bei Drift → Automatischer Alert + Optional Auto-Fix
```

---

## 8. OpenTofu im Detail

### 8.1 Was ist OpenTofu?

OpenTofu ist der Open-Source-Fork von Terraform (nach der HashiCorp-Lizenzänderung). Es ist funktional identisch zu Terraform, aber unter der Linux Foundation mit MPL-2.0-Lizenz.

### 8.2 Rolle in StackKits

OpenTofu ist der **Execution Engine** für Layer 1 und Layer 2:

```
CUE-Schema (Validierung)
    ↓
stack-spec.yaml (Benutzereingabe)
    ↓
OpenTofu Templates (Go-Templates → .tf-Dateien)
    ↓
tofu init → tofu plan → tofu apply
    ↓
Server-Konfiguration via remote-exec & Docker Provider
```

### 8.3 Provider

| Provider | Zweck |
|----------|-------|
| `hashicorp/null` | remote-exec für System-Konfiguration |
| `kreuzwerker/docker` | Docker-Container, Networks, Volumes |
| `cloudflare/cloudflare` | DNS für Public-Domains (optional) |
| `hetzner/hcloud` | Cloud-Server-Bereitstellung (modern-homelab) |

### 8.4 State-Management

| Mode | State-Backend | Use Case |
|------|--------------|----------|
| **Simple (Default)** | Lokale Datei (`terraform.tfstate`) | Entwicklung, einzelner Admin |
| **Advanced** | S3-kompatibel (MinIO, AWS S3) | Team, Produktion |

**Empfehlung**: Für produktive Nutzung sollte der State NICHT lokal liegen. Ein S3-Backend (z.B. MinIO auf dem Server selbst) bietet Locking und Versionierung.

### 8.5 Typische Terraform-Module (Soll-Zustand)

```
modules/
├── bootstrap/        # System-Vorbereitung (apt, user, swap)
├── docker/           # Docker-Installation & -Konfiguration
├── identity/
│   ├── lldap/        # LLDAP-Container + Konfiguration
│   └── step-ca/      # Step-CA + Provisioner-Setup
├── network/
│   ├── local/        # Bridge-Network, mDNS
│   ├── public/       # Traefik, Let's Encrypt
│   └── hybrid/       # VPN + Split-DNS
├── platform/
│   ├── dokploy/      # Dokploy-Container + DB
│   └── coolify/      # Coolify-Container
├── security/
│   ├── ssh/          # SSH-Härtung
│   ├── firewall/     # UFW/nftables
│   └── fail2ban/     # Intrusion-Prevention
└── observability/
    ├── monitoring/   # Prometheus/Netdata/Beszel
    └── logging/      # Dozzle/Loki
```

### 8.6 Aktueller Ist-Zustand

**⚠️ Aktuell** werden KEINE Module verwendet. Es gibt eine monolithische `main.tf` (1130 Zeilen) als statisches Template. Die CUE-Schemas validieren die Konfiguration, aber die `.tf`-Dateien werden via Go-Template-Rendering erzeugt, NICHT aus CUE exportiert.

**Bridge**: `internal/cue/bridge.go` generiert `terraform.tfvars.json` aus CUE – dies ist die Schnittstelle zwischen CUE-Schemas und OpenTofu.

---

## 9. Terramate im Detail

### 9.1 Was ist Terramate?

Terramate ist ein **Orchestrierungs-Tool für Terraform/OpenTofu**. In StackKits wird es primär für **Drift Detection und Day-2 Operations** eingesetzt:
- **Drift-Detection**: Erkenne Konfigurationsabweichungen zwischen Soll und Ist
- **Day-2 Operations**: Geplante Updates, Rolling Changes, Compliance-Checks
- **Stack-Ordering**: Deploye in korrekter Reihenfolge (Netzwerk VOR Services)
- **Change-Detection**: Deploye nur geänderte Stacks

### 9.2 Rolle in StackKits (Advanced Mode)

```
Terramate
    │
    ├── Stack: foundation (Order: 1)
    │     └── OpenTofu: bootstrap, ssh, firewall, lldap, step-ca
    │
    ├── Stack: platform (Order: 2, depends on: foundation)
    │     └── OpenTofu: docker, traefik, dokploy, tinyauth
    │
    └── Stack: applications (Order: 3, depends on: platform)
          └── OpenTofu: monitoring, logging configs
          └── PAAS: User-Apps (Uptime Kuma etc.)
```

### 9.3 Terramate-Konfiguration (Soll-Zustand)

```hcl
# terramate.tm.hcl (Root-Level)
terramate {
  config {
    git {
      default_branch = "main"
    }
  }
}

globals {
  stackkit_version = "2.0.0"
  deployment_mode  = "advanced"
}
```

```hcl
# stacks/foundation/stack.tm.hcl
stack {
  name        = "foundation"
  description = "Layer 1: System, Security, Identity"
  tags        = ["layer:1", "foundation"]
  
  after = []  # Keine Abhängigkeiten
}

generate_hcl "_terramate_generated.tf" {
  content {
    variable "domain" {
      type    = string
      default = global.domain
    }
  }
}
```

```hcl
# stacks/platform/stack.tm.hcl
stack {
  name        = "platform"
  description = "Layer 2: Docker, Traefik, PAAS"
  tags        = ["layer:2", "platform"]
  
  after = ["tag:layer:1"]  # Erst nach Foundation
}
```

### 9.4 Terramate-Befehle

| Befehl | Zweck |
|--------|-------|
| `terramate list` | Alle Stacks anzeigen (in Abhängigkeitsreihenfolge) |
| `terramate run -- tofu plan` | Plan für alle Stacks (geordnet) |
| `terramate run -- tofu apply` | Apply für alle Stacks (geordnet) |
| `terramate run --changed -- tofu plan` | Nur geänderte Stacks planen |
| `terramate run --filter tag:layer:1 -- tofu apply` | Nur Layer 1 deployen |
| `terramate experimental trigger --status=drifted` | Drift-Detection starten |

### 9.5 Drift-Detection

```yaml
# Geplanter Cron-Job (alle 6 Stunden)
schedule: "0 */6 * * *"

# Ablauf:
# 1. terramate run -- tofu plan -detailed-exitcode
# 2. Exit Code 2 = Drift erkannt
# 3. Alert via Notification-Channel
# 4. Optional: Auto-Apply bei non-breaking Drift
```

### 9.6 Aktueller Ist-Zustand

**⚠️ Terramate ist NICHT in die CLI integriert.** Es existieren:
- Ein Scaffold in `base-homelab/templates/advanced/terramate.tm.hcl` (55 Zeilen)
- Ein Drift-Template in `base/lifecycle/_drift.tf.tmpl`
- Keine Terramate-Befehle in `cmd/stackkit/commands/`
- `internal/terramate/` Package existiert als leerer Ordner

---

## 10. Zusammenspiel: CUE → OpenTofu → Terramate

### 10.1 Vollständiger Datenfluss (Soll-Zustand)

```
┌─────────────────────────────────────────────────────┐
│                    BENUTZER                          │
│                                                     │
│  1. stackkit init base-homelab                      │
│     → Erstellt stack-spec.yaml                      │
│                                                     │
│  2. Benutzer editiert stack-spec.yaml               │
│     → IP, Domain, SSH-Key, Variante                 │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                 CUE VALIDATION                      │
│                                                     │
│  3. stackkit validate                               │
│     → Lädt stack-spec.yaml                          │
│     → Validiert gegen base/stackkit.cue             │
│     → Prüft Layer 1/2/3 Constraints                 │
│     → Prüft Variant-spezifische Regeln              │
│     → Exportiert terraform.tfvars.json              │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              TEMPLATE RENDERING                     │
│                                                     │
│  4. stackkit generate                               │
│     → Go-Template-Engine                            │
│     → base/bootstrap/_bootstrap.tf.tmpl → main.tf   │
│     → base/network/_local.tf.tmpl → network.tf      │
│     → base/identity/_lldap.tf.tmpl → identity.tf    │
│     → Variablen aus terraform.tfvars.json           │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          │  SIMPLE    │  ADVANCED  │
          ▼            │            ▼
┌─────────────────┐    │  ┌─────────────────────────┐
│   OPENTOFU      │    │  │    TERRAMATE             │
│                 │    │  │                           │
│  5a. tofu init  │    │  │  5b. terramate run \     │
│  5a. tofu plan  │    │  │      -- tofu init        │
│  5a. tofu apply │    │  │      -- tofu plan        │
│                 │    │  │      -- tofu apply        │
│  (Alles auf     │    │  │  (Stack für Stack,       │
│   einmal)       │    │  │   geordnet)              │
└────────┬────────┘    │  └────────────┬──────────────┘
         │             │               │
         └─────────────┼───────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                   SERVER                            │
│                                                     │
│  Layer 1: System + SSH + Firewall + LLDAP + StepCA  │
│  Layer 2: Docker + Traefik + Dokploy                │
│  Layer 3: Apps via Dokploy (Uptime Kuma etc.)       │
└─────────────────────────────────────────────────────┘
```

### 10.2 CUE als Single Source of Truth

```
                     CUE-Schemas (base/)
                          │
            ┌─────────────┼─────────────┐
            │             │             │
            ▼             ▼             ▼
      Validierung    tfvars.json    Dokumentation
      (cue vet)      (cue export)   (cue export --format)
            │             │
            ▼             ▼
      Fehler-Report  OpenTofu-Input
                          │
                          ▼
                    Deployment
```

**Aktueller Gap**: CUE generiert aktuell nur `tfvars.json` (bridge.go). Die `.tf`-Dateien sind statische Templates. Der Idealzustand wäre:
1. CUE validiert den User-Input
2. CUE exportiert `terraform.tfvars.json` mit allen berechneten Werten
3. Statische `.tf`-Module lesen die Variablen
4. OpenTofu/Terramate führt aus

---

## 11. Add-On-System

### 11.1 Was sind Add-Ons?

Add-Ons sind **Erweiterungen und Modifikationen der StackKit-Standards**. Sie erlauben es, die Standard-Konfiguration eines StackKits an individuelle Bedürfnisse anzupassen, ohne den StackKit selbst zu verändern.

### 11.2 Arten von Add-Ons

| Add-On-Typ | Beschreibung | Beispiel |
|------------|-------------|---------|
| **Multi-Server** | Erweitert Single-Server-Konzept auf N Server | base-homelab + 2. Server |
| **Tool-Add-On** | Fügt zusätzliche Tools/Services hinzu | + Vaultwarden, + Nextcloud |
| **Hardware-Add-On** | Passt an Hardware-Constraints an | ARM-Support, GPU-Workloads, Low-Memory |
| **Provider-Add-On** | Erweitert um Cloud-Provider-Features | Hetzner-Firewall, Azure-DNS |

### 11.3 CUE-Schema (geplant)

```cue
#AddOn: {
    name:        string
    displayName: string
    description: string
    
    // Welche StackKits sind kompatibel?
    compatibleWith: [...string]  // z.B. ["base-homelab", "dev-homelab"]
    
    // Was wird modifiziert?
    modifies: {
        nodes?:    _         // Kann Node-Count ändern
        services?: _         // Kann Services hinzufügen/ändern
        network?:  _         // Kann Networking anpassen
        security?: _         // Kann Security-Policies erweitern
    }
    
    // Validierungsregeln
    requires?: [...string]   // Abhängige Add-Ons
    conflicts?: [...string]  // Inkompatible Add-Ons
}
```

### 11.4 Datenfluss mit Add-Ons

```
kombination.yaml (StackKit: base-homelab + Add-On: multi-server)
    ↓
CUE-Validierung: StackKit-Schema + Add-On-Schema
    ↓
Merged Config: base-homelab mit 2 Nodes statt 1
    ↓
OpenTofu: 2x remote-exec (Node 1 + Node 2)
```

### 11.5 Auto-Detection Add-Ons (kombify Stack)

Der kombify Stack Orchestrator erkennt einige Add-Ons automatisch basierend auf der Node-Konfiguration:

| Auto-Add-On | Trigger | Aktion |
|-------------|---------|--------|
| `cloud-integration` | Node mit `type: "cloud"` | Cloud-Provider-APIs aktivieren |
| `arm-support` | Node mit ARM-Architektur | ARM-kompatible Images verwenden |
| `gpu-workloads` | Node mit GPU | NVIDIA Container Runtime aktivieren |
| `low-memory` | Node mit < 4GB RAM | Service-Auswahl einschränken |

---

## 12. Backend-Split: Local vs Cloud

### 12.1 Konzept

Für den Benutzer in der UI gibt es nur **"base-homelab"**. Im Backend werden zwei verschiedene Provisionierungspfade unterstützt:

```
           ┌────────────────────────┐
           │  UI: "base-homelab"    │
           │  (einheitliche Sicht)  │
           └───────────┬────────────┘
                       │
              ┌────────┴────────┐
              │                 │
    ┌─────────▼──────────┐  ┌──▼──────────────────┐
    │ base-homelab-local │  │ base-homelab-cloud   │
    │                    │  │                      │
    │ • SSH via LAN      │  │ • Cloud-Provider-API │
    │ • Wake-on-LAN      │  │ • SSH via Internet   │
    │ • physisches Netz  │  │ • Floating IPs       │
    │ • Kein Provider    │  │ • Provider: Hetzner, │
    │   nötig            │  │   Azure, DO, Vultr   │
    └────────────────────┘  └──────────────────────┘
```

### 12.2 Unterschiede im CUE-Schema

| Feature | Local | Cloud |
|---------|-------|-------|
| SSH-Port | Konfigurierbar (22 oder custom) | 22 (default) |
| SSH-User | admin / custom | root (mit SSH-Key) |
| Netzwerk | Bridge, LAN-IP | Public IP + VPC |
| DNS | mDNS / Pi-hole | Cloud-DNS (Cloudflare, etc.) |
| Firewall | UFW lokal | Cloud-Firewall + UFW |
| Storage | Lokale Disks | Cloud Volumes |
| Backup-Ziel | NAS / USB / NFS | S3 / Object Storage |

### 12.3 Hybrid-Konfiguration

Wenn ein Benutzer Local + Cloud Nodes kombiniert, wird **VPN-Bridging** verwendet:

```
Local Node (192.168.1.x)  ←── VPN Tunnel ──→  Cloud Node (Public IP)
       │                                              │
       └──── Gemeinsames Overlay Network ─────────────┘
                   (Headscale/WireGuard)
```

---

## 13. Persona-basierte Empfehlungen

### 13.1 Konzept

Der **Persona-Typ** des Benutzers bestimmt die Standardkonfiguration und ob Local oder Cloud empfohlen wird. Dies geschieht im kombify Stack Wizard (UI) vor der StackKit-Auswahl.

### 13.2 Persona-Matrix

| Persona | Intent | Empfehlung | Default-Variante |
|---------|--------|-----------|-------------------|
| **Einfachheit** | "Ich will es einfach zum Laufen bringen" | ☁️ Cloud | base-homelab-cloud, default |
| **Freiheit / Techie** | "Ich will volle Kontrolle über alles" | 🏠 Local | base-homelab-local, default |
| **Sicherheit** | "Datenschutz und Hoheit über Daten" | 🏠 Local | base-homelab-local, secure |
| **Komfort** | "Möglichst wenig Aufwand nach Setup" | ☁️ Cloud | base-homelab-cloud, default |
| **Konkretes Ziel** | "Ich brauche spezifisch X" | 🔀 Abhängig | Ziel-basierte Empfehlung |
| **Neugieriger Entdecker** | "Ich will lernen und experimentieren" | 🏠 Local | dev-homelab |

### 13.3 Entscheidungsbaum (Wizard)

```
START: "Was beschreibt dich am besten?"
    │
    ├─ Einfachheit ──────▶ Cloud empfohlen
    │                        │
    │                     "Hast du eine Domain?"
    │                        ├─ Ja → coolify
    │                        └─ Nein → default
    │
    ├─ Freiheit/Techie ──▶ Local empfohlen
    │                        │
    │                     "Hast du einen Server?"
    │                        ├─ Ja → base-homelab-local
    │                        └─ Nein → "Wir helfen bei der Auswahl"
    │
    ├─ Sicherheit ───────▶ Local + secure Variante
    │
    ├─ Komfort ──────────▶ Cloud + managed Services
    │
    ├─ Konkretes Ziel ───▶ Service-Katalog → passende Empfehlung
    │
    └─ Entdecker ────────▶ dev-homelab (local)
```

### 13.4 Auswirkung auf CUE-Konfiguration

Die gewählte Persona setzt nur **Defaults**, die der Benutzer überschreiben kann:

```cue
// Persona-basierte Defaults (generiert durch Wizard)
_personaDefaults: {
    if _persona == "simplicity" {
        nodeType:    "cloud"
        variant:     "default"
        monitoring:  "basic"     // Uptime Kuma only
    }
    if _persona == "techie" {
        nodeType:    "local"
        variant:     "default"
        monitoring:  "advanced"  // Full monitoring stack
    }
    if _persona == "security" {
        nodeType:    "local"
        variant:     "secure"
        monitoring:  "advanced"
        identity:    "mandatory"
    }
}
```

---

## 14. Beyond-IaC: Runtime Intelligence Layer

### 14.1 Warum "Beyond-IaC"?

IaC (CUE → OpenTofu → Provisioning) ist das **Fundament** von kombify. Aber kombify ist **kein reines IaC-Tool**. Der eigentliche USP liegt darin, dass kombify nach dem initialen Setup als **lebende Plattform** weiterarbeitet:

- **Jedes registrierte Gerät** bekommt einen Worker-Agent
- **gRPC-Kommunikation** in Echtzeit zwischen Core und allen Nodes
- **AI Self-Healing** erkennt und behebt Probleme automatisch
- **AI-gestützte Node-Workers** optimieren Ressourcen und erkennen Anomalien
- **Add-Ons** haben aktives Runtime-Verhalten, nicht nur IaC-Templates
- **Integration Paths** verbinden das Homelab mit externen Systemen

### 14.2 Architektonische Einordnung

```
┌─────────────────────────────────────────────────────────────┐
│            BEYOND-IaC: RUNTIME INTELLIGENCE LAYER           │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │  AI Self-Healing │  │  AI Node Workers │                │
│  │  ─ Anomaly Det.  │  │  ─ Resource Opt. │                │
│  │  ─ Auto-Repair   │  │  ─ Predictive    │                │
│  │  ─ Rollback      │  │  ─ Health Score  │                │
│  └────────┬─────────┘  └────────┬─────────┘                │
│           │                     │                           │
│  ┌────────▼─────────────────────▼─────────┐                │
│  │         gRPC Agent Network             │                │
│  │  ─ CommandStream (bidirektional)       │                │
│  │  ─ Heartbeat (~30s)                    │                │
│  │  ─ ReportStatus                        │                │
│  │  ─ mTLS verschlüsselt                 │                │
│  └────────┬───────────────────────────────┘                │
│           │                                                 │
│  ┌────────▼────────┐  ┌──────────────────┐                 │
│  │  Add-On Runtime │  │ Integration Paths│                 │
│  │  ─ Health Checks│  │ ─ DNS Provider   │                 │
│  │  ─ Auto-Scaling │  │ ─ Monitoring SaaS│                 │
│  │  ─ Lifecycle    │  │ ─ Notifications  │                 │
│  │    Hooks        │  │ ─ CI/CD Webhooks │                 │
│  └─────────────────┘  └──────────────────┘                 │
│                                                             │
│  ┌──────────────────────────────────────────┐              │
│  │         Komfort-Features (UI)            │              │
│  │  ─ Update-Benachrichtigungen             │              │
│  │  ─ Dashboard-Konfiguration               │              │
│  │  ─ Onboarding-Assistenz                  │              │
│  │  ─ Community-Integration                 │              │
│  └──────────────────────────────────────────┘              │
├─────────────────────────────────────────────────────────────┤
│  IaC-MANAGED: CUE → OpenTofu → Provisioning               │
│  Layer 3: Applications    │  PAAS-deployed Services        │
│  Layer 2: Platform        │  Docker, Reverse Proxy, PAAS   │
│  Layer 1: Foundation      │  OS, SSH, Firewall, PKI        │
└─────────────────────────────────────────────────────────────┘
```

### 14.3 Worker Agent Architektur

Auf **jedem registrierten Gerät** (Node) läuft ein **kombify Stack Agent** — ein Go-Binary, das über gRPC mit mTLS mit dem Core kommuniziert.

#### Agent-Lifecycle

```
1. REGISTRATION
   Agent startet → Register(NodeCapabilities) → Core speichert Node
   
2. HEARTBEAT LOOP
   Alle ~30s: Heartbeat(metrics) → Core aktualisiert Node-Status
   
3. COMMAND EXECUTION
   Core sendet über CommandStream:
   ─ ContainerDeploy    (Service starten/updaten)
   ─ ContainerStop      (Service stoppen)
   ─ SystemUpdate       (OS-Updates einspielen)
   ─ HealthCheck        (Service-Gesundheit prüfen)
   ─ DiagnosticsCollect (Logs/Metriken sammeln)
   
4. STATUS REPORTING
   Agent → ReportStatus(progress, logs, errors) → Core
   
5. PRE-CHECKS (vor Deployments)
   Core → RunPreChecks(requirements) → Agent prüft Voraussetzungen
```

#### Agent-Capabilities (bei Registration)

```cue
#NodeCapabilities: {
    hostname:     string
    os:           "linux" | "darwin"
    arch:         "amd64" | "arm64" | "armv7"
    cpuCores:     int & >=1
    memoryMB:     int & >=512
    diskGB:       int & >=10
    dockerVersion: string
    gpuAvailable: bool
    networkInterfaces: [...string]
    labels:       {[string]: string}  // z.B. {"role": "worker", "location": "rack1"}
}
```

### 14.4 AI Self-Healing Pipeline

Die AI-Self-Healing-Pipeline ermöglicht es kombify, Probleme **ohne menschliches Eingreifen** zu erkennen und zu beheben.

#### Pipeline-Stufen

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   DETECT     │    │   DIAGNOSE   │    │    HEAL      │
│              │    │              │    │              │
│ • Heartbeat  │───▶│ • Log-Analyse│───▶│ • Container  │
│   Timeout    │    │ • Resource-  │    │   Restart    │
│ • Health     │    │   Korrelation│    │ • Config     │
│   Check Fail │    │ • Pattern    │    │   Rollback   │
│ • Resource   │    │   Matching   │    │ • Resource   │
│   Anomalie   │    │ • AI-basiert │    │   Rebalance  │
│ • Service    │    │   Root Cause │    │ • Eskalation │
│   Crash      │    │   Analysis   │    │   an User    │
└──────────────┘    └──────────────┘    └──────────────┘
```

#### Eskalationsmodell

| Schweregrad | Aktion | Automatisch? |
|-------------|--------|:---:|
| **Low** | Container-Restart | ✅ |
| **Medium** | Service-Rollback auf letzte gute Config | ✅ |
| **High** | Resource-Rebalancing über Nodes | ✅ (mit Bestätigung) |
| **Critical** | User-Benachrichtigung + Diagnose-Report | ❌ (manuell) |

### 14.5 AI-Assisted Node Workers

Jeder Agent kann mit einem **AI-Modul** erweitert werden, das lokal auf dem Node läuft:

| Fähigkeit | Beschreibung |
|-----------|-------------|
| **Resource Prediction** | Vorhersage von CPU/RAM-Spitzen basierend auf historischen Daten |
| **Anomaly Detection** | Erkennung ungewöhnlicher Muster (Netzwerk-Traffic, Disk-I/O) |
| **Health Scoring** | Zusammenfassung des Node-Gesundheitszustands als Score (0-100) |
| **Smart Scheduling** | Empfehlungen, wann Maintenance-Fenster am besten passen |
| **Log Intelligence** | Automatische Kategorisierung und Priorisierung von Log-Einträgen |

### 14.6 Integration Paths

Integration Paths verbinden das Homelab mit externen Systemen — über definierte Schnittstellen:

```cue
#IntegrationPath: {
    name:        string
    type:        "webhook" | "rest-api" | "grpc" | "mqtt" | "dns-api"
    direction:   "inbound" | "outbound" | "bidirectional"
    auth:        #IntegrationAuth
    retryPolicy: #RetryPolicy
    events:      [...#IntegrationEvent]
}

#IntegrationAuth: {
    method: "api-key" | "oauth2" | "mTLS" | "bearer-token" | "none"
    // Details je nach method
}

#IntegrationEvent: {
    trigger:  string   // z.B. "service.deployed", "health.degraded"
    action:   string   // z.B. "notify", "update-dns", "trigger-pipeline"
    target:   string   // z.B. "slack://webhook", "cloudflare://dns"
}
```

#### Beispiel-Integrationen

| Integration | Typ | Richtung | Beispiel-Events |
|------------|-----|----------|-----------------|
| **Cloudflare DNS** | dns-api | outbound | Service deployed → DNS-Record anlegen |
| **Slack/Discord** | webhook | outbound | Health degraded → Alert senden |
| **Uptime Kuma** | rest-api | bidirectional | Status-Sync, Heartbeat-Forwarding |
| **GitHub Actions** | webhook | inbound | Push → Redeploy Service |
| **Prometheus** | rest-api | outbound | Metriken exportieren |
| **Home Assistant** | mqtt | bidirectional | IoT-Geräte ↔ Homelab Status |

### 14.7 Add-On Runtime-Verhalten

Add-Ons in kombify sind **mehr als statische IaC-Templates**. Sie haben aktives Runtime-Verhalten, das über den Agent ausgeführt wird:

```cue
#AddOnRuntime: {
    // Lifecycle-Hooks (vom Agent ausgeführt)
    hooks: {
        preInstall?:   [...#AgentCommand]  // Vor der Installation
        postInstall?:  [...#AgentCommand]  // Nach der Installation
        preUpdate?:    [...#AgentCommand]  // Vor einem Update
        postUpdate?:   [...#AgentCommand]  // Nach einem Update
        healthCheck?:  #HealthCheckSpec    // Regelmäßige Gesundheitsprüfung
    }
    
    // Runtime-Policies
    policies: {
        autoUpdate:      bool | *false     // Automatische Updates?
        restartPolicy:   "always" | "on-failure" | "never" | *"on-failure"
        resourceLimits?: #ResourceLimits   // CPU/RAM-Grenzen
        scalingPolicy?:  #ScalingPolicy    // Auto-Scaling Regeln
    }
    
    // Integration-Points
    integrations: [...#IntegrationPath]    // Externe Anbindungen
}
```

### 14.8 Abgrenzung: IaC vs. Beyond-IaC

| Aspekt | IaC (Layer 1-3) | Beyond-IaC (Runtime Intelligence) |
|--------|:---:|:---:|
| **Zeitpunkt** | Day-0 / Day-1 (Provisioning) | Day-2+ (Laufzeit) |
| **Verantwortung** | OpenTofu + CUE | Agent + Core + AI |
| **State** | Terraform State | PocketBase + Agent-Metriken |
| **Kommunikation** | SSH (remote-exec) | gRPC (mTLS, bidirektional) |
| **Fehlerbehandlung** | Plan fehlgeschlagen → Abbruch | Anomalie → AI Diagnose → Auto-Heal |
| **Schema-Quelle** | CUE Schemas (StackKits) | CUE + Runtime-Definitionen |
| **User-Interaktion** | kombination.yaml + Wizard | Dashboard + Notifications + AI-Reports |

**Wichtig**: Der Beyond-IaC Layer ist **kein Komfort-Addon** — er ist ein **Kern-Differenzierer**, der kombify von reinen IaC-Tools wie Ansible, Terraform oder NixOS unterscheidet. Er macht aus einer einmaligen Provisionierung eine **kontinuierlich verwaltete Plattform**.

---

## 15. kombify Stack Integration

### 15.1 Überblick

StackKits sind **kein eigenständiges Produkt**, sondern Teil des größeren **kombify Stack Orchestrators**. Der Orchestrator besteht aus:

| Komponente | Technologie | Rolle |
|------------|-------------|-------|
| **Core** | Go Binary | API-Server, Unifier Engine, Job Queue |
| **Frontend** | SvelteKit | UI Wizard, Dashboard, Monitoring |
| **Agent** | Go Binary (gRPC) | Läuft auf Worker-Nodes, führt Befehle aus |
| **StackKits** | CUE-Schemas | Validierung und Konfigurationslogik |

### 15.2 Unifier-Pipeline

Die Unifier-Pipeline ist das Herzstück des Orchestrators. Sie transformiert den Benutzer-Intent in ausführbare IaC-Konfigurationen:

```
┌──────────────┐    ┌─────────────────┐    ┌──────────────────┐
│  kombination │    │   IntentSpec    │    │  Requirements    │
│    .yaml     │ ─▶ │  (Was will     │ ─▶ │  Spec (Was wird  │
│  (User-Input)│    │   der User?)   │    │  tatsächlich     │
└──────────────┘    └────────────────┘    │  gebraucht?)     │
                                          └────────┬─────────┘
                                                   │
                          ┌────────────────────────┘
                          ▼
               ┌──────────────────────┐
               │  StackKit-Resolver   │
               │  ─ Alias-Auflösung   │
               │  ─ Add-On-Erkennung  │
               │  ─ Varianten-Auswahl │
               └──────────┬───────────┘
                          │
                          ▼
               ┌──────────────────────┐    ┌──────────────────┐
               │  Worker-Auflösung   │    │  Unified Spec    │
               │  ─ Node-Zuweisung   │ ─▶ │  (Finale, vali-  │
               │  ─ Service-Placement│    │  dierte Config)  │
               │  ─ Resource-Check   │    └────────┬─────────┘
               └──────────────────────┘             │
                                                    ▼
                                         ┌──────────────────┐
                                         │  IaC-Generierung │
                                         │  ─ tfvars.json   │
                                         │  ─ OpenTofu Plan │
                                         │  ─ Apply         │
                                         └──────────────────┘
```

### 15.3 gRPC-Agent-Protokoll

Auf jedem Worker-Node läuft ein **kombify Stack Agent**, der über gRPC (mTLS) mit dem Core kommuniziert:

| RPC | Richtung | Beschreibung |
|-----|----------|-------------|
| `Register` | Agent → Core | Node registriert sich mit Capabilities |
| `Heartbeat` | Agent → Core | Regelmäßige Lebenszeichen (~30s) |
| `CommandStream` | Core → Agent | Bidirektionaler Befehlsstrom |
| `ReportStatus` | Agent → Core | Status-Updates (Provisioning-Fortschritt) |
| `RunPreChecks` | Core → Agent | Validierung vor dem Deployment |

### 15.4 Service-Placement-Algorithmus

Bei Multi-Node-Setups bestimmt der Placement-Algorithmus, welcher Service auf welchem Node läuft:

```
1. FILTER: Welche Nodes erfüllen die Anforderungen?
   ─ CPU ≥ service.resources.cpu
   ─ RAM ≥ service.resources.memory
   ─ Disk ≥ service.resources.disk
   ─ Node-Role kompatibel (manager/worker)

2. SCORE: Welcher Node ist am besten geeignet?
   ─ Ressourcen-Verfügbarkeit (mehr frei = besser)
   ─ Locality-Constraints (z.B. "muss auf Cloud-Node laufen")
   ─ Anti-Affinity (verteile replicas auf verschiedene Nodes)

3. PLACEMENT: Service wird dem best-scored Node zugewiesen
```

### 15.5 Datenfluss: StackKits ↔ kombify Stack

```
kombify Stack Core                    StackKits (CUE)
       │                                    │
       │  1. User wählt StackKit            │
       │─────────────────────────────────▶  │
       │                                    │  2. CUE validiert
       │  3. Validierte Config             │     kombination.yaml
       │◀─────────────────────────────────  │
       │                                    │
       │  4. Core generiert tfvars.json     │
       │  5. Core führt OpenTofu aus        │
       │  6. Agent auf Node meldet Status   │
```

---

## 16. Anhang: CUE-Schema-Referenz

### 16.1 Layer 1 Schemas

| Schema | Datei | Pflichtfelder |
|--------|-------|---------------|
| `#SystemConfig` | system.cue | timezone, locale, swap |
| `#BasePackages` | system.cue | manager, base, tools |
| `#SystemUsers` | system.cue | admin.name, service.name |
| `#SSHHardening` | security.cue | port, permitRootLogin, passwordAuth |
| `#FirewallPolicy` | security.cue | enabled, backend, defaultInbound |
| `#LLDAPConfig` | identity.cue | enabled, domain.base, admin.email |
| `#StepCAConfig` | identity.cue | enabled, pki.rootCommonName |
| `#ContainerSecurityContext` | security.cue | runAsNonRoot, privileged |
| `#SecretsPolicy` | security.cue | backend |
| `#TLSPolicy` | security.cue | minVersion, certSource |

### 16.2 Layer 2 Schemas

| Schema | Datei | Pflichtfelder |
|--------|-------|---------------|
| `#ContainerRuntime` | system.cue | engine |
| `#PAASConfig` | layers.cue | type, installMethod |
| `#DokployConfig` | layers.cue | enabled, version, port |
| `#CoolifyConfig` | layers.cue | enabled, version, port |
| `#TinyAuthConfig` | layers.cue | enabled, port, sessionSecret |
| `#PocketIDConfig` | layers.cue | enabled, publicAppUrl |
| `#NetworkDefaults` | network.cue | domain, subnet |

### 16.3 Layer 3 Schemas

| Schema | Datei | Pflichtfelder |
|--------|-------|---------------|
| `#ServiceDefinition` | stackkit.cue | name, type, image, network |
| `#ServiceNetworkConfig` | stackkit.cue | mode |
| `#HealthCheck` | observability.cue | enabled, interval, timeout |
| `#ResourceLimits` | stackkit.cue | — (alles optional) |

### 16.4 Entscheidungslogiken

| Schema | Datei | Entscheidet über |
|--------|-------|-----------------|
| `#TLSDecision` | validation.cue | ACME vs Self-Signed vs Custom vs None |
| `#BackupDecision` | validation.cue | Restic/Borg, Retention, Destination |
| `#AlertingDecision` | validation.cue | Channels (Email/Slack/Discord/Telegram) |
| `#DomainType` | validation.cue | Local (.local/.lan) vs Public |
| `#SmartDefaults` | defaults.cue | Services basierend auf Compute-Tier |

### 16.5 Validierungspatterns

| Validator | Pattern | Beispiel |
|-----------|---------|----------|
| `#Validators.ipv4` | IPv4-Adresse | `192.168.1.1` |
| `#Validators.cidr` | CIDR-Notation | `10.0.0.0/16` |
| `#Validators.fqdn` | Domain-Name | `app.example.com` |
| `#Validators.email` | E-Mail | `user@example.com` |
| `#Validators.semver` | Semantic Version | `v1.2.3-beta.1` |
| `#Validators.dockerImage` | Docker-Image | `ghcr.io/org/img` |
| `#Validators.duration` | Zeitdauer | `30s`, `5m`, `2h` |

---

*Ende der Dokumentation. Bei Fragen: [docs/architecture.md](architecture.md) für Übersicht, [docs/CLI.md](CLI.md) für CLI-Referenz.*

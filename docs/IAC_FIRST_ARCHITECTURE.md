# IaC-First Architecture für KombiStack StackKits

> **Status:** Approved Architecture  
> **Version:** 1.0  
> **Date:** 2026-01-08  
> **Authors:** KombiStack Team

---

## 📋 Executive Summary

KombiStack verwendet eine **IaC-First Architektur**, bei der:
- **OpenTofu** die primäre Execution-Engine ist (nicht Shell-Commands im Agent)
- **Terramate** für Orchestration und Day-2 Operations zuständig ist
- **Worker-Agents** nur als Thin-Layer für `tofu` und `terramate` Commands dienen
- **CUE** für Schema-Validation und StackKit-Definitionen verwendet wird

Diese Architektur ermöglicht:
- ✅ State-basiertes Drift Detection
- ✅ Deklarative, versionierbare Infrastructure
- ✅ Nutzung des Terraform Provider Ecosystems
- ✅ Einfache Rollbacks via State
- ✅ Minimale Eigenentwicklung

---

## 🏗️ Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        IaC-FIRST ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  LAYER 1: USER INTENT                                                        │
│  ─────────────────────                                                       │
│  kombination.yaml (IntentSpec)                                               │
│  ├── goals: { storage: true, media: true }                                  │
│  ├── network: { mode: "local" | "public" }                                  │
│  └── variant: "default" | "beszel" | "minimal"                              │
│                                                                              │
│  LAYER 2: UNIFIER PIPELINE                                                   │
│  ─────────────────────────                                                   │
│  Phase 1: IntentSpec Validation (CUE Schema)                                │
│  Phase 2: StackKit Selection + RequirementsSpec                             │
│  Phase 3: Worker Registration (Agent meldet System-Info)                    │
│  Phase 4: Validation (Requirements vs. actual Hardware)                     │
│  Phase 5: UnifiedSpec Generation                                            │
│  Phase 6: IaC Generation (OpenTofu HCL + Terramate)                         │
│                                                                              │
│  LAYER 3: GENERATED IaC                                                      │
│  ──────────────────────                                                      │
│  ├── terramate.tm.hcl     (Stack-Orchestration)                             │
│  ├── bootstrap.tf         (OS-Preparation via remote-exec)                  │
│  ├── network.tf           (Network Mode: local/public)                      │
│  ├── services.tf          (Docker Provider Resources)                       │
│  ├── outputs.tf           (URLs, Credentials)                               │
│  └── terraform.tfvars     (Resolved Variables)                              │
│                                                                              │
│  LAYER 4: AGENT EXECUTION (Thin Layer)                                       │
│  ─────────────────────────────────────                                       │
│  Agent führt NUR aus:                                                       │
│  ├── tofu init                                                              │
│  ├── tofu plan -out=plan.tfplan                                             │
│  ├── tofu apply plan.tfplan                                                 │
│  └── terramate run --sync-drift-status                                      │
│                                                                              │
│  LAYER 5: DAY-2 OPERATIONS (Terramate)                                       │
│  ─────────────────────────────────────                                       │
│  ├── Drift Detection: terramate run --sync-drift-status -- tofu plan       │
│  ├── Selective Updates: terramate run --changed -- tofu apply              │
│  └── Rollback: tofu apply mit altem State                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 IaC-First vs. Agent-First Vergleich

### ❌ Agent-First (NICHT verwenden)

```
User → Unifier → Agent Commands
                    ↓
         Agent führt Shell-Commands aus:
         • apt install docker
         • docker compose up
         • ufw allow 443
```

**Probleme:**
- Eigenentwicklung von Ansible/Puppet
- Keine State-Verwaltung
- Kein Drift Detection
- Keine Idempotenz-Garantie
- Wartungshölle bei OS-Updates

### ✅ IaC-First (VERWENDEN)

```
User → Unifier → OpenTofu HCL generiert
                    ↓
         Agent führt aus:
         • tofu init
         • tofu plan
         • tofu apply
```

**Vorteile:**
- Terraform Provider Ecosystem (Docker, Proxmox, K8s...)
- Built-in State Management
- Drift Detection via `tofu plan`
- Idempotenz garantiert
- Community-maintained Provider

---

## 📦 StackKit Struktur (IaC-First)

```
stackkits/
├── base/                          # SHARED CORE
│   ├── cue.mod/
│   │   └── module.cue
│   │
│   ├── schema/                    # CUE Schemas (Validation)
│   │   ├── intent.cue             # IntentSpec Schema
│   │   ├── requirements.cue       # RequirementsSpec Schema
│   │   ├── unified.cue            # UnifiedSpec Schema
│   │   └── worker.cue             # WorkerInfo Schema
│   │
│   ├── bootstrap/                 # OS-Preparation Templates
│   │   ├── _bootstrap.tf.tmpl     # Docker, Packages, System
│   │   ├── _docker.tf.tmpl        # Docker Installation
│   │   └── _security.tf.tmpl      # SSH, Firewall, Users
│   │
│   ├── network/                   # Network-Mode Templates
│   │   ├── _local.tf.tmpl         # IP-based, self-signed TLS
│   │   └── _public.tf.tmpl        # Domain-based, ACME TLS
│   │
│   └── lifecycle/                 # Day-2 Operations
│       ├── _drift.terramate.hcl   # Drift Detection Config
│       └── _health.tf.tmpl        # Health Check Resources
│
├── base-homelab/                  # STACKKIT: Base Homelab
│   ├── stackkit.yaml              # Metadata + Requirements
│   ├── stackfile.cue              # CUE Definition (extends base)
│   │
│   ├── services/                  # Service CUE Definitions
│   │   ├── traefik.cue
│   │   ├── dokploy.cue
│   │   ├── monitoring.cue
│   │   └── logging.cue
│   │
│   ├── variants/                  # Pre-configured Sets
│   │   ├── default.cue            # Dokploy + Uptime Kuma
│   │   ├── beszel.cue             # Dokploy + Beszel
│   │   └── minimal.cue            # Dockge + Portainer
│   │
│   └── templates/                 # OpenTofu Templates
│       ├── terramate.tm.hcl       # Terramate Stack Config
│       ├── main.tf                # Main Configuration
│       ├── bootstrap.tf           # OS-Preparation (remote-exec)
│       ├── services.tf            # Docker Resources
│       ├── outputs.tf             # URLs, Credentials
│       └── variables.tf           # Input Variables
│
├── modern-homelab/                # STACKKIT: Modern Homelab
│   └── ...                        # Multi-Node Docker
│
└── ha-homelab/                    # STACKKIT: HA Homelab
    └── ...                        # Kubernetes (k3s)
```

---

## 🔧 Dreistufige Platform-Architektur

### Warum dreistufig?

Docker und Kubernetes sind fundamental verschiedene Paradigmen:

| Aspekt | Docker | Kubernetes |
|--------|--------|------------|
| Deployments | `docker compose up` | `kubectl apply` / Helm |
| Networking | Bridge + Traefik | CNI + Ingress |
| Service Discovery | Container-Names | DNS + Services |
| Storage | Volumes | PV/PVC |

### Layer-Struktur

```
┌─────────────────────────────────────────────────────────┐
│                    LAYER 1: CORE                         │
│  Bootstrap, Security, Users, Network Fundamentals        │
│  (Shared across ALL StackKits)                          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                 LAYER 2: PLATFORM                        │
│  ┌─────────────────┐    ┌─────────────────┐             │
│  │     Docker      │    │   Kubernetes    │             │
│  │  (base/modern)  │    │  (ha-homelab)   │             │
│  └─────────────────┘    └─────────────────┘             │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│               LAYER 3: SERVICES + HEALTH                 │
│  Service Definitions, Health Checks, Outputs             │
│  (Platform-specific implementations)                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Der komplette IaC-First Prozess

### Phase 1-2: Configuration & StackKit Selection

```
1. User wählt im Wizard:
   ├── Ziele (storage, media, dev-environment)
   ├── Netzwerk-Mode (local / public)
   ├── Domain (optional, nur bei public)
   └── Variante (default / beszel / minimal)

2. Unifier analysiert IntentSpec:
   ├── Validiert gegen CUE Schema
   ├── Wählt passendes StackKit
   └── Generiert RequirementsSpec:
       {
         "stackKit": "base-homelab",
         "minWorkers": 1,
         "requirements": {
           "minRAM": 4096,
           "minDisk": 20,
           "ports": [22, 80, 443]
         }
       }

3. UI zeigt User:
   "Dein Homelab braucht: 1 Server mit min. 4GB RAM"
   "Führe diesen One-Liner auf deinem Server aus:"
   curl -fsSL https://get.kombistack.io | TOKEN=abc123 bash
```

### Phase 3-4: Worker Registration & Validation

```
4. User führt One-Liner aus → Agent installiert sich:
   ├── Bootstrap-Script lädt Agent Binary
   ├── Agent startet mit Registration Token
   └── Agent sammelt System-Info

5. Agent → Core (gRPC Register):
   {
     "hostname": "homelab-server",
     "os": "ubuntu-24.04",
     "ram_mb": 8192,
     "docker_installed": false,
     "ssh_accessible": true
   }

6. Core validiert Requirements:
   ├── RAM >= 4GB? ✅
   ├── Ports frei? ✅
   └── OS supported? ✅

7. Bei Erfolg → Rollout freigegeben
```

### Phase 5-6: UnifiedSpec & IaC Generation

```
8. Unifier generiert UnifiedSpec:
   IntentSpec + WorkerInfo + Credentials → UnifiedSpec
   {
     "stackKit": "base-homelab",
     "variant": "default",
     "network": {
       "mode": "local",
       "tls": "self-signed",
       "workerIP": "192.168.1.100"
     }
   }

9. Generator erstellt IaC Files:
   UnifiedSpec → StackKit Templates → Rendered OpenTofu
   ├── terramate.tm.hcl
   ├── bootstrap.tf      (Docker Install via remote-exec)
   ├── services.tf       (Docker Provider Resources)
   └── outputs.tf        (Service URLs)
```

### Phase 7: Execution (Agent führt OpenTofu aus)

```
10. User klickt "Homelab ausrollen"

11. Core sendet Commands an Agent:
    ┌────────────────────────────────────────────┐
    │ 1. TRANSFER_FILES → IaC Files übertragen  │
    │ 2. TOFU_INIT     → tofu init              │
    │ 3. TOFU_PLAN     → tofu plan -out=plan    │
    │ 4. TOFU_APPLY    → tofu apply plan        │
    │ 5. HEALTH_CHECK  → Service-URLs prüfen    │
    └────────────────────────────────────────────┘

12. OpenTofu macht (deklarativ!):
    • null_resource + remote-exec → Docker Installation
    • null_resource + remote-exec → Firewall Setup
    • docker_network → Network erstellen
    • docker_container → Services starten

13. Bei Erfolg:
    ✅ "Dein Homelab ist bereit!"
    Service URLs:
    • Traefik: https://192.168.1.100:8080
    • Dokploy: https://192.168.1.100:3000
```

### Phase 8: Day-2 Operations (Terramate)

```
DRIFT DETECTION (Scheduled):
─────────────────────────────
Core sendet Command an Agent:
→ terramate run --sync-drift-status -- tofu plan -detailed-exitcode

Agent meldet zurück:
├── Exit Code 0: No changes (kein Drift)
├── Exit Code 2: Changes detected (Drift!)
└── Plan-Details für UI

UI zeigt:
⚠️ "Drift detected: Container 'traefik' wurde manuell geändert"
→ Button: "Auto-Remediate" oder "Ignorieren"


UPDATES:
────────
User ändert Config → Neue IaC Files
Core sendet:
→ terramate run --changed -- tofu apply


ROLLBACK:
─────────
Bei Fehler: Core hat vorherigen tfstate
→ tofu apply mit altem State = Rollback
```

---

## 📄 Beispiel: bootstrap.tf (IaC-First)

```hcl
# OS-Preparation via OpenTofu (NICHT via Agent-Shell-Commands!)

variable "worker_ip" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "root"
}

variable "ssh_private_key_path" {
  type = string
}

# =============================================================================
# CONNECTION CONFIGURATION
# =============================================================================

locals {
  ssh_connection = {
    type        = "ssh"
    host        = var.worker_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }
}

# =============================================================================
# DOCKER INSTALLATION
# =============================================================================

resource "null_resource" "install_docker" {
  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -e",
      
      "# Check if Docker is already installed",
      "if command -v docker &> /dev/null; then",
      "  echo 'Docker already installed'",
      "  exit 0",
      "fi",
      
      "# Install Docker",
      "curl -fsSL https://get.docker.com | sh",
      
      "# Enable and start Docker",
      "systemctl enable docker",
      "systemctl start docker",
      
      "echo 'Docker installation complete'"
    ]
  }
}

# =============================================================================
# FIREWALL SETUP
# =============================================================================

resource "null_resource" "setup_firewall" {
  depends_on = [null_resource.install_docker]

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    user        = local.ssh_connection.user
    private_key = local.ssh_connection.private_key
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -e",
      
      "# Install UFW if not present",
      "apt-get update && apt-get install -y ufw",
      
      "# Configure UFW",
      "ufw default deny incoming",
      "ufw default allow outgoing",
      "ufw allow 22/tcp comment 'SSH'",
      "ufw allow 80/tcp comment 'HTTP'",
      "ufw allow 443/tcp comment 'HTTPS'",
      
      "# Enable UFW",
      "echo 'y' | ufw enable",
      
      "echo 'Firewall setup complete'"
    ]
  }
}

# =============================================================================
# MARKER OUTPUT
# =============================================================================

output "bootstrap_complete" {
  value      = true
  depends_on = [null_resource.setup_firewall]
}
```

---

## 📄 Beispiel: services.tf (Docker Provider)

```hcl
# Services via OpenTofu Docker Provider

resource "docker_network" "homelab" {
  name       = "homelab"
  driver     = "bridge"
  depends_on = [null_resource.install_docker]
}

# =============================================================================
# TRAEFIK (Reverse Proxy)
# =============================================================================

resource "docker_image" "traefik" {
  name = "traefik:v3.1"
}

resource "docker_container" "traefik" {
  name  = "traefik"
  image = docker_image.traefik.image_id
  
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.homelab.name
  }

  # Dynamic command based on network mode
  command = var.network_mode == "local" ? [
    "--api.dashboard=true",
    "--api.insecure=true",
    "--providers.docker=true",
    "--entrypoints.web.address=:80",
  ] : [
    "--api.dashboard=true",
    "--providers.docker=true",
    "--certificatesresolvers.letsencrypt.acme.email=${var.acme_email}",
  ]

  labels {
    label = "managed-by"
    value = "kombistack"
  }
}

# =============================================================================
# DOKPLOY (default/beszel variants)
# =============================================================================

resource "docker_container" "dokploy" {
  count = var.variant != "minimal" ? 1 : 0
  
  name  = "dokploy"
  image = "dokploy/dokploy:latest"
  
  restart = "unless-stopped"

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  networks_advanced {
    name = docker_network.homelab.name
  }

  labels {
    label = "managed-by"
    value = "kombistack"
  }
}
```

---

## 🔑 Agent-Rolle in IaC-First

Der Agent ist ein **Thin Layer**, der NUR folgende Aufgaben hat:

### Was der Agent MACHT:

| Task | Beschreibung |
|------|--------------|
| System-Info sammeln | RAM, OS, Ports → gRPC Register |
| Files empfangen | IaC Files von Core entgegennehmen |
| `tofu init` ausführen | OpenTofu initialisieren |
| `tofu plan` ausführen | Plan generieren, an Core melden |
| `tofu apply` ausführen | Plan anwenden |
| `terramate run` ausführen | Orchestration Commands |
| Logs streamen | Execution Logs via gRPC → SSE |
| Health melden | Service-Status an Core |

### Was der Agent NICHT macht:

| Task | Stattdessen |
|------|-------------|
| ❌ `apt install docker` | ✅ OpenTofu `null_resource` + `remote-exec` |
| ❌ `docker run ...` | ✅ OpenTofu `docker_container` Resource |
| ❌ `ufw allow 443` | ✅ OpenTofu `null_resource` + `remote-exec` |
| ❌ Config-Management | ✅ OpenTofu State |
| ❌ Drift Detection Logik | ✅ `tofu plan` Exit Code |

---

## 📊 Feature-Vergleich

| Feature | Agent-First | IaC-First |
|---------|-------------|-----------|
| Docker Install | Agent Shell | OpenTofu remote-exec |
| Container Deploy | Agent Shell | Docker Provider |
| Firewall | Agent Shell | OpenTofu remote-exec |
| State Management | ❌ Selbst bauen | ✅ terraform.tfstate |
| Idempotenz | ❌ Selbst garantieren | ✅ Terraform-Garantie |
| Drift Detection | ❌ Selbst bauen | ✅ tofu plan |
| Rollback | ❌ Selbst bauen | ✅ State-basiert |
| Provider Ecosystem | ❌ Nicht nutzbar | ✅ Docker, Proxmox, K8s... |
| Day-2 Updates | ❌ Kompliziert | ✅ terramate run --changed |

---

## 🚀 Implementation Roadmap

### Sprint 5.2: IaC-First Migration (Neu)

| ID | Task | Effort | Status |
|----|------|--------|--------|
| IAC-1 | bootstrap.tf Template erstellen | 1d | Open |
| IAC-2 | services.tf auf Docker Provider umstellen | 2d | Open |
| IAC-3 | Network-Mode Templates (local/public) | 1d | Open |
| IAC-4 | Agent Commands auf tofu beschränken | 1d | Open |
| IAC-5 | Terramate Integration für Day-2 | 2d | Open |
| IAC-6 | Tests für IaC-Generation | 1d | Open |

### Deliverables

- ✅ Alle OS-Preparation via OpenTofu remote-exec
- ✅ Alle Services via Docker Provider
- ✅ Agent führt nur tofu/terramate Commands aus
- ✅ Drift Detection via Terramate
- ✅ Tests für generierte IaC Files

---

## 📚 Referenzen

- [OpenTofu Provisioners](https://opentofu.org/docs/language/resources/provisioners/)
- [Terramate Drift Detection](https://terramate.io/docs/cli/orchestration/)
- [Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest)
- [KombiStack Unifier Flow](../../KombiStack/docs/concepts/Unifier-Specification-Flow.md)

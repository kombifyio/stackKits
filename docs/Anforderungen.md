1)
ich ahbe jetzt weiter an den stackKits geplant und dir nochmal die wichtigsten dokumente verlinkt. Ich möchte das wir zunöächst mit 3 Basic stackKits planen und zwar.
Base Homelab (1x lokal), Modern Homelab (1x lokal, 1x cloud), High Availability Homelab (Multi-cloud-Server).

Dazu möchte ich, dass wir zuerst das stackKit für das Base Homelab bauen.

Wir müssen jetzt einmal einen gesamt-Aufbauplan für die stackKits besperchen und du Funktion vom aktuellen Prototyp auf production-ready bauen.

Ich habe dir das Repo stackKits hier als ordner in den workspace hinterlegt, sodass du direkt im finalen repo arbeiten kannst und dort dauber einzelne stackKits bauen oder hinterlegen kannst.

Ich möchte bitte:
eine ausführlcihe Architektur, StackKits-Prozessplanung mit cue, opentofu + terramate aund wie alle Logiken und abhängigkeiten dazwischen funktionieren.

einen plan wie wir ein ausgereiftes "Base Homelab" stackKit bauen. Pahse 1) für Ubuntu, single server. alles andere muss durch das stackKit passieren. Docker ist gesetzt. Phase 2: wir unterstuützen mehrere OS und wir haben unterschiedliche varianten des TechStacks basierend auf der compute-leistung. (auf einem rasoberry PI wird unser Homelab anders ausgerollt als auf einen vollwertigen Server mit 8 CPUs und 16GB Ram zum besipiel.

Dann den vollständigen Aufbau des Base Homelab stackKits im stackKits Repo. 

Umbau der aktuellen Integration in kombiStack direkt zu -> wir gehen auf das Repo und holen uns da ganz aktuell die passende Config des stackKits.

Aufbau von Tests die Realbedingungen entsprechen und Umsetzung von allem.

Mache am Ende nochmal ein Reveiw im Big Picture, ob wir was vergessen haben und update dann nochmal den Plan, den du in docs erstellt. 

Dann baue den Plan in die aktuelle roadmap ein und mache ein Update von Sprint 5. Zunächst nur Sprint 5 mit Base Homelab. Für weitere stackKits machen wir dann einen weiteren Sprint.

Evaluiere bitte auch das Konzepot und vorgehen, nutze subagents und tools zur recherche und zur Planungsunterstützung.

ich freue mich sehr auf deinen plan


2)
Ganz wichtig: unser Tool soll dem user eine robuste, seamless experience bieten wo alles nach dem rollout sauber funktioniert ohne weitere manuell schritte. Das hat oberste Priorität.

Bitte challenge die aktuellen stackKits da ganz ehrlich und gib mir eine review-Analyse und issues die du finden kannst.

gib mir bitte auch eine genau auflistung wie die Logiken aktuell funktionieren und an welchen Stellen stackKits aktuell Variabilität eingebaut haben, in Form von 1) unterscheidelcihe OS suppoerted, 2) unterscheidliche Monitoering-Tools suppoerted, 3) basic openTofu-only vs. advanced Terramate+OpenTofu mode suppoerted, 4)Orchestration after rollout supported with changes and without changes  5)different levels of drift detection supported, 6) unterscheidlcihe Netzwerkonzepte oder Netzwerkmodi supported... und alles weitere. bitte gib mir hier die aktuelle Liste die mir einen genauen überblick gibt was geht.

Dann erstelle bitte eine SOLL-Liste mit allen Punkten die wir variabel oder konfigurierbar in den stackKits anbieten können / sollten. wichtig: die stackKits dürfen keine Prämissen zu vorisntallierten Tools oder configs setzen. das muss von uns koommen.

Dann lass uns die beiden Listen IST und SOLL einmal auswerten ob wir die stackKit Struktur nochmal verbessern müssen. Evaluiere nochmal ob wir hier auch den gesamten Homelab Use Case abbilden. 

Lass uns hier aussschließlich mit dem Base Homelab im Dteail arbeiten und  planen.

Anschließend lass uns aber das Multi-Server-Szenario bei der Architekturplanung mit betrachten and vorbereiten, sodass wir später nicht nochmal alles umbauen müssen. Prüfe dann was genau das Multi-Server SZenario (zz.B: Modern Homelab) von den Base Homelab-StackKit Unterscheiden wird und welchge zusätzlichen oder anderen Stellen dort betrachtet und über cues konfiguriert werden müssen, damit wir ein Gefühl dafür bekommen, was für alle stacKits als gemeinsamer "Core" gilt und was additions für unterschiedlcihe stackKits sein werden. So können wir bei Updates oder Erweiterungen imemr am Core arbeiten und haben keien unterscheidlcihen  Wahrheiten.

Dann betrachte auch bitte noch die Add-On-Funtkionalität, wo bei einen stackKit beispeilsweise auch noch weitere Server nachträglich hinzugefügt werden können oder neue Tools ausgerollt werden können 8neue Tolls sind vielleicht noch nichtmal ein Add-On, aber ein Server wahrscheinlich schon.
Da brauchen wir wahrscheinlich auch ein Konzept, was Ad-Ons zu einem stackKit sind unsd was nicht.
Du hast völlig recht - das muss ich mir genau anschauen. Lass mich zuerst die aktuellen StackKits analysieren: 

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base-homelab/services.cue#1-1), lines 1 to 200

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base-homelab/stackkit.yaml#1-1), lines 1 to 200

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base-homelab/templates/simple/main.tf#1-1), lines 1 to 200

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base-homelab/templates/simple/main.tf#200-200), lines 200 to 400

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base-homelab/stackfile.cue#1-1), lines 1 to 220

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base)

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base/stackkit.cue#1-1), lines 1 to 150

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base/network.cue#1-1), lines 1 to 100

Read [](file:///c%3A/Users/mako1/OneDrive/Dokumente/GitHub/StackKits/base/system.cue#1-1), lines 1 to 100

Ich habe jetzt einen guten Überblick. Lass mich eine detaillierte Analyse erstellen:

---

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
| **Container** | Docker | k3s | k3s HA |
| **Networking** | Bridge | CNI (Cilium) | CNI + MetalLB |
| **Storage** | Local | Longhorn | Ceph/Longhorn |
| **Service Mesh** | None | Optional | Cilium/Linkerd |
| **GitOps** | None | FluxCD | FluxCD |
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

---

## 🎯 Empfohlene nächste Schritte

### Prio 1: Kritische Fixes für Base Homelab

1. **Local Network Mode**
   - IP-basierter Zugriff ohne Domain
   - Self-signed Zertifikate
   - Service URLs = `http://192.168.1.100:8080`

2. **Bootstrap implementieren**
   - SSH-Connection
   - Docker Installation
   - Firewall Setup
   - User Creation

3. **Health Verification**
   - Post-Rollout Checks
   - Service Readiness Probes

### Prio 2: Core-Architektur

1. **Base Package aufteilen** in echte Module
2. **Lifecycle-Framework** implementieren
3. **Network-Modes** implementieren (local/public)

### Prio 3: Multi-Node Vorbereitung

1. **Cluster-Schema** in Core
2. **Node-Join-Logik** abstrahieren
3. **Add-On Framework** implementieren

---

Soll ich einen dieser Bereiche im Detail ausarbeiten und implementieren?

3)
Halte bitte deinen Plan so detailliert und vollständig in einem neuen Dokuments in docs fest.

Dann lass uns nochmal erweitert planen und mache mir anpassungsvorschläge mit den Ergänzungen von meienr Seite:

-Modern Homelab soll bitte auch auf Docker Basis sein. Lass unds ggf. nochmal darüber nachdenken, ob ein veriables core-konzept nicht sinn macht, da sich zwischen docker und kubernetes ja aeigentlich der ganze TechStack und die behaviors komplett ädnern, wenn ich das richtig verstehe. macht es sinn die stacks dann dreistufig aufzuteilen?
Core -> Platform(Docker vs. k8s, apply vs. apply+orchestrate, local vs. public) -> Services + Health
Oder so ähnlich?

Und was ich noch challengen möchte: las suns bitte den bootstrap-prozess nochmal prüfen wann genau das im prozess passiert
1. User konfiguroert im Wizard
2. Unifier prüft uns wählt stackKit
3. User bekommt One-liner für Worker-registry und Requiremeents-Info
4. User registriert worker -> wokrer können uns hier erste Infos über das tatsächlcihe System liefern
4.2 Wir haben hier die Möglichkeit dem User nochmal Infos zu geben oder Add-ons, etc nachzukonfigurieren, wenn der user zum beispiel mehr serevr als gefpordert registriert oder die compute-power nicht für das gefwählte stackKits ausreicht
4.3 User bekommt Feedback falls was nicht passt oder wir das stackKit ändern
4.4 User kann regieren und weitere oder andere Server regsitrieren oder austauschen
4.5 Hmelab-Rollout wird bei erfolgreicher validierung der requirements freigegeben
5. User startet Homelab Rollout per Knopfdruck
6. Worker starten die Queues, etc.

Prüfe nochmal ob wir den Prozess mit unsren Unifier-Logiken, dem Bootstrap, den stackKits und der Orchestration mit Terramate so passend abdecken.

Challenge das bitte, mache mir einen erweiterten Vorschlag oder Änderungsvorschläge und lass uns den neuen Plan in den docs dann updaten
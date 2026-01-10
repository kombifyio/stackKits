# Default Spec Files

Diese Default-Specs sind **fertige Vorlagen** für CLI-Only Nutzung (ohne KombiStack UI). Sie enthalten sinnvolle Standard-Konfigurationen für die drei Homelab-Varianten.

## 📋 Verfügbare Varianten

| StackKit | Beschreibung | Nodes | Container Runtime | Network Mode |
|----------|--------------|-------|-------------------|--------------|
| [base-homelab](../base-homelab/default-spec.yaml) | Einfaches Single-Server Homelab | 1 | Docker | local |
| [ha-homelab](../ha-homelab/default-spec.yaml) | High-Availability mit Swarm | 3 | Docker Swarm | local |
| [modern-homelab](../modern-homelab/default-spec.yaml) | Kubernetes-basiert (K3s) | 3 | Kubernetes | public |

## 🚀 Schnellstart

### 1. Vorlage kopieren

```bash
# Wähle deine Variante
cd /path/to/StackKits
cp base-homelab/default-spec.yaml ~/my-homelab-spec.yaml
```

### 2. Konfiguration anpassen

**Mindestanpassungen (PFLICHT):**

```yaml
# IPs anpassen
nodes:
  - ip: 192.168.1.100        # Deine Server-IP
    ssh:
      host: 192.168.1.100    # Gleiche IP
      user: admin            # Dein SSH-User
      key_path: ~/.ssh/id_ed25519  # Dein SSH-Key

# Secrets generieren
services:
  - name: postgres
    env:
      POSTGRES_PASSWORD: xxx  # openssl rand -hex 32
  - name: dokploy
    env:
      NEXTAUTH_SECRET: yyy    # openssl rand -hex 32
```

**Secrets generieren:**

```bash
# PostgreSQL Passwort
openssl rand -hex 32

# Dokploy NEXTAUTH_SECRET
openssl rand -hex 32

# Grafana Admin Passwort (ha-homelab, modern-homelab)
openssl rand -base64 16
```

### 3. Validieren & Deployen

```bash
# Validieren (prüft CUE-Schema)
stackkit validate ~/my-homelab-spec.yaml

# Preview (zeigt geplante Änderungen)
stackkit plan ~/my-homelab-spec.yaml

# Deployen
stackkit apply ~/my-homelab-spec.yaml
```

## 📖 Detaillierte Anpassungen

### base-homelab (Single Server)

**Hardware-Anforderungen:**
- 1 Server mit 4GB RAM, 2 CPU Cores
- Ubuntu 24.04 LTS (empfohlen)
- SSH-Zugriff

**Anpassungen:**

```yaml
# 1. Server-IP (3 Stellen)
nodes[0].ip: 192.168.1.100
nodes[0].ssh.host: 192.168.1.100
services[1].env.NEXTAUTH_URL: http://192.168.1.100:3000

# 2. SSH-Konfiguration
nodes[0].ssh.user: admin  # Dein SSH-User
nodes[0].ssh.key_path: ~/.ssh/id_ed25519

# 3. Secrets (2 Stellen)
services[1].env.NEXTAUTH_SECRET: <generiert>
services[2].env.POSTGRES_PASSWORD: <generiert>

# 4. Domains (optional, für /etc/hosts)
services[1].labels.traefik.http.routers.dokploy.rule: Host(`dokploy.local`)
services[3].labels.traefik.http.routers.uptime.rule: Host(`uptime.local`)
```

**Enthaltene Services:**
- Traefik (Reverse Proxy)
- Dokploy (App Deployment)
- PostgreSQL (Database)
- Uptime Kuma (Monitoring)

### ha-homelab (3-Node Swarm)

**Hardware-Anforderungen:**
- 1 Main Node: 8GB RAM, 4 CPU Cores
- 2 Worker Nodes: 4GB RAM, 2 CPU Cores (jeweils)
- Ubuntu 24.04 LTS
- Alle Nodes im gleichen Netzwerk

**Anpassungen:**

```yaml
# 1. Server-IPs (9 Stellen)
nodes[0].ip: 192.168.1.100  # Main
nodes[1].ip: 192.168.1.101  # Worker 1
nodes[2].ip: 192.168.1.102  # Worker 2
# + ssh.host für alle 3 Nodes
# + docker.swarm.advertise_addr (Main)
# + services[2].env.NEXTAUTH_URL

# 2. SSH-Konfiguration (3 Stellen)
nodes[0-2].ssh.user: admin  # Gleicher User!
nodes[0-2].ssh.key_path: ~/.ssh/id_ed25519

# 3. Secrets (4 Stellen)
services[1].env.POSTGRES_PASSWORD
services[2].env.DATABASE_URL  # Gleiche Password!
services[2].env.NEXTAUTH_SECRET
services[5].env.GF_SECURITY_ADMIN_PASSWORD

# 4. Domains (4 Stellen)
# Traefik Ingress Rules für Dokploy, Uptime Kuma, Prometheus, Grafana

# 5. HA-Konfiguration (optional)
services[X].deploy.replicas: 2  # Anzahl Replicas
```

**Enthaltene Services:**
- Traefik (Load Balancer)
- PostgreSQL (HA Database)
- Dokploy (Replicated)
- Uptime Kuma
- Prometheus (Monitoring Addon)
- Grafana (Monitoring Addon)

**Swarm-Setup:** Wird automatisch initialisiert:
1. Main Node: `docker swarm init`
2. Worker Nodes: `docker swarm join` (Token vom Manager)

### modern-homelab (Kubernetes)

**Hardware-Anforderungen:**
- 1 Control Plane: 8GB RAM, 4 CPU Cores
- 2 Worker Nodes: 4GB RAM, 2 CPU Cores (jeweils)
- Ubuntu 24.04 LTS
- **Wichtig:** Benötigt **echte Domain** für Let's Encrypt!

**Anpassungen:**

```yaml
# 1. Server-IPs (7 Stellen)
nodes[0-2].ip: 192.168.1.100-102
# + ssh.host für alle 3
# + k3s.options (TLS SAN)
# + ingress-nginx externalIPs
# + network.ingress_ip

# 2. SSH-Konfiguration (3 Stellen)
nodes[0-2].ssh.user: admin
nodes[0-2].ssh.key_path: ~/.ssh/id_ed25519

# 3. Domains (5 Stellen) - MUSS ECHT SEIN!
services[4].env.NEXTAUTH_URL: https://dokploy.yourdomain.com
services[4].k8s.ingress.host: dokploy.yourdomain.com
services[5].k8s.ingress.host: uptime.yourdomain.com
services[6].k8s.values.grafana.ingress.hosts[0]: grafana.yourdomain.com
tls.email: admin@yourdomain.com

# 4. Secrets (4 Stellen)
services[4].env.DATABASE_URL
services[4].env.NEXTAUTH_SECRET
services[6].k8s.values.grafana.adminPassword
network.dns.email

# 5. DNS Provider
network.dns.provider: cloudflare  # oder route53, digitalocean
```

**DNS-Setup (WICHTIG!):**

```bash
# 1. Domain registrieren (z.B. bei Cloudflare)
# 2. A-Records erstellen:
dokploy.yourdomain.com  → Public IP
uptime.yourdomain.com   → Public IP
grafana.yourdomain.com  → Public IP

# 3. API-Token für DNS-01 Challenge erstellen (Cloudflare)
# 4. Token in Kubernetes Secret speichern:
kubectl create secret generic cloudflare-api-token \
  --namespace cert-manager \
  --from-literal=api-token=<your-token>
```

**Enthaltene Services:**
- Ingress-NGINX (Load Balancer)
- Cert-Manager (Let's Encrypt)
- PostgreSQL Operator + Cluster (HA)
- Dokploy (Replicated)
- Uptime Kuma
- Prometheus Stack (Monitoring)
- Loki Stack (Observability)

## 🔍 Validierung

### Schema-Validierung

```bash
# CUE-Schema prüfen
stackkit validate my-spec.yaml

# Detaillierte Fehler
stackkit validate my-spec.yaml --verbose
```

### Häufige Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `invalid IP address` | Falsche IP-Format | Nutze `192.168.x.y` Format |
| `SSH key not found` | Falscher Key-Pfad | Prüfe: `ls ~/.ssh/id_ed25519` |
| `service node not found` | Node-Name falsch | Prüfe `nodes[].name` vs `services[].node` |
| `circular dependency` | Service hängt von sich selbst ab | Prüfe `services[].needs` |

## 🛠️ Troubleshooting

### Debug-Modus

```bash
# Zeige generierte OpenTofu-Files
stackkit plan --debug

# Zeige CUE-Validierung
stackkit validate --show-cue
```

### SSH-Probleme

```bash
# Teste SSH-Verbindung
ssh -i ~/.ssh/id_ed25519 admin@192.168.1.100

# Füge Host zu known_hosts hinzu
ssh-keyscan -H 192.168.1.100 >> ~/.ssh/known_hosts
```

### Docker/K3s-Probleme

```bash
# Prüfe Docker Installation
ssh admin@192.168.1.100 "docker --version"

# Prüfe K3s Status
ssh admin@192.168.1.100 "sudo systemctl status k3s"

# K3s Logs
ssh admin@192.168.1.100 "sudo journalctl -u k3s -f"
```

## 📚 Weitere Ressourcen

- [stack-spec.yaml Reference](../docs/stack-spec-reference.md) - Vollständige Spec-Dokumentation
- [Creating StackKits Guide](../docs/creating-stackkits.md) - Eigene StackKits erstellen
- [CLI Reference](../docs/cli-reference.md) - Alle CLI-Befehle
- [Architecture](../docs/architecture.md) - CUE + OpenTofu + Terramate

## 🤝 Beitragen

Verbesserungsvorschläge für Default-Specs? Erstelle einen Pull Request!

**Richtlinien:**
- Secrets bleiben `changeme_*` (keine echten Secrets!)
- Kommentare mit `⚠️` markieren PFLICHT-Anpassungen
- Hardware-Anforderungen dokumentieren
- Realistische Service-Konfigurationen

# Default Spec Files

These default specs are **ready-to-use templates** for CLI-only usage (without KombiStack UI). They contain sensible default configurations for the three homelab variants.

## 📋 Available Variants

| StackKit | Description | Nodes | Container Runtime | Network Mode |
|----------|-------------|-------|-------------------|--------------|
| [base-homelab](../base-homelab/default-spec.yaml) | Simple single-server homelab | 1 | Docker | local |
| [ha-homelab](../ha-homelab/default-spec.yaml) | High-availability with Swarm | 3 | Docker Swarm | local |
| [modern-homelab](../modern-homelab/default-spec.yaml) | Kubernetes-based (K3s) | 3 | Kubernetes | public |

## 🚀 Quick Start

### 1. Copy Template

```bash
# Choose your variant
cd /path/to/StackKits
cp base-homelab/default-spec.yaml ~/my-homelab-spec.yaml
```

### 2. Customize Configuration

**Minimum Adjustments (REQUIRED):**

```yaml
# Adjust IPs
nodes:
  - ip: 192.168.1.100        # Your server IP
    ssh:
      host: 192.168.1.100    # Same IP
      user: admin            # Your SSH user
      key_path: ~/.ssh/id_ed25519  # Your SSH key

# Generate secrets
services:
  - name: postgres
    env:
      POSTGRES_PASSWORD: xxx  # openssl rand -hex 32
  - name: dokploy
    env:
      NEXTAUTH_SECRET: yyy    # openssl rand -hex 32
```

**Generate Secrets:**

```bash
# PostgreSQL password
openssl rand -hex 32

# Dokploy NEXTAUTH_SECRET
openssl rand -hex 32

# Grafana admin password (ha-homelab, modern-homelab)
openssl rand -base64 16
```

### 3. Validate & Deploy

```bash
# Validate (checks CUE schema)
stackkit validate ~/my-homelab-spec.yaml

# Preview (shows planned changes)
stackkit plan ~/my-homelab-spec.yaml

# Deploy
stackkit apply ~/my-homelab-spec.yaml
```

## 📖 Detailed Customization

### base-homelab (Single Server)

**Hardware Requirements:**
- 1 server with 4GB RAM, 2 CPU cores
- Ubuntu 24.04 LTS (recommended)
- SSH access

**Customizations:**

```yaml
# 1. Server IP (3 locations)
nodes[0].ip: 192.168.1.100
nodes[0].ssh.host: 192.168.1.100
services[1].env.NEXTAUTH_URL: http://192.168.1.100:3000

# 2. SSH configuration
nodes[0].ssh.user: admin  # Your SSH user
nodes[0].ssh.key_path: ~/.ssh/id_ed25519

# 3. Secrets (2 locations)
services[1].env.NEXTAUTH_SECRET: <generated>
services[2].env.POSTGRES_PASSWORD: <generated>

# 4. Domains (optional, for /etc/hosts)
services[1].labels.traefik.http.routers.dokploy.rule: Host(`dokploy.local`)
services[3].labels.traefik.http.routers.uptime.rule: Host(`uptime.local`)
```

**Included Services:**
- Traefik (Reverse Proxy)
- Dokploy (App Deployment)
- PostgreSQL (Database)
- Uptime Kuma (Monitoring)

### ha-homelab (3-Node Swarm)

**Hardware Requirements:**
- 1 Main Node: 8GB RAM, 4 CPU cores
- 2 Worker Nodes: 4GB RAM, 2 CPU cores (each)
- Ubuntu 24.04 LTS
- All nodes in the same network

**Customizations:**

```yaml
# 1. Server IPs (9 locations)
nodes[0].ip: 192.168.1.100  # Main
nodes[1].ip: 192.168.1.101  # Worker 1
nodes[2].ip: 192.168.1.102  # Worker 2
# + ssh.host for all 3 nodes
# + docker.swarm.advertise_addr (Main)
# + services[2].env.NEXTAUTH_URL

# 2. SSH configuration (3 locations)
nodes[0-2].ssh.user: admin  # Same user!
nodes[0-2].ssh.key_path: ~/.ssh/id_ed25519

# 3. Secrets (4 locations)
services[1].env.POSTGRES_PASSWORD
services[2].env.DATABASE_URL  # Same password!
services[2].env.NEXTAUTH_SECRET
services[5].env.GF_SECURITY_ADMIN_PASSWORD

# 4. Domains (4 locations)
# Traefik ingress rules for Dokploy, Uptime Kuma, Prometheus, Grafana

# 5. HA configuration (optional)
services[X].deploy.replicas: 2  # Number of replicas
```

**Included Services:**
- Traefik (Load Balancer)
- PostgreSQL (HA Database)
- Dokploy (Replicated)
- Uptime Kuma
- Prometheus (Monitoring Addon)
- Grafana (Monitoring Addon)

**Swarm Setup:** Automatically initialized:
1. Main Node: `docker swarm init`
2. Worker Nodes: `docker swarm join` (Token from manager)

### modern-homelab (Kubernetes)

**Hardware Requirements:**
- 1 Control Plane: 8GB RAM, 4 CPU cores
- 2 Worker Nodes: 4GB RAM, 2 CPU cores (each)
- Ubuntu 24.04 LTS
- **Important:** Requires a **real domain** for Let's Encrypt!

**Customizations:**

```yaml
# 1. Server IPs (7 locations)
nodes[0-2].ip: 192.168.1.100-102
# + ssh.host for all 3
# + k3s.options (TLS SAN)
# + ingress-nginx externalIPs
# + network.ingress_ip

# 2. SSH configuration (3 locations)
nodes[0-2].ssh.user: admin
nodes[0-2].ssh.key_path: ~/.ssh/id_ed25519

# 3. Domains (5 locations) - MUST BE REAL!
services[4].env.NEXTAUTH_URL: https://dokploy.yourdomain.com
services[4].k8s.ingress.host: dokploy.yourdomain.com
services[5].k8s.ingress.host: uptime.yourdomain.com
services[6].k8s.values.grafana.ingress.hosts[0]: grafana.yourdomain.com
tls.email: admin@yourdomain.com

# 4. Secrets (4 locations)
services[4].env.DATABASE_URL
services[4].env.NEXTAUTH_SECRET
services[6].k8s.values.grafana.adminPassword
network.dns.email

# 5. DNS Provider
network.dns.provider: cloudflare  # or route53, digitalocean
```

**DNS Setup (IMPORTANT!):**

```bash
# 1. Register domain (e.g., at Cloudflare)
# 2. Create A-Records:
dokploy.yourdomain.com  → Public IP
uptime.yourdomain.com   → Public IP
grafana.yourdomain.com  → Public IP

# 3. Create API token for DNS-01 challenge (Cloudflare)
# 4. Store token in Kubernetes secret:
kubectl create secret generic cloudflare-api-token \
  --namespace cert-manager \
  --from-literal=api-token=<your-token>
```

**Included Services:**
- Ingress-NGINX (Load Balancer)
- Cert-Manager (Let's Encrypt)
- PostgreSQL Operator + Cluster (HA)
- Dokploy (Replicated)
- Uptime Kuma
- Prometheus Stack (Monitoring)
- Loki Stack (Observability)

## 🔍 Validation

### Schema Validation

```bash
# Check CUE schema
stackkit validate my-spec.yaml

# Detailed errors
stackkit validate my-spec.yaml --verbose
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `invalid IP address` | Wrong IP format | Use `192.168.x.y` format |
| `SSH key not found` | Wrong key path | Check: `ls ~/.ssh/id_ed25519` |
| `service node not found` | Wrong node name | Check `nodes[].name` vs `services[].node` |
| `circular dependency` | Service depends on itself | Check `services[].needs` |

## 🛠️ Troubleshooting

### Debug Mode

```bash
# Show generated OpenTofu files
stackkit plan --debug

# Show CUE validation
stackkit validate --show-cue
```

### SSH Issues

```bash
# Test SSH connection
ssh -i ~/.ssh/id_ed25519 admin@192.168.1.100

# Add host to known_hosts
ssh-keyscan -H 192.168.1.100 >> ~/.ssh/known_hosts
```

### Docker/K3s Issues

```bash
# Check Docker installation
ssh admin@192.168.1.100 "docker --version"

# Check K3s status
ssh admin@192.168.1.100 "sudo systemctl status k3s"

# K3s logs
ssh admin@192.168.1.100 "sudo journalctl -u k3s -f"
```

## 📚 Additional Resources

- [stack-spec.yaml Reference](stack-spec-reference.md) - Complete spec documentation
- [Creating StackKits Guide](creating-stackkits.md) - Create your own StackKits
- [CLI Reference](CLI.md) - All CLI commands
- [Architecture](ARCHITECTURE.md) - CUE + OpenTofu + Terramate

## 🤝 Contributing

Have improvement suggestions for default specs? Create a pull request!

**Guidelines:**
- Secrets remain `changeme_*` (no real secrets!)
- Mark REQUIRED adjustments with `⚠️` comments
- Document hardware requirements
- Use realistic service configurations

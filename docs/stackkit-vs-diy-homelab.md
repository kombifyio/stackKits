# StackKit vs. DIY Homelab: What You Actually Get

**One command on a naked Ubuntu server. That's it.**

`stackkit apply` takes a fresh Ubuntu 24.04 installation and turns it into a fully configured, production-grade homelab — with reverse proxy, automatic HTTPS, a PaaS dashboard, monitoring, log viewer, identity management, and hardened security. No manual SSH sessions. No weekend-long setup marathons. No YouTube tutorial rabbit holes.

This document compares what a StackKit delivers out of the box versus what you'd have to build, configure, and maintain yourself.

---

## The 30-Second Version

| | **With StackKit** | **Without (DIY)** |
|---|---|---|
| **Time to running homelab** | ~15 minutes | 2–5 days (if you know what you're doing) |
| **Services configured** | 8–12 pre-integrated services | Whatever you manage to install |
| **HTTPS certificates** | Automatic (Let's Encrypt) | Manual cert setup per service |
| **Reverse proxy** | Pre-configured Traefik with routing | Install, configure, debug Nginx/Traefik yourself |
| **App deployment** | Git-push deploys via PaaS dashboard | `docker run` and hope for the best |
| **Monitoring** | Built-in uptime monitoring | Nothing until you set it up |
| **Security hardening** | 15+ security controls applied | Whatever you remember to do |
| **Reproducibility** | Identical every time, any server | "It worked on my machine" |
| **Updates** | `stackkit apply` — re-deploy from scratch | SSH in, `apt upgrade`, pray |
| **Documentation** | Self-documenting (CUE schemas) | Your notes in a Google Doc somewhere |

---

## What Lands on Your Server

When you run `stackkit apply` on a fresh Ubuntu 24.04 box (minimum 2 cores, 4 GB RAM, 50 GB disk), you get this — fully wired, health-checked, and production-ready:

### Platform Layer (Infrastructure)

| Service | What It Does | DIY Equivalent |
|---------|-------------|----------------|
| **Traefik v3** | Reverse proxy with automatic HTTPS, Let's Encrypt certificates, dashboard | Install Nginx/Caddy, write configs per service, manage certs manually, debug routing |
| **Dokploy** | PaaS dashboard — deploy apps from Git with one click, manage domains, view builds | No equivalent unless you install Coolify/Dokploy yourself and wire it to Traefik |
| **Docker Compose** | Container orchestration with health checks, restart policies, resource limits | Install Docker, write compose files, figure out networking, hope containers restart |

### Identity & Access (Zero-Trust Ready)

| Service | What It Does | DIY Equivalent |
|---------|-------------|----------------|
| **LLDAP** | Lightweight LDAP directory — central user/group management | No central identity. Every service has separate logins |
| **Step-CA** | Private Certificate Authority — internal mTLS, auto-issued certs | No internal TLS. Services talk in plaintext on your LAN |
| **TinyAuth** | Forward-auth proxy — protect any service with SSO login and passkeys | Basic auth in Nginx, or nothing at all |
| **PocketID** | Full OIDC provider — SSO across all services with one login | Set up Authelia/Authentik yourself (complex, 2+ hours minimum) |

### Monitoring & Observability

| Service | What It Does | DIY Equivalent |
|---------|-------------|----------------|
| **Uptime Kuma** | Uptime monitoring with status pages, alerts via email/Slack/Discord/ntfy | No monitoring. You find out services are down when you try to use them |
| **Dozzle** | Real-time Docker log viewer — see all container logs in one browser tab | `docker logs -f container_name` in SSH, one container at a time |
| **Beszel** *(optional)* | Lightweight server metrics — CPU, RAM, disk, network history | Install Netdata or Glances manually |
| **Whoami** | Network diagnostic endpoint — verify routing, headers, TLS | `curl localhost` and hope you can interpret the output |

### Security Hardening (Applied Automatically)

This is the part most DIY setups skip entirely. StackKit applies **all of these by default**:

| Security Control | What StackKit Does | What DIY Usually Looks Like |
|---|---|---|
| **Firewall** | UFW configured, only ports 80/443 exposed, Docker rules locked down | UFW maybe, Docker bypasses it, all ports open |
| **Docker socket protection** | Tecnativa socket proxy — containers can't exec into each other | Raw Docker socket mounted everywhere |
| **Container isolation** | `no-new-privileges`, `icc:false`, read-only root filesystem where possible | Default Docker settings (everything allowed) |
| **Network segmentation** | Separate frontend/backend Docker networks, internal-only services hidden | One flat `bridge` network, everything can talk to everything |
| **SSH hardening** | Key-only auth, Fail2ban for brute-force protection | Password auth still enabled, no brute-force protection |
| **Security headers** | HSTS, X-Frame-Options, CSP, Referrer-Policy via Traefik middleware | Missing entirely or manually added per service |
| **Auto-updates** | `unattended-upgrades` for OS security patches | `apt upgrade` whenever you remember |
| **Secrets management** | SOPS + age encrypted secrets in Git | Passwords in `.env` files, committed to Git in plaintext |
| **Intrusion detection** | CrowdSec + Traefik bouncer (community threat intelligence) | Nothing. You find out about attacks from your ISP |
| **DNS filtering** | AdGuard Home + recursive resolver | Pi-hole if you're lucky, ISP DNS if you're not |
| **Health checks** | Every service has HTTP/TCP health checks with auto-restart | No health checks. Dead containers stay dead |
| **Resource limits** | Memory and CPU limits per container prevent runaway processes | No limits. One container can OOM the entire server |
| **Restart policies** | `unless-stopped` on all services — survives reboots | Some containers restart, some don't, you can't remember which |

---

## The Deployment Experience

### With StackKit

```bash
# 1. Install stackkit CLI
curl -fsSL https://get.stackkits.dev | sh

# 2. Create your stack spec
stackkit init base-kit

# 3. Edit your config (domain, email, SSH key)
vim stack-spec.yaml

# 4. Deploy everything
stackkit apply

# Done. All services running. Open https://dokploy.yourdomain.com
```

**Total time:** ~15 minutes (including DNS setup)

### Without StackKit (DIY)

```bash
# 1. Secure the server
ssh root@server
apt update && apt upgrade -y
adduser deploy
usermod -aG sudo deploy
# ... configure SSH keys, disable password auth, set up UFW ...

# 2. Install Docker
curl -fsSL https://get.docker.com | sh
# ... configure Docker daemon, set up networks ...

# 3. Install Traefik
# ... write traefik.yml, dynamic config, create Docker network,
#     set up Let's Encrypt ACME, debug certificate errors ...

# 4. Install each service one by one
# ... write docker-compose.yml for each, configure Traefik labels,
#     set up volumes, figure out environment variables, debug
#     networking issues between containers ...

# 5. Set up monitoring
# ... if you get to it ...

# 6. Security hardening
# ... probably skip this, you're exhausted ...
```

**Total time:** 2–5 days (weekends, realistically)

---

## What You Don't Have to Think About

StackKit handles decisions that take hours to research and minutes to get wrong:

| Decision | StackKit's Answer | Time Saved |
|----------|-------------------|------------|
| Which reverse proxy? | Traefik v3 (auto-discovery, native Docker) | 2–4 hours of comparison + setup |
| How to get HTTPS? | Let's Encrypt via ACME, auto-renewal | 1–2 hours of cert debugging |
| Which PaaS? | Dokploy (no domain) or Coolify (with domain) — context-aware | 3–5 hours of evaluation |
| How to do SSO? | TinyAuth (simple) or PocketID (full OIDC) | 4–8 hours minimum |
| Container networking? | Pre-configured bridge networks with isolation | 2–3 hours of Docker network debugging |
| Log management? | Dozzle — zero config, just works | 1–2 hours |
| How to monitor? | Uptime Kuma with alerts | 1–2 hours |
| Server security? | 15+ controls, all applied automatically | 1–2 days of research and setup |
| How to update? | `stackkit apply` — immutable, from scratch | Ongoing anxiety |

**Estimated total time saved: 20–40 hours** on initial setup alone.

---

## Reproducibility: The Hidden Killer Feature

The biggest advantage isn't what StackKit installs — it's that it installs it **identically, every time, on any server**.

| Scenario | With StackKit | DIY |
|----------|--------------|-----|
| Server dies | `stackkit apply` on a new box. Done. | Rebuild from memory. What was that Traefik config? |
| Want a staging environment | `stackkit apply` on a second box. Identical. | Manually replicate. Forget half the settings. |
| Friend wants the same setup | Hand them your `stack-spec.yaml` | "Let me write you a 47-page guide" |
| Upgrade to new Ubuntu LTS | `stackkit apply` on fresh install | In-place upgrade. Cross fingers. Roll back. |
| Audit what's running | `cue eval ./base-kit/` — schema is the truth | `docker ps` and hope the compose files are in sync |

---

## Available StackKit Tiers

| | Base Kit | Modern Homelab | High Availability Kit |
|---|---|---|---|
| **Status** | **Available now** | Planned | Planned |
| **Nodes** | 1 server | 2+ (local + cloud) | 3+ (cluster) |
| **Best for** | Personal server, dev box | Hybrid home/cloud | Production, uptime SLAs |
| **Highlights** | Everything above | + VPN overlay, split DNS, multi-node | + Docker Swarm, auto-failover, Patroni DB HA |

Start with the **Base Kit**. It covers 90% of homelab use cases. Scale up when you need to.

---

## FAQ

**Q: Do I lose control over my server?**
No. StackKit generates standard Docker Compose and OpenTofu files. You can inspect everything, eject at any time, or just use the generated configs as a starting point.

**Q: Can I add my own services?**
Yes. Dokploy gives you a PaaS dashboard to deploy anything from Git. Services you add get automatic Traefik routing and HTTPS.

**Q: What if I don't have a domain?**
StackKit works with local `.local` domains via mDNS. You can also use a domain later — just update your `stack-spec.yaml` and re-apply.

**Q: What Ubuntu versions are supported?**
Ubuntu 24.04 LTS. Debian 12 also works. Other distros are planned.

**Q: Is this just another Ansible playbook?**
No. StackKit definitions are written in CUE — a typed configuration language with built-in validation. Your config is validated *before* it touches the server. Ansible playbooks can silently misconfigure; CUE schemas can't.

**Q: What happens when a service updates?**
Update the version in your CUE definition, run `stackkit apply`. The entire stack is redeployed cleanly. No drift, no leftover state.

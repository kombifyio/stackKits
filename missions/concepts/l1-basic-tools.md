# Layer 1: Basic Tools & OS Hardening

**Scope:** Foundation-level setup guide for a secure, maintainable single-server Ubuntu homelab with local-only access.

---

## Target Audience

| Persona | Description | Primary Interface |
|---------|-------------|-------------------|
| **A (Non-Techie)** | Uses Web-UIs for One-Click Deployment and Monitoring | Browser |
| **B (Techie)** | Uses SSH & Terminal for Troubleshooting and Deep-Dives | Terminal |

---

## Prerequisites

- Fresh Ubuntu Server Installation (LTS recommended)
- SSH access as a user with sudo rights
- Server located in local home network

---

## Phase 1: System-Level (OS Hardening & Basic Tools)

These steps are executed once via SSH on the server. They lay the foundation for security and provide tools for experts.

### 1.1 System Update

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Security Configuration (Firewall & SSH)

| Tool | Purpose | Command / Configuration |
|------|---------|------------------------|
| **UFW** | Enable firewall (allow only SSH) | `sudo ufw allow OpenSSH`<br>`sudo ufw enable`<br>`sudo ufw status verbose` |
| **SSH** | Disable root login & require key-auth only | Edit: `sudo nano /etc/ssh/sshd_config`<br>Set: `PermitRootLogin no`<br>Set: `PasswordAuthentication no`<br>Restart: `sudo systemctl restart ssh` |

> **Note:** These settings align with the [base/security.cue](../../base/security.cue) schema defaults for SSH hardening.

### 1.3 Modern Terminal Tools

We replace outdated standard tools with modern, colorful alternatives.

| Tool | Replaces | Installation | Invocation |
|------|----------|--------------|------------|
| `bat` | `cat` | `sudo apt install -y bat`<br>(Note: often called via `batcat`) | `batcat /var/log/syslog` |
| `eza` | `ls` | `sudo apt install -y eza` | `eza -lah` |
| `btop` | `htop` | `sudo apt install -y btop` | `btop` |
| `htop` | `top` | `sudo apt install -y htop` | `htop` |
| `fd` | `find` | `sudo apt install -y fd-find` | `fdfind <pattern>` |
| `ripgrep` | `grep` | `sudo apt install -y ripgrep` | `rg <pattern>` |
| `micro` | `nano` | `sudo apt install -y micro` | `micro <file>` |

### 1.4 Quick Install Script

```bash
#!/bin/bash
# Layer 1 Basic Tools Installation

# Update system
sudo apt update && sudo apt upgrade -y

# Install modern CLI tools
sudo apt install -y bat eza btop htop fd-find ripgrep micro

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw --force enable

# Harden SSH (backup first)
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "Layer 1 setup complete!"
```

---

## Phase 2: Identity Foundation (Passkey Setup)

After basic OS hardening, set up identity components for Zero-Trust:

### 2.1 pocketid (Local Passkey Provider)

```bash
# Deploy via Docker (see Layer 2)
docker run -d \
  --name pocketid \
  --restart unless-stopped \
  -p 8080:8080 \
  -v pocketid_data:/data \
  ghcr.io/pocket-id/pocket-id:latest
```

### 2.2 lldap (Directory Service)

```bash
# Deploy via Docker (see Layer 2)
docker run -d \
  --name lldap \
  --restart unless-stopped \
  -p 3890:3890 \
  -p 17170:17170 \
  -v lldap_data:/data \
  -e LLDAP_JWT_SECRET=$(openssl rand -base64 32) \
  -e LLDAP_LDAP_USER_PASS=changeme \
  lldap/lldap:stable
```

> **Note:** See [Layer 1 Identity](../layer-1-foundation/base/IDENTITY.md) for full identity architecture.

---

## Phase 3: Certificate Infrastructure (step-ca)

For mTLS and workload identity:

### 3.1 step-ca (PKI)

```bash
# Initialize step-ca
docker run -d \
  --name step-ca \
  --restart unless-stopped \
  -p 9000:9000 \
  -v step_ca_data:/home/step \
  smallstep/step-ca:latest
```

> **Note:** See [base/security.cue](../../base/security.cue) for PKI schema definitions.

---

## Integration Points

| Layer | Component | Documentation |
|-------|-----------|---------------|
| Layer 1 | Identity Architecture | [IDENTITY.md](../layer-1-foundation/base/IDENTITY.md) |
| Layer 2 | Docker Hardening | [HARDENING.md](../layer-2-platform/docker/HARDENING.md) |
| Layer 3 | StackKit Profiles | [IDENTITY-PROFILES.md](../layer-3-stackkits/IDENTITY-PROFILES.md) |
| Schema | Security CUE | [base/security.cue](../../base/security.cue) |

---

## Next Steps

1. **Layer 2:** Install Docker and apply [hardening configuration](../layer-2-platform/docker/HARDENING.md)
2. **Layer 3:** Deploy a StackKit (start with `base-homelab`)
3. **Identity:** Configure passkeys and RBAC via lldap
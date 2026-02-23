# Ubuntu VM-Service (Docker Desktop)

This directory provides a VM-like Ubuntu service (SSH + Docker Engine) for local StackKits testing.

## Requirements

- Docker Desktop running
- A local SSH public key (recommended: `~/.ssh/id_ed25519.pub`)

## Start

1. Create `authorized_keys` next to this file:

```powershell
Copy-Item "$env:USERPROFILE\.ssh\id_ed25519.pub" ".\authorized_keys"
```

2. Start the VM service:

```powershell
docker compose up -d --build
```

## Connect

```powershell
ssh -p 2222 root@localhost
```

## Docker API for StackKits

Use this to target the VM-service Docker Engine from OpenTofu and the `stackkit status` command:

```powershell
$env:DOCKER_HOST = "tcp://localhost:2375"
```

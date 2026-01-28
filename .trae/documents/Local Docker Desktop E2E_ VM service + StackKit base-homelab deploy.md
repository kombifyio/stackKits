## What I found (current repo state)
- This workspace contains **StackKits** (the `stackkit` Go CLI + StackKits like `base-homelab`). It does **not** include the **KombiStack/kombifyStack** repository or its Docker Compose startup files, so I can’t start “kombifyStack” from within this repo as-is.
- A “prep-tool” already exists here: `stackkit prepare` (alias `stackkit prep`) supports **remote host preparation over SSH** and can install **Docker + OpenTofu** on Ubuntu/Debian.
- `base-homelab` templates currently point the Docker provider at `unix:///var/run/docker.sock`, which means deployments target the Docker Engine where `tofu` runs.

## Key gap vs your request
To “apply the base-homelab StackKit to a VM-service (Ubuntu) started via Docker Compose”, we need a local **Ubuntu “VM-like” service** that:
- exposes **SSH** (for `stackkit prepare --host ...`), and
- runs a **Docker Engine** whose API is reachable from the host (so `tofu` can deploy to it), and
- exposes the service ports from inside that “VM” back to your host for verification.

## Plan (after you confirm)
### 1) Locate and start kombifyStack (if present locally)
- Search the parent workspace for a `kombifyStack`/`KombiStack` directory.
- If found, start it using its documented compose/script entrypoint.
- If not found, proceed with StackKits-only and document exactly what path/name is expected so we can wire it in cleanly.

### 2) Add a Docker-Compose “Ubuntu VM” dev service
- Create `dev/vm/` with:
  - a Dockerfile building an Ubuntu image with `openssh-server`, `sudo`, `curl`, and a Docker Engine (dockerd)
  - an entrypoint that starts `dockerd` + `sshd`
  - a `docker-compose.yml` that runs the container **privileged**, exposes:
    - SSH (host `2222` → container `22`)
    - Docker API (host `2375` → container `2375`, dev-only)
    - base-homelab ports (80, 443, 3000, 3001, 8080, 8888, 9080, 5001, 9000, 19999, 8090)
- Ensure the VM service accepts an SSH public key via a bind-mounted `authorized_keys` file (no secrets committed).

### 3) Make StackKits deploy target selectable (local vs VM)
- Adjust `base-homelab` OpenTofu templates so the Docker provider does **not hardcode** the unix socket.
  - Preferred: rely on `DOCKER_HOST` (and optional `DOCKER_TLS_VERIFY`) so StackKits can target either local Docker Desktop or the VM-service Docker API without template changes per environment.
- Keep default behavior unchanged: if `DOCKER_HOST` is not set, it still targets local Docker Desktop.

### 4) Local “startup check” for everything
- Start Docker Compose services (kombifyStack if available + VM-service).
- Verify:
  - VM-service is reachable on SSH
  - Docker API is reachable (from host)
  - `stackkit` dev build runs (`stackkit version`, `stackkit validate`)

### 5) End-to-end CLI run against the VM-service (Ubuntu)
- Create a fresh test workspace folder.
- Run the full CLI flow:
  - `stackkit init base-homelab`
  - `stackkit prepare --host localhost --user root --key <dev-key> --dry-run` (then real run)
  - Set `DOCKER_HOST=tcp://localhost:2375` for the session
  - `stackkit generate`
  - `stackkit plan`
  - `stackkit apply --auto-approve`
- Validate the deployment by:
  - `stackkit status` (with `DOCKER_HOST=tcp://localhost:2375`)
  - HTTP checks against exposed ports (e.g., `http://localhost:3000`, `http://localhost:3001`, etc.)

### 6) If prep is missing/insufficient, harden it for this dev VM
- If SSH host-key strict checking blocks local dev, add a `stackkit prepare` flag (e.g., `--insecure-hostkey` or `--auto-add-hostkey`) so the compose VM can be used without manual known_hosts editing.
- If OpenTofu install detection/install fails inside the VM, adjust the remote install routine to be more robust for Ubuntu container environments.

### 7) (Optional but recommended) Add a repeatable “one command” dev runner
- Add a small `dev/` script that:
  - ensures a dev SSH key exists (generated locally, not committed)
  - writes `authorized_keys`
  - starts compose
  - runs the StackKit CLI flow with the right environment variables

## Outputs you’ll get
- A working Docker Desktop local environment that starts an Ubuntu VM-like service.
- A verified end-to-end run of `stackkit prepare + generate + plan + apply` deploying `base-homelab` into that VM-service.
- If kombifyStack exists locally, it gets started and verified in the same startup check; otherwise I’ll document what’s missing and how to add it cleanly.

# Docker Swarm Ecosystem -- Full Alignment Research

Research document for kombify StackKits ha-kit. Covers every built-in Docker Swarm capability and complementary tools to maximize alignment with Docker-native standards.

---

## 1. Core Swarm Architecture

### 1.1 Cluster Management (Built-in)

Docker Swarm mode is built directly into Docker Engine -- no additional software required. A swarm consists of **manager nodes** (control plane) and **worker nodes** (data plane).

| Component | Description |
|-----------|-------------|
| **SwarmKit** | The orchestration library embedded in Docker Engine (github.com/docker/swarmkit) |
| **Raft Consensus** | Managers use Raft for leader election and state replication |
| **Declarative Model** | Define desired state; Swarm reconciles actual state continuously |
| **Single Disk Image** | Both manager and worker roles from the same Docker Engine binary |

**Key Raft properties:**
- Requires a **majority (quorum)** of managers to agree on updates
- Odd number of managers recommended (3, 5, 7)
- Fault tolerance: 3 managers tolerate 1 failure, 5 tolerate 2, 7 tolerate 3

| Swarm Size | Majority | Fault Tolerance |
|------------|----------|-----------------|
| 3 | 2 | 1 |
| 5 | 3 | 2 |
| 7 | 4 | 3 |
| 9 | 5 | 4 |

**Manager distribution for fault tolerance:**

| Managers | Repartition (3 availability zones) |
|----------|-----------------------------------|
| 3 | 1-1-1 |
| 5 | 2-2-1 |
| 7 | 3-2-2 |

### 1.2 Node Types and Roles

| Role | Capabilities |
|------|-------------|
| **Manager** | Raft consensus, scheduling, API endpoints, cluster state, can also run workloads |
| **Worker** | Executes tasks assigned by managers, reports status back |
| **Manager-only** | Manager with `--availability drain` -- no workloads, purely control plane |

Manager nodes can be drained to prevent workload scheduling, isolating the control plane from resource starvation.

```bash
docker node update --availability drain <NODE>
```

### 1.3 Services and Tasks

| Concept | Description |
|---------|-------------|
| **Service** | The desired state definition (image, replicas, networks, ports, resources) |
| **Task** | Atomic scheduling unit -- one container running as part of a service |
| **Replicated mode** | Run N replicas distributed across nodes |
| **Global mode** | Run exactly one task per node (like a DaemonSet) |
| **Replicated-job** | Run N tasks to completion (exit code 0) |
| **Global-job** | Run one task per node to completion |

Services are the central abstraction. You never manage individual containers -- you declare desired state and Swarm handles placement, scheduling, and reconciliation.

---

## 2. Networking (Built-in)

### 2.1 Overlay Networks

Docker Swarm creates two automatic networks on initialization:

| Network | Type | Purpose |
|---------|------|---------|
| **ingress** | Overlay | Routing mesh for published ports + internal load balancing (IPVS) |
| **docker_gwbridge** | Bridge | Connects overlay networks to each daemon's physical network |

User-defined overlay networks provide service-to-service communication across nodes:

```bash
docker network create --driver overlay --opt encrypted my-app-network
```

**Critical properties:**
- Overlay networks use **VXLAN** encapsulation (port 4789 UDP)
- **Control plane traffic is always encrypted** (mTLS between managers)
- **Application data plane can be encrypted** with `--opt encrypted` (IPSec ESP)
- Recommended subnet size: /24 (256 addresses per overlay)
- Custom default address pools configurable at `swarm init`

### 2.2 Ingress Routing Mesh

Every node in the swarm participates in the routing mesh. When any node receives a request on a published port, it routes to an active container -- even if no task runs on that node.

**How it works:**
1. Each node runs an IPVS load balancer
2. IPVS tracks all IPs participating in the service
3. Incoming request on any node gets routed to an active container
4. Round-robin load balancing by default

**Publishing modes:**

| Mode | Flag | Behavior |
|------|------|----------|
| **Ingress** (default) | `--publish mode=ingress` | All nodes listen on port, IPVS routes to tasks |
| **Host** | `--publish mode=host` | Only the node running the task binds the port |

Host mode bypasses the routing mesh -- useful for external load balancers (HAProxy, Traefik) that need direct access.

### 2.3 Service Discovery (Built-in DNS)

Swarm has an **embedded DNS server** that assigns each service a unique DNS name:

| Discovery Method | Flag | Behavior |
|-----------------|------|----------|
| **VIP** (default) | `--endpoint-mode vip` | Single virtual IP per service; internal L3/L4 load balancing |
| **DNSRR** | `--endpoint-mode dnsrr` | DNS returns list of task IPs; client picks one |

**VIP mode**: Docker assigns a virtual IP that is the front-end for the service. Internal IPVS handles load distribution. Best for most use cases.

**DNSRR mode**: Each DNS query returns all task IPs. Best when using an external load balancer (HAProxy) that manages its own health checks and balancing algorithms.

### 2.4 Firewall Ports Required

| Port | Protocol | Purpose |
|------|----------|---------|
| 2377 | TCP | Cluster management (manager-to-manager communication) |
| 7946 | TCP/UDP | Container network discovery |
| 4789 | UDP | Overlay network traffic (VXLAN, configurable) |
| ESP (IP 50) | - | Required if overlay encryption enabled |

---

## 3. Security (Built-in)

### 3.1 Mutual TLS (Automatic)

Swarm enforces mTLS between all nodes by default:
- Each node gets a TLS certificate with a cryptographic identity
- Certificates auto-rotate (default: 90 days, configurable)
- Self-signed root CA or custom external CA
- All manager-to-manager and manager-to-worker communication encrypted

```bash
# Set custom certificate rotation period
docker swarm update --cert-expiry 48h
```

### 3.2 Secrets Management

Docker Secrets is a first-class Swarm primitive for sensitive data:

| Property | Detail |
|----------|--------|
| **Encrypted in transit** | Over mTLS connections |
| **Encrypted at rest** | Stored in encrypted Raft log on managers |
| **In-memory only** | Mounted to containers via tmpfs at `/run/secrets/<name>` |
| **Scoped access** | Only services explicitly granted access can read secrets |
| **Auto-cleanup** | Secrets unmounted and flushed from memory when task stops |
| **Max size** | 500 KB per secret |
| **Rotation** | Version secrets by appending dates/versions to names |

```yaml
# In docker-compose.yml for stack deploy
secrets:
  db_password:
    external: true

services:
  db:
    image: postgres:16
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

**Secret lifecycle:**
1. `docker secret create` -- stored in Raft log
2. Service granted access -- decrypted and mounted to task containers
3. Task stops -- secret unmounted, flushed from node memory
4. Node loses connectivity -- keeps existing secrets but cannot receive updates

### 3.3 Configs (Non-Sensitive Data)

Docker Configs work like secrets but for non-sensitive configuration:

| Property | Detail |
|----------|--------|
| **Not encrypted at rest** | Stored in Raft log (which is encrypted) but mounted in clear |
| **Mounted to filesystem** | Directly into container filesystem (no tmpfs) |
| **Default location** | `/<config-name>` in Linux containers |
| **Max size** | 500 KB per config |
| **Immutable** | Cannot modify; create new config and update service |

### 3.4 Autolock (Encryption Key Protection)

Swarm autolock protects the TLS key and Raft log encryption key:

```bash
# Initialize with autolock
docker swarm init --autolock

# Enable on existing swarm
docker swarm update --autolock=true

# Unlock after Docker restart
docker swarm unlock
```

When enabled, managers require manual unlock after Docker restart. The unlock key must be stored securely offline.

### 3.5 Node Identity

- Each node has a unique cryptographic identity (node ID)
- Node IDs are globally unique and non-reusable
- Never copy `/var/lib/docker/swarm/` between nodes
- To re-join: demote, remove, re-join with fresh state

---

## 4. Deployment and Updates (Built-in)

### 4.1 Docker Stack Deploy

`docker stack deploy` deploys multi-service applications from Compose files:

```bash
docker stack deploy -c docker-compose.yml mystack
```

Uses the `deploy` section of Compose files (the Compose Deploy Specification):

```yaml
services:
  web:
    image: nginx:latest
    deploy:
      mode: replicated
      replicas: 3
      placement:
        constraints:
          - node.role == worker
          - node.labels.zone == us-east
        preferences:
          - spread: node.labels.datacenter
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        monitor: 30s
        max_failure_ratio: 0.1
        order: stop-first
      rollback_config:
        parallelism: 1
        delay: 5s
        failure_action: pause
        order: stop-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      labels:
        com.example.tier: frontend
      endpoint_mode: vip
    secrets:
      - db_password
    configs:
      - source: nginx_config
        target: /etc/nginx/nginx.conf
```

### 4.2 Rolling Updates

Swarm supports zero-downtime rolling updates natively:

| Parameter | Description |
|-----------|-------------|
| `parallelism` | Number of tasks to update simultaneously (0 = all at once) |
| `delay` | Wait time between updating task groups |
| `failure_action` | `continue`, `rollback`, or `pause` on failure |
| `monitor` | Time to watch each updated task for failure |
| `max_failure_ratio` | Acceptable failure rate during update |
| `order` | `stop-first` (default) or `start-first` (briefly overlapping) |

```bash
# Update service image with rolling update
docker service update --image nginx:1.26 --update-parallelism 2 --update-delay 10s my-web
```

### 4.3 Automatic Rollback

If an update fails, Swarm can automatically rollback to the previous version:

```yaml
deploy:
  update_config:
    failure_action: rollback
  rollback_config:
    parallelism: 1
    delay: 5s
```

### 4.4 Placement Constraints and Preferences

| Feature | Description | Example |
|---------|-------------|---------|
| **Constraints** | Hard requirements -- task MUST run on matching nodes | `node.role == manager` |
| **Preferences** | Soft distribution -- spread tasks evenly across label values | `spread: node.labels.zone` |
| **Node labels** | Custom metadata on nodes for targeting | `node.labels.disktype == ssd` |

Built-in constraint fields:
- `node.id` -- Node ID
- `node.hostname` -- Node hostname
- `node.role` -- `manager` or `worker`
- `node.platform.os` -- Operating system
- `node.platform.arch` -- Architecture
- `node.labels.<key>` -- Custom node labels
- `engine.labels.<key>` -- Engine labels

### 4.5 Resource Constraints

```yaml
deploy:
  resources:
    limits:
      cpus: '0.50'     # CPU cores limit
      memory: 50M       # Memory limit
      pids: 100         # PID limit
    reservations:
      cpus: '0.25'     # Guaranteed CPU
      memory: 20M       # Guaranteed memory
      devices:          # GPU/TPU reservation
        - capabilities: [gpu]
          driver: nvidia
          count: 1
```

### 4.6 Health Checks

Swarm uses Docker health checks to determine task health:

```yaml
services:
  web:
    image: nginx
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

Unhealthy tasks are automatically rescheduled by the orchestrator.

---

## 5. Desired State Reconciliation (Built-in)

The Swarm manager **continuously monitors** and reconciles cluster state:

| Scenario | Swarm Response |
|----------|----------------|
| Worker node crashes | Reschedules tasks on available nodes |
| Container exits unexpectedly | Restarts based on restart_policy |
| Node rejoins after outage | Rebalances if needed |
| Service scaled up/down | Creates/removes tasks to match desired count |
| Resource exhaustion | Marks tasks as pending until resources available |

This is fundamentally different from Docker Compose, where the user manages container lifecycle manually.

---

## 6. Backup and Disaster Recovery (Built-in)

### 6.1 Swarm State Backup

All swarm state is stored in `/var/lib/docker/swarm/` on manager nodes:
- Raft logs (encrypted)
- TLS certificates
- Encryption keys
- Service definitions

**Backup procedure:**
1. Stop Docker on one manager (maintain quorum with others)
2. Copy entire `/var/lib/docker/swarm/` directory
3. Restart Docker

**Restore procedure:**
1. Stop Docker on new node
2. Replace `/var/lib/docker/swarm/` with backup
3. Start Docker
4. `docker swarm init --force-new-cluster`
5. Add new manager and worker nodes

### 6.2 Quorum Recovery

If quorum is lost (majority of managers down), existing worker tasks continue running but no management operations are possible.

Recovery: `docker swarm init --force-new-cluster` on a remaining manager forces it to become a single-manager swarm. Then add new managers to restore fault tolerance.

---

## 7. Complementary Ecosystem Tools

These are NOT part of Docker Swarm but integrate tightly with it for our ha-kit StackKit.

### 7.1 Reverse Proxy / Load Balancing

| Tool | Integration | License | Role in ha-kit |
|------|------------|---------|-------------------|
| **Traefik** | Native Docker Swarm provider; auto-discovers services via labels; runs as global service | MIT | Primary reverse proxy (L7) |
| **HAProxy** | DNSRR endpoint mode for direct backend access; can use Swarm DNS for service discovery | GPL-2.0 | L4 load balancer + health checks |
| **Keepalived** | Runs alongside HAProxy for VIP failover (VRRP) | GPL-2.0 | Floating VIP for external access |

**Traefik + Swarm integration:**
```yaml
services:
  traefik:
    image: traefik:v3
    deploy:
      mode: global
      placement:
        constraints:
          - node.role == manager
    command:
      - --providers.swarm.endpoint=unix:///var/run/docker.sock
      - --providers.swarm.exposedByDefault=false
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  web:
    image: nginx
    deploy:
      replicas: 3
      labels:
        - traefik.enable=true
        - traefik.http.routers.web.rule=Host(`example.com`)
        - traefik.http.services.web.loadbalancer.server.port=80
```

**HAProxy + Swarm DNSRR:**
```yaml
services:
  haproxy:
    image: haproxy:lts
    deploy:
      mode: global
    # HAProxy resolves service names via Swarm DNS

  backend:
    image: myapp
    deploy:
      replicas: 3
      endpoint_mode: dnsrr  # Let HAProxy handle balancing
```

### 7.2 Database HA

| Tool | Purpose | License | Swarm Integration |
|------|---------|---------|-------------------|
| **Patroni** | PostgreSQL HA (leader election, failover) | MIT | Runs as replicated service; uses etcd for consensus |
| **etcd** | Distributed KV store for Patroni and CoreDNS | Apache-2.0 | Runs as replicated service (3 replicas, placement constraints) |
| **Valkey Sentinel** | Redis-compatible HA (monitoring, failover) | BSD-3-Clause | Sentinel as global service, Valkey as replicated |

### 7.3 Service Discovery (Beyond Built-in)

| Tool | Purpose | License | Swarm Integration |
|------|---------|---------|-------------------|
| **CoreDNS** | Authoritative DNS with etcd backend | Apache-2.0 | Extends Swarm's built-in DNS with custom zones |
| **Swarm built-in DNS** | Service name resolution | Built-in | Automatic; no configuration needed |

Swarm's built-in DNS handles service-to-service communication. CoreDNS + etcd extends this with custom DNS zones for external resolution and advanced routing.

### 7.4 Storage

| Tool | Purpose | License | Swarm Integration |
|------|---------|---------|-------------------|
| **GlusterFS** | Distributed filesystem | GPL-3.0 | Volume plugin; replicated volumes across Swarm nodes |
| **Docker volumes** | Built-in volume management | Built-in | Named volumes survive container restarts and reschedules |

GlusterFS provides shared persistent storage across Swarm nodes. When a task is rescheduled to a different node, GlusterFS ensures data follows.

### 7.5 Monitoring and Observability

| Tool | Deployment Mode | License | Purpose |
|------|----------------|---------|---------|
| **Prometheus** | Replicated service | Apache-2.0 | Metrics collection and alerting |
| **Grafana** | Replicated service | AGPL-3.0 | Dashboards and visualization |
| **cAdvisor** | Global service | Apache-2.0 | Container-level metrics (CPU, memory, network per container) |
| **Node Exporter** | Global service | Apache-2.0 | Host-level metrics (disk, CPU, memory per node) |
| **Loki** | Replicated service | AGPL-3.0 | Log aggregation (pairs with Grafana) |
| **Promtail** | Global service | Apache-2.0 | Log collector (ships to Loki) |
| **Alertmanager** | Replicated service | Apache-2.0 | Alert routing, grouping, silencing |

**Swarm-native deployment pattern:**
- **Global services** (one per node): cAdvisor, Node Exporter, Promtail
- **Replicated services** (pinned to managers or specific nodes): Prometheus, Grafana, Loki, Alertmanager

### 7.6 Management UIs

| Tool | License | Purpose |
|------|---------|---------|
| **Portainer CE** | Zlib | Web UI for Swarm management (services, stacks, nodes, volumes) |
| **Swarmpit** | AGPL-3.0 | Lightweight Swarm-specific management UI |

### 7.7 Identity and Auth

| Tool | License | Purpose |
|------|---------|---------|
| **LLDAP** | GPL-3.0 | Lightweight LDAP directory |
| **Step-CA** | Apache-2.0 | Internal PKI / certificate authority |
| **TinyAuth** | MIT | Minimal forward-auth proxy |
| **PocketID** | MIT | Lightweight OIDC provider |

---

## 8. Compose Deploy Specification -- Full Reference

The `deploy` key in Compose files is the interface between Docker Compose files and Docker Swarm. This is the specification that kombify generates.

### 8.1 Complete Attribute Map

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | string | `replicated` | `replicated`, `global`, `replicated-job`, `global-job` |
| `replicas` | integer | 1 | Number of tasks (replicated mode only) |
| `endpoint_mode` | string | `vip` | `vip` or `dnsrr` |
| `labels` | map | - | Service-level metadata (not container-level) |
| `placement.constraints` | list | - | Hard scheduling requirements |
| `placement.preferences` | list | - | Soft scheduling preferences (spread strategy) |
| `resources.limits` | object | - | CPU, memory, PID limits |
| `resources.reservations` | object | - | Guaranteed CPU, memory, devices (GPU/TPU) |
| `update_config` | object | - | Rolling update parameters |
| `rollback_config` | object | - | Rollback parameters |
| `restart_policy` | object | - | Restart behavior (condition, delay, max_attempts, window) |

### 8.2 Update/Rollback Config Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `parallelism` | integer | 1 | Tasks to update at a time (0 = all) |
| `delay` | duration | 0s | Wait between task group updates |
| `failure_action` | string | `pause` | `continue`, `rollback`, `pause` |
| `monitor` | duration | 0s | Time to monitor after each update |
| `max_failure_ratio` | float | 0 | Acceptable failure rate |
| `order` | string | `stop-first` | `stop-first` or `start-first` |

### 8.3 Restart Policy Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `condition` | string | `any` | `none`, `on-failure`, `any` |
| `delay` | duration | 0s | Wait between restart attempts |
| `max_attempts` | integer | unlimited | Max failed restarts before giving up |
| `window` | duration | immediate | Time window to evaluate restart success |

---

## 9. Docker Swarm CLI Command Reference

### 9.1 Swarm Management

| Command | Purpose |
|---------|---------|
| `docker swarm init` | Initialize a new swarm |
| `docker swarm join` | Join node to existing swarm |
| `docker swarm leave` | Leave the swarm |
| `docker swarm update` | Update swarm settings (cert rotation, autolock, etc.) |
| `docker swarm unlock` | Unlock a locked swarm |
| `docker swarm unlock-key` | Manage unlock key |
| `docker swarm join-token` | Manage join tokens (rotate for security) |

### 9.2 Node Management

| Command | Purpose |
|---------|---------|
| `docker node ls` | List nodes in the swarm |
| `docker node inspect` | Detailed node info |
| `docker node update` | Update node (labels, availability, role) |
| `docker node promote` | Promote worker to manager |
| `docker node demote` | Demote manager to worker |
| `docker node rm` | Remove node from swarm |

### 9.3 Service Management

| Command | Purpose |
|---------|---------|
| `docker service create` | Create a new service |
| `docker service ls` | List services |
| `docker service inspect` | Detailed service info |
| `docker service ps` | List tasks for a service |
| `docker service update` | Update service configuration |
| `docker service scale` | Scale service replicas |
| `docker service rollback` | Rollback to previous version |
| `docker service rm` | Remove a service |
| `docker service logs` | View service logs (aggregated from all tasks) |

### 9.4 Stack Management

| Command | Purpose |
|---------|---------|
| `docker stack deploy` | Deploy a stack from a Compose file |
| `docker stack ls` | List stacks |
| `docker stack ps` | List tasks in a stack |
| `docker stack services` | List services in a stack |
| `docker stack rm` | Remove a stack |

### 9.5 Secret and Config Management

| Command | Purpose |
|---------|---------|
| `docker secret create` | Create a secret |
| `docker secret ls` | List secrets |
| `docker secret inspect` | Inspect secret metadata (not content) |
| `docker secret rm` | Remove a secret |
| `docker config create` | Create a config |
| `docker config ls` | List configs |
| `docker config inspect` | Inspect config |
| `docker config rm` | Remove a config |

---

## 10. kombify ha-kit Alignment Matrix

Maps every Swarm capability to how ha-kit uses it.

| Swarm Feature | ha-kit Usage | Status |
|---------------|-----------------|--------|
| **Raft consensus** | 3 manager nodes for quorum | Core |
| **Overlay networks** | Encrypted overlay for all inter-service traffic | Core |
| **Ingress routing mesh** | Default for most services; bypassed for Traefik (host mode) | Core |
| **Built-in DNS** | Service-to-service discovery within the swarm | Core |
| **VIP endpoint mode** | Default for most services | Core |
| **DNSRR endpoint mode** | Used for HAProxy backends | Core |
| **Secrets** | Database passwords, TLS certs, API keys | Core |
| **Configs** | Traefik config, HAProxy config, CoreDNS zones, Prometheus config | Core |
| **Rolling updates** | Zero-downtime deploys for all application services | Core |
| **Automatic rollback** | Failure action: rollback on all critical services | Core |
| **Placement constraints** | Manager-only nodes for control plane; worker nodes for workloads | Core |
| **Placement preferences** | Spread across availability zones (if applicable) | Core |
| **Global mode** | Traefik, cAdvisor, Node Exporter, Promtail, Keepalived | Core |
| **Replicated mode** | Application services, Patroni, Valkey, Prometheus, Grafana | Core |
| **Resource limits** | Memory/CPU limits on all services | Core |
| **Resource reservations** | Guaranteed resources for critical services (DB, etcd) | Core |
| **Health checks** | All services define health checks for rescheduling | Core |
| **mTLS** | Automatic node-to-node encryption | Core |
| **Autolock** | Optional; recommended for production | Add-on |
| **Node labels** | Zone labels, disk type labels, role labels | Core |
| **Manager drain** | Dedicate managers to control plane in larger clusters | Optional |
| **Swarm backup** | `/var/lib/docker/swarm/` backup via add-on | Add-on |
| **Stack deploy** | All services deployed via `docker stack deploy` from Compose files | Core |
| **Service logs** | Aggregated logs from all tasks via `docker service logs` | Core |
| **GPU reservations** | Reserved for AI workload add-on | Add-on |

### 10.1 Services by Deploy Mode

**Global services** (one per node):
- Traefik (reverse proxy, host mode ports)
- cAdvisor (container metrics)
- Node Exporter (host metrics)
- Promtail (log collection)
- Keepalived (VIP failover)
- HAProxy (L4 load balancer)

**Replicated services** (specific replica count):
- Patroni (PostgreSQL HA) -- 3 replicas
- etcd -- 3 replicas, pinned to managers
- Valkey -- 1 primary + 2 replicas
- Valkey Sentinel -- 3 replicas
- CoreDNS -- 2-3 replicas
- Prometheus -- 1-2 replicas
- Grafana -- 1 replica
- Loki -- 1 replica
- Alertmanager -- 1-2 replicas
- LLDAP -- 1-2 replicas
- Step-CA -- 1 replica (with backup)
- TinyAuth / PocketID -- 2 replicas
- Application services -- user-defined

### 10.2 Network Topology

```
                    ┌─────────────────────────────────────┐
                    │         External Clients             │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │     Keepalived VIP (Floating IP)     │
                    └──────────────┬──────────────────────┘
                                   │
             ┌─────────────────────┼─────────────────────┐
             │                     │                     │
     ┌───────▼───────┐   ┌────────▼──────┐   ┌──────────▼────┐
     │  Node 1 (mgr) │   │ Node 2 (mgr)  │   │ Node 3 (mgr)  │
     │  ┌──────────┐  │   │ ┌──────────┐  │   │ ┌──────────┐  │
     │  │ Traefik  │  │   │ │ Traefik  │  │   │ │ Traefik  │  │
     │  │(host:443)│  │   │ │(host:443)│  │   │ │(host:443)│  │
     │  └────┬─────┘  │   │ └────┬─────┘  │   │ └────┬─────┘  │
     │       │        │   │      │        │   │      │        │
     │  ┌────▼────────┴───┴──────▼────────┴───┴──────▼────┐   │
     │  │          Swarm Overlay Network (encrypted)       │   │
     │  │                                                   │   │
     │  │  ┌─────────┐ ┌─────────┐ ┌──────────┐           │   │
     │  │  │Patroni  │ │ Valkey  │ │ CoreDNS  │           │   │
     │  │  │+etcd    │ │+Sentinel│ │ +etcd    │           │   │
     │  │  └─────────┘ └─────────┘ └──────────┘           │   │
     │  │                                                   │   │
     │  │  ┌─────────┐ ┌─────────┐ ┌──────────┐           │   │
     │  │  │  App    │ │  App    │ │   App    │           │   │
     │  │  │Services │ │Services │ │ Services │           │   │
     │  │  └─────────┘ └─────────┘ └──────────┘           │   │
     │  └───────────────────────────────────────────────────┘   │
     └─────────────────────────────────────────────────────────┘
```

### 10.3 Secret/Config Usage

| Object | Type | Used By |
|--------|------|---------|
| `db_password` | Secret | Patroni, application services |
| `db_replication_password` | Secret | Patroni replicas |
| `valkey_password` | Secret | Valkey, application services |
| `lldap_admin_password` | Secret | LLDAP |
| `step_ca_password` | Secret | Step-CA |
| `traefik_config` | Config | Traefik static configuration |
| `haproxy_config` | Config | HAProxy configuration |
| `coredns_corefile` | Config | CoreDNS zone configuration |
| `prometheus_config` | Config | Prometheus scrape configuration |
| `alertmanager_config` | Config | Alertmanager routing rules |

---

## 11. What Docker Swarm Does NOT Provide (Gaps Filled by ha-kit)

| Gap | Solution in ha-kit |
|-----|----------------------|
| **No autoscaling** | Manual scaling via `docker service scale`; could add Prometheus-based alerts |
| **No built-in ingress TLS termination** | Traefik handles TLS with ACME/Let's Encrypt |
| **No advanced L7 routing** | Traefik provides path-based, header-based, weighted routing |
| **No database HA** | Patroni + etcd for PostgreSQL; Valkey Sentinel for cache |
| **No distributed storage** | GlusterFS (add-on) for shared volumes |
| **No external DNS** | CoreDNS + etcd for custom DNS zones |
| **No built-in monitoring** | Prometheus + Grafana + cAdvisor + Node Exporter + Loki stack |
| **No VIP failover** | Keepalived for floating VIP on the network |
| **No advanced health check actions** | Traefik health checks + HAProxy health checks complement Docker's |
| **No GitOps** | PaaS (Coolify/Dokploy) provides git-based deployment |
| **No identity management** | LLDAP + Step-CA + TinyAuth/PocketID |
| **Round-robin only LB** | HAProxy for weighted, least-connections, sticky sessions |

---

## 12. Docker Swarm Operational Best Practices

### 12.1 Manager Node Operations
- Always use **odd number** of managers (3 or 5)
- Use **fixed IP addresses** for managers (dynamic OK for workers)
- **Drain managers** in production to isolate control plane
- **Distribute managers** across availability zones
- Never copy Raft data between nodes

### 12.2 Networking
- Use **encrypted overlays** for sensitive traffic (`--opt encrypted`)
- Customize ingress network to enable encryption
- Keep overlay networks at **/24 size** (256 addresses)
- Use **DNSRR** with external load balancers (HAProxy)
- Use **host mode publishing** for Traefik to preserve client IPs

### 12.3 Security
- Enable **autolock** for production swarms
- **Rotate join tokens** periodically (`docker swarm join-token --rotate`)
- Set **custom cert rotation** interval (`--cert-expiry`)
- Use **secrets** for all sensitive data (never environment variables for passwords)
- Use **configs** for non-sensitive configuration files
- Restrict Docker socket access (read-only mount for Traefik)

### 12.4 Updates
- Always set **`failure_action: rollback`** for critical services
- Use **`order: start-first`** for zero-downtime web services
- Use **`order: stop-first`** for stateful services (databases)
- Set **`monitor`** duration to detect slow failures
- Keep **`max_failure_ratio`** low (0.1 or less)

### 12.5 Backup
- Regular backup of `/var/lib/docker/swarm/` from a manager
- Store **autolock key** securely offline
- Test restore procedure with `--force-new-cluster`
- Run 5 managers if doing regular backups (can lose 1 manager during backup + 1 for fault tolerance)

---

## 13. Sources

- Docker Swarm Mode Overview: https://docs.docker.com/engine/swarm/
- Swarm Key Concepts: https://docs.docker.com/engine/swarm/key-concepts/
- Swarm Networking: https://docs.docker.com/engine/swarm/networking/
- Swarm Ingress: https://docs.docker.com/engine/swarm/ingress/
- Swarm Secrets: https://docs.docker.com/engine/swarm/secrets/
- Swarm Configs: https://docs.docker.com/engine/swarm/configs/
- Swarm Admin Guide: https://docs.docker.com/engine/swarm/admin_guide/
- Swarm Services: https://docs.docker.com/engine/swarm/services/
- Swarm Autolock: https://docs.docker.com/engine/swarm/swarm_manager_locking/
- Compose Deploy Specification: https://docs.docker.com/reference/compose-file/deploy/
- Swarm Stack Deploy: https://docs.docker.com/engine/swarm/stack-deploy/
- Traefik + Docker Swarm: https://traefik.io/blog/traefik-and-docker-swarm/
- HAProxy on Docker Swarm: https://www.haproxy.com/blog/haproxy-on-docker-swarm-load-balancing-and-dns-service-discovery

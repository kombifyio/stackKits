# HA-Homelab StackKit: Research & Architecture Document

> Research findings for the `ha-homelab` StackKit. No Kubernetes.
> Docker Compose per node with coordination layer for high availability.
> Date: 2026-02-11
>
> **LICENSE UPDATE (2026-02-11)**: All tool recommendations have been re-evaluated
> from the perspective of kombify as a SaaS vendor. See `docs/license-compliance-saas.md`
> for the full analysis. Key changes: Valkey replaces Redis, CoreDNS+etcd replaces Consul,
> Nomad dropped as default orchestration.

---

## 1. What Changes From modern-homelab to ha-homelab

modern-homelab assumes: if a node goes down, services are unavailable until someone intervenes.
ha-homelab assumes: if a node goes down, services continue with minimal interruption.

This is not just "add more servers." It requires new infrastructure primitives:

| Concern | modern-homelab | ha-homelab |
|---------|---------------|------------|
| **Failure model** | Manual recovery | Automatic failover |
| **Load balancing** | Traefik on one node | HAProxy + Keepalived (VIP) |
| **Storage** | Local volumes per node | Replicated storage (GlusterFS or DRBD+ZFS) |
| **Databases** | Single PostgreSQL | Patroni cluster (PostgreSQL HA) |
| **Cache** | Single Redis/Valkey | **Valkey** Sentinel (3-node quorum) |
| **Service discovery** | Static Docker Compose | **CoreDNS + etcd** (DNS-based) |
| **Inter-node security** | Optional mTLS | Mandatory mTLS (Step-CA RA mode) |
| **Secrets** | SOPS+age (static) | SOPS+age + rotation strategy |
| **Coordination** | PaaS (Coolify/Dokploy) | PaaS + health-based failover scripts |
| **Minimum nodes** | 2 (1 cloud + 1 local) | 3 (quorum requirement) |
| **Network** | Best-effort | VRRP failover, health probes |

---

## 2. The Quorum Problem

HA requires **odd-numbered node counts** (3, 5, 7) for consensus. With 2 nodes, a network split means neither node can determine if the other is dead or just unreachable (split-brain). The minimum viable HA setup is **3 nodes**.

**Recommended minimum topology:**
```
Cloud VPS 1  --- entry point, HAProxy+Keepalived MASTER, etcd member
Cloud VPS 2  --- entry point, HAProxy+Keepalived BACKUP, etcd member
Local Node 1 --- compute + storage, etcd member, GlusterFS brick
```

For full local HA (data sovereignty):
```
Cloud VPS 1  --- entry point, HAProxy+Keepalived
Local Node 1 --- compute + storage, etcd member
Local Node 2 --- compute + storage, etcd member
Local Node 3 --- compute + storage, etcd member
```

---

## 3. Foundational Patterns

### 3.1 VIP Failover with Keepalived + VRRP

The entry point to the cluster must be a single IP. Keepalived provides this via the Virtual Router Redundancy Protocol (VRRP).

**How it works:**
- One node is MASTER (holds the VIP), others are BACKUP
- MASTER sends VRRP advertisements every 1 second
- If BACKUP stops hearing advertisements, highest-priority BACKUP takes over VIP
- Health check scripts reduce priority when a node's services are unhealthy
- Failover happens in 1-3 seconds

**Key config requirements:**
- `NET_ADMIN` + `NET_BROADCAST` capabilities for Docker containers
- Host networking mode (VRRP doesn't work with bridge networks)
- Unicast mode for cloud environments (multicast often blocked)
- `nopreempt` option if you want the recovered node NOT to reclaim VIP automatically

**For hybrid (cloud+local):**
- Keepalived runs on cloud VPS nodes (public IPs)
- Local nodes are behind tunnel, don't need VIP
- Cloud VIP is what DNS points to

**Docker Compose pattern:**
```yaml
services:
  keepalived:
    image: osixia/keepalived:2.0.20
    network_mode: host
    cap_add: [NET_ADMIN, NET_BROADCAST]
    restart: unless-stopped
    volumes:
      - ./keepalived.conf:/container/service/keepalived/assets/keepalived.conf:ro
      - ./check_service.sh:/usr/local/bin/check_service.sh:ro
```

### 3.2 Load Balancing with HAProxy

HAProxy distributes traffic across Docker hosts and performs health checking.

**Pattern:** Keepalived manages the VIP, HAProxy handles the actual routing.

**Key features for HA:**
- Health checks every 3s, 2 failures = server marked down
- `option redispatch` -- retry failed request on another server
- Stats dashboard on :8404 for visibility
- Connection draining during maintenance

**Config pattern:**
```
backend app_servers
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server docker1 192.168.1.10:8080 check inter 3s fall 2 rise 3
    server docker2 192.168.1.11:8080 check inter 3s fall 2 rise 3
```

**Relationship to Traefik:** Traefik remains the per-node reverse proxy (TLS termination, routing). HAProxy is the cross-node load balancer in front of Traefik instances.

```
Internet -> VIP -> HAProxy -> [Traefik@node1, Traefik@node2, Traefik@node3] -> Services
```

### 3.3 Docker Daemon Hardening for HA

Every Docker host needs:
```json
{
  "live-restore": true,
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "5" },
  "default-ulimits": { "nofile": { "Hard": 65536, "Soft": 65536 } }
}
```

- `live-restore: true` -- containers survive Docker daemon restarts (critical for updates)
- All containers: `restart: unless-stopped`
- Health checks on every service

---

## 4. Storage

This is the hardest problem in Docker-native HA. Containers are ephemeral; data is not.

### 4.1 Storage Decision Matrix

| Solution | Type | Nodes | Complexity | Use Case | License |
|----------|------|-------|------------|----------|---------|
| **GlusterFS** | Distributed FS | 2-10 | Medium | Shared files, uploads, media | GPL-3 |
| **DRBD + ZFS** | Block replication | 2-3 | Medium-High | Databases, critical data | GPL-2 / CDDL |
| **NFS** | Network FS | Any | Low | Read-heavy, simple mounts | N/A |
| **Litestream** | SQLite backup | 1+S3 | Low | SQLite-based apps | Apache-2 |
| **LiteFS** | SQLite replication | 2+ | Low-Medium | SQLite read replicas | Apache-2 |
| **Ceph** | Distributed block+FS | 5+ | Very High | NOT for homelab | LGPL |

### 4.2 Recommendation: Tiered Storage

**Tier 1 -- GlusterFS (shared file storage)**
- Best for: uploads, media, static files, config
- Replicated volume across 2-3 nodes (every node has full copy)
- ~250 MB/s write, ~280 MB/s read on consumer SSDs
- Self-healing when replicas diverge after node failure
- Red Hat commercial support ended 2024, but open-source project still active
- Weakness: small file metadata overhead, split-brain needs manual intervention
- Docker pattern: mount GlusterFS -> bind mount into containers

```bash
# Create 3-way replicated volume
gluster volume create app-data replica 3 \
  node1:/data/gluster/brick1 \
  node2:/data/gluster/brick1 \
  node3:/data/gluster/brick1
```

**Tier 2 -- DRBD + ZFS (block-level replication for critical data)**
- Best for: database volumes, anything needing data integrity guarantees
- Synchronous replication: every write confirmed on both nodes before returning
- ZFS provides: checksums, snapshots, self-healing, compression
- Active/passive: primary node writes, secondary mirrors in real-time
- Weakness: synchronous replication adds write latency, RAM-hungry (ARC cache)
- Best for 2-node HA pairs

**Tier 3 -- External / managed storage**
- S3-compatible (Hetzner Object Storage, Backblaze B2) for backups
- Stateless containers pointing to external PostgreSQL where possible

### 4.3 What NOT to Use

- **Ceph**: Minimum 5 nodes, enterprise hardware expectations, massive complexity. Not for homelab.
- **Longhorn**: Kubernetes-native, not applicable.
- **Docker named volumes alone**: Not replicated, node-local only.

---

## 5. Database High Availability

### 5.1 PostgreSQL: Patroni + etcd + HAProxy

This is the standard PostgreSQL HA pattern. Patroni manages leader election, etcd stores cluster state, HAProxy routes to the current primary.

```
Clients -> HAProxy (port 5432) -> Patroni Leader (PostgreSQL primary)
                                  Patroni Replica 1
                                  Patroni Replica 2
```

**Components:**
- **Patroni** -- manages PostgreSQL replication, automatic failover, fencing
- **etcd** -- distributed key-value store for leader election (needs 3 nodes for quorum)
- **HAProxy** -- routes connections to current primary, read replicas optional

**Why Patroni over raw streaming replication:**
- Automatic failover (no manual pg_promote)
- Fencing: prevents split-brain (old primary can't accept writes)
- REST API for health checks
- Switchover command for planned maintenance

**License:** Patroni=MIT, etcd=Apache-2

**Alternative for smaller setups:** PostgreSQL streaming replication + repmgr (simpler but less robust failover).

### 5.2 Redis: Sentinel

Redis Sentinel provides HA for Redis without the complexity of Redis Cluster.

**How it works:**
- 3 Sentinel instances monitor the Redis primary
- If primary fails, Sentinels vote on promotion (needs quorum of 2/3)
- Sentinel reconfigures replicas to follow new primary
- Clients connect to Sentinel to discover current primary

**Why Sentinel over Redis Cluster:**
- Redis Cluster shards data (complexity, changes client code)
- Sentinel is pure failover (same Redis, just HA)
- For homelab scale, you don't need sharding

**License:** Redis (pre-7.4)=BSD-3, Redis 7.4+=RSALv2+SSPLv1. Consider **Valkey** (Linux Foundation fork, BSD-3) or **KeyDB** (BSD-3, multi-threaded).

### 5.3 SQLite: Litestream + LiteFS

Many homelab apps use SQLite (Vaultwarden, Radicale, TinyAuth, etc.).

- **Litestream**: Continuous backup of SQLite to S3/local path. Not replication -- recovery from backup. RPO: seconds. RTO: minutes.
- **LiteFS**: FUSE-based replication. One primary node, read replicas. Automatic failover via Consul lease. More complex but true replication.

**Recommendation:** Litestream for most homelab apps (simple, reliable backup). LiteFS only if you need read scaling.

**License:** Both Apache-2.

---

## 6. Service Discovery

> **LICENSE UPDATE**: Consul (BSL-1.1) is **not recommended** for kombify as a SaaS vendor.
> HashiCorp's BSL restricts "offering the Licensed Work to third parties on a hosted or
> embedded basis which is competitive with HashiCorp's products." kombify shipping
> infrastructure configs with Consul is a gray area at best. See `docs/license-compliance-saas.md`.

### 6.1 CoreDNS + etcd (Recommended)

In modern-homelab, services are at known IPs in docker-compose files. In ha-homelab, services can move between nodes. You need service discovery.

**CoreDNS + etcd provides:**
- **Service registry**: Services register via HTTP PUT to etcd, CoreDNS reads records
- **DNS interface**: `myservice.ha.local` resolves to healthy instances
- **KV store**: etcd provides distributed KV (also needed by Patroni)
- **Health checking**: External health-check script updates etcd entries (removes unhealthy)

**Architecture:**
- etcd cluster (3 nodes, already needed for Patroni)
- CoreDNS with etcd plugin, serving DNS-SD records
- Health-check sidecar per node: periodically checks services, updates etcd
- Services resolve peers via DNS

**Licenses:** CoreDNS=Apache-2, etcd=Apache-2. Zero risk for SaaS use.

**Trade-off vs Consul:**
- Consul has built-in health checking; CoreDNS+etcd needs external health scripts
- Consul has gossip protocol for fast convergence; etcd uses Raft (slightly slower failover detection)
- etcd is already required by Patroni, so this adds only CoreDNS + health scripts

### 6.2 Consul (Opt-in Add-on, License Warning)

Consul remains the most feature-complete service discovery tool for Docker environments. If a customer has their own HashiCorp license or the BSL is acceptable for their use case, it can be offered as an opt-in add-on.

**Consul provides:**
- Service registry, health checking, KV store, DNS interface, prepared queries
- Docker integration via `registrator`
- Single binary, low resource usage

**License:** BSL-1.1. **Not safe for kombify's default StackKit without a commercial license from HashiCorp.** Contact licensing@hashicorp.com if needed.

### 6.3 Simple DNS (Minimal Alternative)

For stable clusters where services don't move often:
- CoreDNS with file plugin, updated by a cron script
- Or simple `/etc/hosts` management via deploy scripts
- Less dynamic, but works for predictable clusters

---

## 7. Security at HA Scale

HA increases the attack surface. More nodes, more network paths, more credentials.

### 7.1 Mandatory mTLS Between Nodes

In modern-homelab, inter-node traffic goes through tunnel (encrypted). In ha-homelab with local-only clusters, nodes communicate directly on LAN. This traffic MUST be encrypted.

**Step-CA in RA (Registration Authority) mode:**
- Root CA on a secure node (or offline)
- RA on each node for local certificate issuance
- Short-lived certificates (24h), auto-renewed
- All inter-node communication over mTLS

**What needs mTLS:**
- CoreDNS + etcd cluster communication
- etcd peer communication (Raft consensus)
- Patroni REST API
- DRBD replication traffic
- GlusterFS brick communication
- HAProxy to backend connections

### 7.2 Network Segmentation

Even on a flat LAN, use firewall rules:
- Management traffic (SSH, etcd, CoreDNS): restricted to cluster nodes
- Service traffic (HTTP/S): through HAProxy only
- Storage traffic (GlusterFS, DRBD): dedicated VLAN or subnet if possible
- VRRP traffic: between load balancer nodes only

### 7.3 Secrets at Scale

SOPS+age remains the base. Additional concerns:
- **Secret rotation**: Automated credential rotation for databases, Redis auth
- **Per-node secrets**: Each node gets only the secrets it needs
- **etcd encryption at rest**: etcd stores cluster state, must be encrypted
- **etcd RBAC**: Role-based access control for service registration/discovery

### 7.4 Hardened Docker

Beyond `daemon.json`:
- Rootless Docker where possible (not all HA components support it)
- AppArmor/seccomp profiles for containers
- Read-only root filesystem for stateless containers
- No `--privileged` (except Keepalived which needs NET_ADMIN)
- Image signing and verification
- Regular vulnerability scanning (Trivy)

---

## 8. Orchestration Without Kubernetes

### 8.1 The Coordination Problem

Docker Compose per node doesn't coordinate across nodes. Someone needs to decide:
- Which services run on which nodes
- When to restart failed services on another node
- How to do rolling updates across nodes

### 8.2 Options

**Option A: PaaS + Scripts (Pragmatic)**
- Coolify/Dokploy for deployments (already in modern-homelab)
- Keepalived + health check scripts for failover
- Simple bash deploy scripts for rolling updates
- Manual placement decisions in CUE configs
- **Pro**: Simple, builds on modern-homelab patterns
- **Con**: No automatic service rescheduling across nodes

**Option B: Nomad (Opt-in, Requires License Negotiation)**
- HashiCorp Nomad: lightweight job scheduler
- Supports Docker driver natively
- Single binary, 3-node server cluster for HA
- Handles placement, restarts, rolling deploys, service mesh
- Integrates with Consul (service discovery) and Vault (secrets)
- **Pro**: Real orchestration without K8s complexity
- **Con**: New learning curve
- **License**: BSL-1.1 -- **NOT safe for kombify as SaaS vendor without commercial license**.
  HashiCorp restricts "offering the Licensed Work to third parties on an embedded basis
  which is competitive with HashiCorp's products." Contact licensing@hashicorp.com.
  Versions >4 years old convert to MPL-2 (e.g., Nomad 1.6 Aug 2023 -> MPL-2 Aug 2027).

**Option C: Docker Swarm (Limited)**
- Built into Docker, simple to set up
- Declarative services, rolling updates, networking
- **Con**: Effectively abandoned by Docker Inc., no new features since 2019
- **Con**: Limited health check integration
- Not recommended for new deployments

### 8.3 Recommendation

**Option A (PaaS + Scripts) is the only default-safe option** due to Nomad's BSL-1.1 license. The CUE schema should still define an `orchestration` field for future extensibility (if a Nomad commercial license is negotiated):

```
orchestration: "compose-manual" | "nomad"
```

Default is `compose-manual`. Nomad requires explicit opt-in with license acknowledgment.

---

## 9. Observability in HA Mode

### 9.1 What Changes

Monitoring a single node is straightforward. Monitoring a cluster requires:
- **Cluster-wide dashboards**: See all nodes at once
- **Consensus monitoring**: Is etcd healthy? Is quorum maintained?
- **Failover event tracking**: When did VIP move? Why?
- **Replication lag**: Is the database replica falling behind?
- **Split-brain detection**: Are two nodes claiming to be primary?
- **Storage health**: GlusterFS heal status, DRBD sync state

### 9.2 Additional Monitoring Targets

Beyond modern-homelab's monitoring add-on (VictoriaMetrics + Grafana + Loki):

| Target | Metric | Alert Threshold |
|--------|--------|-----------------|
| etcd | leader changes, peer connectivity | >1 leader change/5min |
| CoreDNS | query latency, cache hit rate | query errors > 0 |
| Keepalived | VIP transitions, state flapping | >2 transitions/5min |
| HAProxy | backend health, connection errors | any backend down |
| Patroni | replication lag, timeline changes | lag > 10s |
| Valkey Sentinel | failover events, quorum size | quorum < 2 |
| GlusterFS | heal info, brick status | any brick offline |
| DRBD | connection state, sync percentage | state != UpToDate |

### 9.3 Alertmanager Integration

Modern-homelab monitoring uses VictoriaMetrics + vmalert. For HA:
- Alert on quorum loss (etcd, Valkey Sentinel)
- Alert on failover events (Keepalived, Patroni)
- Alert on replication issues (DRBD, PostgreSQL, GlusterFS)
- Alert on split-brain scenarios
- Notification channels: webhook (to Uptime Kuma or ntfy.sh)

---

## 10. Disaster Recovery

### 10.1 Backup Strategy Upgrade

modern-homelab's Restic 3-2-1 backup stays, but HA adds:
- **etcd snapshots**: Regular etcd backup (cluster state)
- **etcd snapshots**: `etcdctl snapshot save` for service discovery state
- **Database PITR**: PostgreSQL WAL archiving for point-in-time recovery
- **DRBD metadata backup**: DRBD resource configs + metadata

### 10.2 Recovery Scenarios

| Scenario | Recovery | RTO |
|----------|----------|-----|
| Single node failure | Automatic failover | 1-3 seconds (VIP), 10-30s (services) |
| Database primary failure | Patroni promotes replica | 10-30 seconds |
| Storage node failure | GlusterFS self-healing from replicas | Minutes (background) |
| Complete cluster failure | Restore from backup | Hours |
| Split-brain (2 primaries) | Fencing + manual resolution | Minutes (with alerts) |
| Network partition | Quorum side continues, minority stops | Automatic |

### 10.3 Fencing

Fencing ensures that a failed node doesn't come back and corrupt data by accepting writes when a new primary exists.

- **Patroni fencing**: Old primary's PostgreSQL is shut down before new primary is promoted
- **DRBD fencing**: Split-brain handler scripts
- **Application-level**: Health check scripts that stop containers when becoming BACKUP

---

## 11. Resource Requirements

### 11.1 Overhead of HA Components

| Component | CPU | RAM | Disk | Per Node? |
|-----------|-----|-----|------|-----------|
| Keepalived | Negligible | ~10 MB | - | On LB nodes |
| HAProxy | Low | ~50 MB | - | On LB nodes |
| CoreDNS | Low | ~50 MB | - | On 3+ nodes |
| etcd | Low | ~512 MB | 1 GB | On 3+ nodes |
| Patroni + PG | Medium | ~1 GB+ | Varies | On DB nodes |
| Redis Sentinel | Negligible | ~50 MB | - | On 3 nodes |
| GlusterFS | Low | ~256 MB | Varies | On storage nodes |

### 11.2 Minimum Viable HA Topology

**3-node local cluster (data sovereignty):**
```
Node 1 (4 CPU, 8 GB RAM, 200 GB SSD):
  - etcd, CoreDNS, Patroni (PG primary)
  - Keepalived MASTER, HAProxy, Traefik
  - GlusterFS brick

Node 2 (4 CPU, 8 GB RAM, 200 GB SSD):
  - etcd, CoreDNS, Patroni (PG replica)
  - Keepalived BACKUP, HAProxy, Traefik
  - GlusterFS brick

Node 3 (4 CPU, 8 GB RAM, 200 GB SSD):
  - etcd, CoreDNS, Patroni (PG replica)
  - Valkey Sentinel, application services
  - GlusterFS brick
```

**Hybrid (2 cloud + 2 local):**
```
Cloud 1 (2 CPU, 4 GB):
  - Keepalived MASTER, HAProxy, Traefik
  - etcd member

Cloud 2 (2 CPU, 4 GB):
  - Keepalived BACKUP, HAProxy, Traefik
  - etcd member

Local 1 (4 CPU, 16 GB, 500 GB):
  - etcd member, etcd, Patroni primary
  - GlusterFS, application services

Local 2 (4 CPU, 16 GB, 500 GB):
  - etcd, Patroni replica
  - GlusterFS, application services
```

---

## 12. What The CUE Schema Needs

### 12.1 New Base Concepts

The ha-homelab CUE schema needs to extend modern-homelab with:

```cue
#HAConfig: {
    // Quorum settings
    quorum: {
        minNodes: int & >=3
        consensusStore: "etcd"
    }

    // VIP failover
    vip: {
        enabled: bool | *true
        address: string         // The virtual IP
        interface: string       // Network interface
        mode: "active-passive" | "active-active"
    }

    // Load balancing
    loadBalancer: {
        provider: "haproxy"
        healthCheck: {
            interval: string | *"3s"
            fall: int | *2
            rise: int | *3
        }
    }

    // Storage
    storage: {
        shared: {
            provider: "glusterfs" | "nfs"
            replicaCount: int | *3
        }
        block?: {
            provider: "drbd"
            filesystem: "zfs" | "ext4"
        }
    }

    // Database HA
    database: {
        provider: "patroni"
        replicas: int | *2
        etcdNodes: int | *3
    }

    // Cache HA
    cache: {
        provider: "valkey-sentinel"
        sentinelCount: int | *3
    }

    // Service discovery
    discovery: {
        provider: "coredns-etcd" | "dns-static"
        servers: int | *3
    }

    // Orchestration
    orchestration: "compose-manual" | "nomad"
}
```

### 12.2 Service Definition Extensions

Each service needs HA metadata:

```cue
#HAServiceDefinition: base.#ServiceDefinition & {
    ha: {
        replicas: int | *1
        failoverMode: "active-passive" | "active-active" | "none"
        healthCheck: {
            endpoint: string
            interval: string | *"10s"
            timeout: string | *"5s"
            retries: int | *3
        }
        dataStrategy: "stateless" | "shared-fs" | "replicated-db" | "external"
        placement: {
            antiAffinity?: bool     // Don't run on same node as another instance
            preferLocal?: bool      // Prefer local nodes for latency
        }
    }
}
```

---

## 13. Open Questions / Decisions Needed

1. **GlusterFS vs DRBD+ZFS**: Should the default be GlusterFS (simpler, file-level) or DRBD+ZFS (stronger integrity, block-level)? Or tiered as described above?

2. ~~**Consul license (BSL-1.1)**~~ **RESOLVED**: Consul is NOT safe for kombify SaaS use. Default is CoreDNS + etcd. Consul available as opt-in add-on with license warning.

3. ~~**Nomad as future path**~~ **RESOLVED**: Nomad NOT safe for default due to BSL-1.1. Schema supports it as opt-in field. Commercial license negotiation needed before enabling.

4. ~~**Valkey vs Redis**~~ **RESOLVED**: Valkey (BSD-3) is the default. Redis 8+ AGPL-3 as conditional alternative. Redis 7.4 RSALv2/SSPLv1 is blocked.

5. ~~**etcd vs Consul for consensus**~~ **RESOLVED**: etcd is the only consensus store (needed for Patroni, also used by CoreDNS for service discovery). No Consul.

6. **Cloud VIP**: Most cloud providers don't support VRRP. Alternative: DNS failover, Floating IP API (Hetzner has this), or run Keepalived in unicast mode on a private network.

7. **Scope of HA**: Should every add-on service be HA, or only "platform" services (Traefik, DB, Valkey, identity)? The pragmatic answer is: HA for platform, single-instance for most add-ons with automatic restart.

---

## 14. Tool License Summary (SaaS-Vendor Perspective)

> See `docs/license-compliance-saas.md` for the full license compliance analysis.

| Tool | License | SaaS-Safe? | Status |
|------|---------|-----------|--------|
| HAProxy | GPL-2 | **YES** (config-gen only) | Stable, widely used |
| Keepalived | GPL-2 | **YES** (config-gen only) | Stable, battle-tested |
| GlusterFS | GPL-3 | **YES** (config-gen only) | Active, Red Hat support ended 2024 |
| DRBD | GPL-2 | **YES** (config-gen only) | Active (LINBIT) |
| ZFS (OpenZFS) | CDDL | **YES** | Active, stable |
| Patroni | MIT | **YES** | Active (Zalando) |
| etcd | Apache-2 | **YES** | Active (CNCF) |
| CoreDNS | Apache-2 | **YES** | Active (CNCF) |
| Valkey | BSD-3 | **YES** | Active (Linux Foundation fork) |
| Litestream | Apache-2 | **YES** | Active |
| LiteFS | Apache-2 | **YES** | Active (Fly.io) |
| Step-CA | Apache-2 | **YES** | Active (Smallstep) |
| Traefik | MIT | **YES** | Active |
| Consul | BSL-1.1 | **HIGH RISK** | Opt-in only, needs commercial license |
| Nomad | BSL-1.1 | **HIGH RISK** | Opt-in only, needs commercial license |
| Redis 8+ (AGPL) | AGPL-3 | **CONDITIONAL** | Safe if unmodified, source available |
| Redis 7.4 | RSALv2/SSPLv1 | **BLOCKED** | Do not use |

---

## 15. Summary: What ha-homelab Needs That modern-homelab Doesn't

### New Infrastructure Services
1. **Keepalived** -- VIP failover (VRRP)
2. **HAProxy** -- Cross-node load balancing
3. **CoreDNS + etcd** -- Service discovery + health checking (replaces Consul)
4. **etcd** -- Distributed consensus (for Patroni + CoreDNS)
5. **GlusterFS** -- Shared replicated storage
6. **DRBD+ZFS** -- Block-level replication (optional, for critical data)
7. **Patroni** -- PostgreSQL HA management
8. **Valkey Sentinel** -- Cache HA (BSD-3, replaces Redis)

### New Patterns
1. Quorum-based decision making (3+ nodes)
2. VIP-based entry points (not DNS-only)
3. Active-passive and active-active service placement
4. Health-check-driven failover scripts
5. Mandatory mTLS for all inter-node traffic
6. Fencing to prevent split-brain data corruption
7. Rolling deployment across nodes with capacity preservation
8. Replication lag monitoring and alerting

### New CUE Schema Concepts
1. `#HAConfig` -- cluster-wide HA configuration
2. `#HAServiceDefinition` -- per-service HA metadata
3. `#QuorumConfig` -- consensus requirements
4. `#VIPConfig` -- virtual IP management
5. `#StorageTier` -- tiered storage configuration
6. `#FailoverPolicy` -- how services handle node failure
7. `#PlacementConstraint` -- anti-affinity, node preference

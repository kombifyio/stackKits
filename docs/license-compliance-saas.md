# License Compliance Analysis: kombify as SaaS Vendor

> **Context**: kombify is a SaaS product that ships/orchestrates homelab infrastructure.
> License evaluation is from the perspective of a **commercial SaaS vendor** that
> generates configurations, references container images, and deploys software on
> customer hardware -- NOT from a homelab end-user perspective.
> Date: 2026-02-11

---

## 1. What kombify Actually Does (License-Relevant Actions)

Before evaluating licenses, we must define what kombify does with each piece of software:

| Action | License Trigger? | Description |
|--------|-----------------|-------------|
| **Generates config files** (Docker Compose, CUE) | Usually no | kombify produces YAML/CUE that references software. The configs themselves are kombify's work. |
| **References container images** (e.g. `image: haproxy:latest`) | Depends | Referencing a public image by name is not distribution. Hosting/mirroring images may be. |
| **Bundles binaries or source code** | Yes | If kombify ships actual binaries, source, or modified container images, that is distribution. |
| **Runs software on kombify's servers** (SaaS backend) | Depends on license | GPL: no trigger (SaaS loophole). AGPL: triggers source disclosure for modifications. |
| **Deploys software on customer hardware** | Customer's action | The customer pulls images and runs them. kombify provides instructions/automation. |
| **Provides a managed service** | Yes for RSALv2/BSL | If kombify operates software as a service for customers, restrictive licenses apply. |

**Critical distinction**: There is a significant legal difference between:
- **A)** "kombify generates a docker-compose.yml that says `image: consul:1.18`" (config generation)
- **B)** "kombify runs Consul as part of its SaaS platform" (managed service)
- **C)** "kombify distributes a Docker image containing Consul" (distribution)

For the ha-homelab StackKit, kombify primarily does **(A)**: generates configuration files that customers then use to deploy software on their own hardware. This is the most defensible position.

---

## 2. License Categories and SaaS Impact

### 2.1 Permissive Licenses (SAFE)

| License | Tools | SaaS Impact |
|---------|-------|-------------|
| **MIT** | Patroni, Litestream, LiteFS | No restrictions. Use freely in any context. |
| **Apache-2.0** | etcd, Step-CA, CoreDNS, Traefik | No restrictions. Patent grant included. Must preserve notices if distributing. |
| **BSD-2-Clause** | go-redis | No restrictions. |
| **BSD-3-Clause** | Valkey, Redis <=7.2, hiredis | No restrictions. |

**Verdict**: No action needed. These are safe for any SaaS use case.

### 2.2 GPL-2.0 / GPL-3.0 (CONDITIONAL -- Likely Safe)

| License | Tools |
|---------|-------|
| **GPL-2.0** | HAProxy, Keepalived, DRBD |
| **GPL-3.0** | GlusterFS |

**The GPL SaaS Loophole**: GPL's copyleft only triggers on **distribution** of the software (giving someone a copy of the binary/source). Running GPL software on a server to provide a service is NOT distribution under GPL. This is the exact "loophole" that AGPL was created to close.

**kombify's situation**:
- If kombify **generates config files** that tell customers to `docker pull haproxy:latest` -- NOT distribution. The customer pulls the image themselves from Docker Hub.
- If kombify **bundles or mirrors GPL binaries** in its own container registry or distribution -- THIS IS distribution and triggers GPL copyleft. kombify would need to provide corresponding source code.
- If kombify **runs HAProxy on its own servers** (e.g., as part of the SaaS backend) -- NOT distribution under GPL. No source code disclosure needed.
- If kombify **modifies GPL software and distributes the modifications** -- Must release modifications under GPL.

**Verdict**: SAFE if kombify only generates configs referencing public images. Do NOT bundle/mirror/redistribute GPL binaries. Do NOT distribute modified GPL containers without source.

**Risk mitigation**:
- Never host GPL container images on kombify infrastructure
- Always reference upstream images (e.g., `docker.io/haproxy:2.9`)
- If custom HAProxy configs are baked into images, publish those images with source
- Document that customers pull images directly from upstream

### 2.3 AGPL-3.0 (CONDITIONAL -- Needs Careful Handling)

| License | Tools |
|---------|-------|
| **AGPL-3.0** | Redis 8+ (if AGPL chosen from tri-license), older RediSearch/RedisJSON/RedisBloom |

**AGPL closes the SaaS loophole**: If you run AGPL software as a network service AND users interact with it over a network, you must provide the complete source code (including modifications) to those users.

**kombify's situation**:
- **Config generation only**: If kombify generates configs that deploy Redis 8 on customer hardware, kombify is NOT running Redis as a service. The customer is. The customer must comply with AGPL for their own deployment. This is likely safe for kombify.
- **Running AGPL on kombify servers**: If kombify's SaaS backend itself uses AGPL software (e.g., Redis as a cache for the kombify platform), kombify must offer source code of any modifications to its users. Unmodified AGPL software: just point to upstream source.
- **Modifications**: If kombify modifies AGPL software and deploys it (even as config), those modifications must be AGPL-licensed and source-available.

**Verdict**: SAFE for config generation. CONDITIONAL if kombify runs AGPL software server-side. Isolate AGPL components via containerization. Never modify AGPL code without releasing modifications.

**Risk mitigation**:
- For Redis 8+: choose **AGPL-3.0** from the tri-license (it's the most permissive option for this use case, since we're not modifying Redis)
- Never modify AGPL source without publishing modifications
- If running AGPL on kombify servers, add "Source Code" link in product UI pointing to upstream
- Use containerization to isolate AGPL from proprietary code

### 2.4 BSL-1.1 -- HashiCorp (HIGH RISK)

| License | Tools |
|---------|-------|
| **BSL-1.1** | Consul, Nomad, Vault, Terraform, Waypoint, Packer, Boundary |

**HashiCorp's Additional Use Grant** (exact text):
> "You may make production use of the Licensed Work, provided such use does not include offering the Licensed Work to third parties on a hosted or embedded basis which is competitive with HashiCorp's products."

**Key terms**:
- **"offering to third parties"**: kombify offers infrastructure orchestration to customers
- **"hosted or embedded basis"**: kombify either hosts or embeds these tools in its product
- **"competitive with HashiCorp's products"**: HashiCorp sells Consul (service mesh/discovery), Nomad (orchestration), Vault (secrets management)

**kombify's situation -- THIS IS THE CRITICAL RISK**:

kombify is a SaaS product that orchestrates infrastructure. It generates configs that deploy Consul for service discovery and potentially Nomad for orchestration. This is dangerously close to HashiCorp's own product offerings:

| HashiCorp Product | HashiCorp's Offering | kombify's Use | Competitive? |
|-------------------|---------------------|---------------|-------------|
| **Consul** | Service mesh, service discovery, distributed KV | Service discovery in HA homelab configs | **GRAY AREA** -- kombify provides infrastructure orchestration that includes Consul functionality |
| **Nomad** | Workload orchestration, job scheduling | Orchestration option in ha-homelab | **LIKELY YES** -- kombify orchestrating workloads via Nomad is directly competitive |
| **Vault** | Secrets management | Not currently used (we use SOPS+age) | Not applicable |
| **Terraform** | Infrastructure as Code | Not currently used (we use CUE) | Not applicable |

**The "embedded" question**: HashiCorp's FAQ Q14 asks "What does embedded mean?" Their examples from Apr 2024 update include products that deploy HashiCorp software as part of their offering. A SaaS product that generates Consul deployment configs and manages Consul clusters for customers would likely be considered "embedded."

**The kemitchell analysis** (Kyle Mitchell, IP attorney) notes:
- The BSL + Additional Use Grant + FAQ creates a complex licensing situation
- Custom licensing terms are available via licensing@hashicorp.com
- The "competitive" determination is ultimately HashiCorp's interpretation

**Verdict**: **HIGH RISK**. kombify generating configs that deploy Consul/Nomad for customers, as part of a paid SaaS infrastructure product, is at minimum a gray area and at worst a BSL violation. HashiCorp explicitly targets products that "offer the Licensed Work to third parties on a hosted or embedded basis."

**Options**:
1. **AVOID** -- Replace Consul with open-source alternatives (CoreDNS + etcd, or custom DNS-based discovery). Replace Nomad with compose-manual approach.
2. **NEGOTIATE** -- Contact licensing@hashicorp.com for a commercial license or exemption
3. **USE OLD VERSIONS** -- Consul/Nomad versions released >4 years ago are now MPL-2.0 (open source). But they lack security patches.
4. **USE FORKS** -- OpenTofu exists for Terraform; no equivalent for Consul/Nomad

**Recommendation**: **AVOID Consul and Nomad in the default ha-homelab StackKit**. Offer them only as an opt-in add-on with clear license warnings, or negotiate a commercial license with HashiCorp.

### 2.5 RSALv2 (BLOCKED for SaaS)

| License | Tools |
|---------|-------|
| **RSALv2** | Redis 7.4+ (Community Edition), Redis modules |

**RSALv2 restrictions** (exact text from Redis):
> You may not: Commercialize the software or provide it to others as a managed service in a way that provides the functionality of the Software available to third parties

**kombify's situation**:
- kombify generates configs that deploy Redis for customers as part of a paid SaaS product
- This could be interpreted as "providing Redis functionality to third parties" via kombify's service
- Even though kombify doesn't run Redis itself, it facilitates Redis deployment as part of a commercial offering

**Verdict**: **AVOID under RSALv2**. The restriction on providing functionality to third parties is broad. Use the AGPL-3.0 option (Redis 8+) or Valkey instead.

### 2.6 SSPLv1 (BLOCKED for SaaS)

| License | Tools |
|---------|-------|
| **SSPLv1** | Redis 7.4+ (alternative), MongoDB, Redis Insight (community) |

**SSPLv1 requirement**: If you offer the software as a service, you must release the complete source code of your entire service stack (not just modifications to the SSPL software, but everything -- your SaaS platform, deployment tools, management layers).

**Verdict**: **ABSOLUTELY BLOCKED**. SSPL is incompatible with any proprietary SaaS product. Never select SSPLv1 from a tri-license option.

### 2.7 CDDL-1.0 (SAFE)

| License | Tools |
|---------|-------|
| **CDDL-1.0** | OpenZFS |

**CDDL**: Weak copyleft, file-level scope. Commercial use allowed. Modifications to CDDL files must be released under CDDL, but does not extend to other files.

**kombify's situation**: If kombify generates ZFS configuration (e.g., `zpool create` commands in deploy scripts), that's not a CDDL work. kombify doesn't modify or distribute ZFS source.

**Verdict**: SAFE. CDDL does not restrict config generation or usage.

**Note**: CDDL is not GPL-compatible. Cannot link CDDL and GPL code in the same binary. This is a Linux kernel concern (ZFS module), not a kombify concern.

---

## 3. Tool-by-Tool Compliance Matrix

| Tool | License | Config-Gen Safe? | Self-Host Safe? | Bundle Safe? | SaaS Verdict |
|------|---------|-----------------|-----------------|-------------|-------------|
| **HAProxy** | GPL-2 | YES | YES (SaaS loophole) | NO (must provide source) | **SAFE** |
| **Keepalived** | GPL-2 | YES | YES | NO | **SAFE** |
| **GlusterFS** | GPL-3 | YES | YES | NO | **SAFE** |
| **DRBD** | GPL-2 | YES | YES | NO | **SAFE** |
| **OpenZFS** | CDDL | YES | YES | YES | **SAFE** |
| **Patroni** | MIT | YES | YES | YES | **SAFE** |
| **etcd** | Apache-2 | YES | YES | YES | **SAFE** |
| **Step-CA** | Apache-2 | YES | YES | YES | **SAFE** |
| **CoreDNS** | Apache-2 | YES | YES | YES | **SAFE** |
| **Traefik** | MIT | YES | YES | YES | **SAFE** |
| **Valkey** | BSD-3 | YES | YES | YES | **SAFE** |
| **Litestream** | Apache-2 | YES | YES | YES | **SAFE** |
| **LiteFS** | Apache-2 | YES | YES | YES | **SAFE** |
| **Redis 8+** | AGPL-3 (chosen) | YES | CONDITIONAL | NO w/o source | **CONDITIONAL** |
| **Consul** | BSL-1.1 | **GRAY AREA** | N/A | NO | **HIGH RISK** |
| **Nomad** | BSL-1.1 | **GRAY AREA** | N/A | NO | **HIGH RISK** |
| **Redis 7.4** | RSALv2/SSPLv1 | NO | NO | NO | **BLOCKED** |

---

## 4. Required Changes to ha-homelab StackKit

Based on this analysis, the following changes are needed:

### 4.1 MANDATORY Changes

| Current | Replace With | Reason |
|---------|-------------|--------|
| Redis (any version) | **Valkey** (BSD-3) | RSALv2/SSPLv1 too risky. AGPL-3 is conditional. Valkey is BSD-3, zero risk. |
| Consul (service discovery) | **CoreDNS + etcd** or **DNS-SD** | BSL-1.1 competitive risk. CoreDNS (Apache-2) + etcd (Apache-2) provide discovery without BSL. |
| Nomad (orchestration) | **compose-manual** (scripts) | BSL-1.1 competitive risk. Use PaaS + health-check scripts. |

### 4.2 RECOMMENDED Changes

| Tool | Action | Reason |
|------|--------|--------|
| Redis Sentinel | **Valkey Sentinel** | Drop-in replacement, BSD-3 licensed |
| Consul (KV store) | **etcd** (already needed for Patroni) | Consolidate on etcd, avoid Consul entirely |
| Any HashiCorp tool | Avoid unless negotiated | BSL-1.1 is toxic for competing SaaS products |

### 4.3 Safe to Keep (No Changes)

HAProxy, Keepalived, GlusterFS, DRBD, OpenZFS, Patroni, etcd, Step-CA, CoreDNS, Traefik, Valkey, Litestream, LiteFS -- all safe under config-generation model.

---

## 5. Service Discovery Without Consul

Consul is the most significant tool we lose. Alternatives:

### Option A: CoreDNS + etcd (Recommended)
- CoreDNS (Apache-2) reads service records from etcd (Apache-2)
- Health checks via external script that updates etcd entries
- Services register themselves via simple HTTP PUT to etcd
- CoreDNS serves DNS-SD records for service lookup
- **Pro**: Both are CNCF projects, Apache-2, battle-tested
- **Con**: No built-in health checking (need external script)

### Option B: DNS-SD with mDNS/Avahi
- Avahi (LGPL-2.1) for local service advertisement
- Works on LAN without central registry
- **Pro**: Zero infrastructure, works out of box
- **Con**: LAN only, no WAN support, no health checks

### Option C: Custom Health-Check + Static Config
- HAProxy already does health checks on backends
- Traefik can do service discovery via Docker labels
- For cross-node: maintain a simple service registry in etcd (which Patroni already needs)
- **Pro**: No new components, leverages existing infra
- **Con**: Less dynamic, requires more CUE schema work

### Recommendation

**Option A (CoreDNS + etcd)** for ha-homelab. etcd is already required for Patroni, so adding CoreDNS is one additional component with zero license risk.

---

## 6. Orchestration Without Nomad

Without Nomad, the ha-homelab uses the "compose-manual" approach:

1. Docker Compose per node (as in modern-homelab)
2. Keepalived + health check scripts for automatic failover
3. Rolling update scripts (bash/Python) that update nodes sequentially
4. CUE generates placement configs (which services on which nodes)
5. PaaS (Coolify/Dokploy) handles deployment coordination

This is less automated than Nomad but has zero license risk and builds directly on modern-homelab patterns. The CUE schema should still define an `orchestration` field for future extensibility if a commercial Nomad license is negotiated.

---

## 7. The "Config Generation vs Distribution" Legal Argument

This is the foundation of kombify's license safety. The argument:

1. **kombify does not distribute software**. It generates configuration files (Docker Compose YAML, CUE schemas, shell scripts) that *reference* software by name and version.

2. **The customer downloads software themselves**. When a customer runs `docker compose up`, Docker pulls images from Docker Hub, GitHub Container Registry, etc. -- not from kombify.

3. **kombify's configs are original works**. The YAML/CUE files are kombify's intellectual property. They contain references to third-party software but do not contain any copyrighted code from those projects.

4. **Analogy**: A cookbook that references "Heinz Ketchup" in a recipe is not distributing ketchup. A Linux tutorial that says "apt install nginx" is not distributing nginx.

**This argument is strong for GPL, CDDL, and MIT/Apache/BSD licenses**. It is **weaker for BSL-1.1** because HashiCorp's Additional Use Grant restricts "offering the Licensed Work to third parties on an embedded basis" -- and a SaaS product that generates deployment configs for Consul could be argued to "offer Consul to third parties on an embedded basis."

**For maximum legal safety**: Do not include BSL-1.1 or RSALv2 tools in default StackKit configurations. Offer them only as clearly documented opt-in add-ons with license warnings.

---

## 8. Recommendations Summary

### Immediate Actions
1. **Default to Valkey over Redis** in all StackKits (BSD-3, zero risk)
2. **Replace Consul with CoreDNS + etcd** in ha-homelab
3. **Drop Nomad as default orchestration** -- use compose-manual
4. **Never bundle/mirror container images** -- always reference upstream

### Future Considerations
1. **Contact HashiCorp** (licensing@hashicorp.com) if Consul/Nomad are desired features -- negotiate commercial terms
2. **Monitor Redis tri-license** -- AGPL-3 option is usable but Valkey is cleaner
3. **Track BSL change dates** -- HashiCorp BSL versions convert to MPL-2.0 after 4 years (rolling per release). Consul 1.16 (Aug 2023) becomes MPL-2.0 in Aug 2027.
4. **Legal review** -- This analysis is engineering judgment, not legal advice. Before production launch, have a lawyer review the license compliance strategy.

### License-Safe HA Stack

```
Entry Layer:     HAProxy (GPL-2) + Keepalived (GPL-2)
Proxy:           Traefik (MIT)
Discovery:       CoreDNS (Apache-2) + etcd (Apache-2)
Database:        Patroni (MIT) + PostgreSQL (PostgreSQL License) + etcd (Apache-2)
Cache:           Valkey Sentinel (BSD-3)
Storage:         GlusterFS (GPL-3) or DRBD (GPL-2) + OpenZFS (CDDL)
Certificates:    Step-CA (Apache-2)
SQLite HA:       Litestream (Apache-2) / LiteFS (Apache-2)
Orchestration:   Docker Compose + health-check scripts (kombify's own code)
```

Every component in this stack is either permissive or GPL (with SaaS loophole protection). Zero BSL, zero RSALv2, zero SSPL.

---

## Sources

- FOSSA: Business Source License explained -- https://fossa.com/blog/business-source-license-requirements-provisions-history/
- HashiCorp License FAQ -- https://www.hashicorp.com/en/license-faq
- Kyle Mitchell: HashiCorp's New Licensing -- https://writing.kemitchell.com/2023/08/18/HashiCorp-BSL.html
- Redis License Page -- https://redis.io/legal/licenses/
- Vaultinum: AGPL Compliance Guide -- https://vaultinum.com/blog/essential-guide-to-agpl-compliance-for-tech-companies
- HashiCorp BSL Additional Use Grant (exact text): "You may make production use of the Licensed Work, provided such use does not include offering the Licensed Work to third parties on a hosted or embedded basis which is competitive with HashiCorp's products."
- Redis RSALv2 (exact restriction): "You may not commercialize the software or provide it to others as a managed service"
- SSPLv1 (exact requirement): Must release entire service stack source code if providing as a service

# StackKits Roadmap & Kombify Integration Plan

> **Last Updated:** 2026-01-30
> **Status:** Active Development
> **Current Version:** v1.0.0-beta

---

## Executive Summary

This document outlines the development roadmap for StackKits and its integration with the Kombify ecosystem. The plan is organized into 6 sprints over approximately 12 weeks, taking StackKits from current state to production-ready with full ecosystem integration.

### Current State Assessment

| Component | Status | Blockers |
|-----------|--------|----------|
| base-homelab | 85% Complete | CUE validation passes, needs E2E testing |
| dev-homelab | 60% Complete | Docker platform import issue, syntax fixes needed |
| kombify-admin | 30% Complete | Prisma schema ready, needs API layer |
| Kong API Gateway | Not Started | Depends on kombify-admin API |
| kombifyStack CLI | Not Started | Depends on Kong API |
| kombifySim | Not Started | Depends on StackKits production-ready |

---

## Sprint Overview

```
Sprint 1 (Weeks 1-2):   StackKits Production Ready
Sprint 2 (Weeks 3-4):   kombify-admin API & Database Migration
Sprint 3 (Weeks 5-6):   Kong API Gateway Integration
Sprint 4 (Weeks 7-8):   kombifyStack CLI & Unification Engine
Sprint 5 (Weeks 9-10):  kombifySim Integration
Sprint 6 (Weeks 11-12): Production Hardening & Documentation
```

---

## Sprint 1: StackKits Production Ready

**Goal**: base-homelab fully tested and production-ready, dev-homelab fixed

### Week 1: base-homelab Completion

#### 1.1 End-to-End Testing
- [ ] Create test environment (local VM or Docker)
- [ ] Test Terraform deployment flow
- [ ] Validate Layer 1 identity (LLDAP + Step-CA)
- [ ] Validate Layer 2 platform (Traefik + Dokploy)
- [ ] Validate Layer 3 applications via Dokploy
- [ ] Test all variants: default, coolify, beszel, minimal, secure

#### 1.2 CUE Validation Pipeline
- [ ] Run `cue vet ./base/... ./base-homelab/... ./platforms/...` in CI
- [ ] Add pre-commit hooks for CUE validation
- [ ] Create validation test suite

#### 1.3 Documentation
- [ ] Update README with quick-start guide
- [ ] Create variant selection guide
- [ ] Document Layer 1 identity setup (LLDAP admin, Step-CA enrollment)

### Week 2: dev-homelab Fixes

#### 2.1 Fix Docker Platform Import Issue
```
Root Cause Analysis Required:
- Import "github.com/kombihq/stackkits/platforms/docker" reports "not used"
- But lines 269 and 283 use docker.#DockerConfig and docker.#TraefikConfig
- Possible: CUE module resolution issue or struct field rejection
```

**Investigation Steps**:
1. Check if `docker:` and `traefik:` fields are rejected by `#BaseStackKit`
2. Verify CUE module.cue configuration
3. Test import in isolation
4. Consider restructuring to embed docker platform properly

#### 2.2 Fix Remaining Syntax Issues
- [ ] Fix `#Services` reference resolution
- [ ] Ensure all packages use consistent naming (`devhomelab` vs `dev_homelab`)
- [ ] Update test files with correct import syntax

#### 2.3 Integration Testing
- [ ] Test dev-homelab deployment
- [ ] Validate TinyAuth integration
- [ ] Test Dokploy PAAS workflows

### Sprint 1 Deliverables
| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| base-homelab v3.0.0 | All CUE validations pass, E2E test successful |
| dev-homelab v2.1.0 | All CUE validations pass, Docker import fixed |
| CI Pipeline | GitHub Actions runs CUE validation on every PR |
| Documentation | Quick-start guide, variant guide published |

---

## Sprint 2: kombify-admin API & Database Migration

**Goal**: Production PostgreSQL with REST API through kombify-admin

### Week 3: Database Migration

#### 3.1 Production Database Setup
```yaml
# Target: Managed PostgreSQL or self-hosted with HA
Options:
  - Supabase (managed, free tier available)
  - Neon (serverless PostgreSQL)
  - Self-hosted PostgreSQL with Patroni
  - Docker Compose for development
```

- [ ] Choose production database provider
- [ ] Create production database instance
- [ ] Configure connection pooling (PgBouncer or Prisma Data Proxy)
- [ ] Set up database backups

#### 3.2 Prisma Migration
```bash
# Migration workflow
cd kombify-admin
npm install
npx prisma migrate dev --name init
npx prisma db seed
```

- [ ] Create migration scripts
- [ ] Test migration on staging database
- [ ] Create rollback procedures
- [ ] Document database schema

#### 3.3 Environment Configuration
```env
# Production environment variables
DATABASE_URL=postgresql://user:pass@host:5432/kombify_admin?sslmode=require
DIRECT_URL=postgresql://user:pass@host:5432/kombify_admin?sslmode=require
```

- [ ] Set up environment variable management (Doppler, Vault, or .env)
- [ ] Configure connection strings for different environments
- [ ] Implement secrets rotation

### Week 4: REST API Development

#### 4.1 API Framework Selection
```
Recommended: Hono.js + Prisma
- Lightweight, fast, TypeScript-native
- Works on Edge, Node.js, Bun
- OpenAPI support via @hono/zod-openapi
```

- [ ] Initialize Hono.js API project
- [ ] Configure Prisma client
- [ ] Set up OpenAPI documentation

#### 4.2 Core API Endpoints

```typescript
// kombify-admin/src/routes/index.ts

// StackKits CRUD
GET    /api/v1/stackkits
GET    /api/v1/stackkits/:id
POST   /api/v1/stackkits
PUT    /api/v1/stackkits/:id
DELETE /api/v1/stackkits/:id

// Tools CRUD
GET    /api/v1/tools
GET    /api/v1/tools/:id
POST   /api/v1/tools
PUT    /api/v1/tools/:id

// Validation Rules
GET    /api/v1/validation-rules
GET    /api/v1/validation-rules/layer/:layer
POST   /api/v1/validation-rules

// Settings
GET    /api/v1/settings
GET    /api/v1/settings/layer/:layer
GET    /api/v1/settings/type/:type

// Patterns
GET    /api/v1/patterns
GET    /api/v1/patterns/:name

// Decisions (ADRs)
GET    /api/v1/decisions
POST   /api/v1/decisions

// CUE Generation
POST   /api/v1/generate/cue
GET    /api/v1/generate/cue/status/:jobId
```

- [ ] Implement StackKit endpoints
- [ ] Implement Tool endpoints
- [ ] Implement ValidationRule endpoints
- [ ] Implement Settings endpoints
- [ ] Implement Pattern endpoints
- [ ] Implement Decision endpoints
- [ ] Implement CUE generation endpoint

#### 4.3 Authentication & Authorization
```typescript
// JWT-based auth with role-based access
Roles:
  - admin: Full CRUD access
  - editor: Create/Update StackKits, Tools
  - viewer: Read-only access
  - generator: CUE generation only (for CI/CD)
```

- [ ] Implement JWT authentication
- [ ] Implement role-based authorization
- [ ] Create API key management for CI/CD

### Sprint 2 Deliverables
| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| Production Database | PostgreSQL running with seed data |
| kombify-admin API v1.0 | All endpoints functional, OpenAPI docs |
| Authentication | JWT auth with role-based access |
| API Documentation | OpenAPI 3.0 spec, Swagger UI |

---

## Sprint 3: Kong API Gateway Integration

**Goal**: Kong manages API routing, rate limiting, and authentication

### Week 5: Kong Setup

#### 5.1 Kong Deployment
```yaml
# Kong deployment options
Development:
  - Docker Compose with Kong DB-less mode
  - Kong Ingress Controller in local K3s

Production:
  - Kong Konnect (managed)
  - Self-hosted Kong with PostgreSQL
  - Kong Ingress Controller in Kubernetes
```

- [ ] Deploy Kong Gateway
- [ ] Configure admin API access
- [ ] Set up Kong Manager UI

#### 5.2 Service & Route Configuration
```yaml
# Kong declarative config (kong.yml)
_format_version: "3.0"

services:
  - name: kombify-admin
    url: http://kombify-admin:3000
    routes:
      - name: admin-api
        paths:
          - /api/v1/admin
        strip_path: true
    plugins:
      - name: jwt
      - name: rate-limiting
        config:
          minute: 100
          policy: local

  - name: kombify-stack
    url: http://kombify-stack:3001
    routes:
      - name: stack-api
        paths:
          - /api/v1/stack
        strip_path: true

  - name: public-api
    url: http://kombify-admin:3000
    routes:
      - name: public-stackkits
        paths:
          - /api/v1/public/stackkits
        methods:
          - GET
    plugins:
      - name: rate-limiting
        config:
          minute: 30
          policy: local
```

- [ ] Define services for each backend
- [ ] Configure routes
- [ ] Set up path-based routing

#### 5.3 Plugins & Security
```yaml
# Kong plugins
Authentication:
  - JWT (for API clients)
  - Key-Auth (for CLI tools)
  - OAuth2 (for web apps)

Security:
  - Rate Limiting (per consumer, per route)
  - IP Restriction (for admin endpoints)
  - CORS (for web clients)
  - Request Size Limiting

Observability:
  - Prometheus (metrics)
  - HTTP Log (request logging)
  - Zipkin (distributed tracing)
```

- [ ] Configure JWT plugin
- [ ] Configure Key-Auth for CLI
- [ ] Set up rate limiting
- [ ] Enable CORS for web clients
- [ ] Configure logging and metrics

### Week 6: CLI Authentication Integration

#### 6.1 API Key Management
```bash
# CLI authentication flow
kombify login
> Enter your API key: sk_live_xxxxx
> Authenticated as: user@example.com
> Organization: my-homelab

# API key stored in ~/.kombify/credentials
```

- [ ] Create API key generation endpoint
- [ ] Implement CLI credential storage
- [ ] Configure Kong Key-Auth consumer

#### 6.2 Public API for Self-Hosters
```yaml
# Public endpoints (no auth required, rate limited)
GET /api/v1/public/stackkits          # List available StackKits
GET /api/v1/public/stackkits/:name    # Get StackKit details
GET /api/v1/public/tools              # List tools catalog
GET /api/v1/public/patterns           # List patterns

# Download endpoints
GET /api/v1/public/download/:stackkit # Download StackKit package
```

- [ ] Create public API routes
- [ ] Configure rate limiting for public endpoints
- [ ] Implement StackKit package download

### Sprint 3 Deliverables
| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| Kong Gateway | Running with all services configured |
| JWT Authentication | Working for API clients |
| Key-Auth for CLI | CLI can authenticate via API key |
| Public API | Rate-limited public endpoints for self-hosters |
| API Documentation | Updated with Kong-proxied URLs |

---

## Sprint 4: kombifyStack CLI & Unification Engine

**Goal**: CLI tool for deploying StackKits with unified configuration

### Week 7: CLI Development

#### 7.1 CLI Framework
```typescript
// Recommended: Commander.js + Inquirer.js + Chalk
// Or: Oclif for enterprise-grade CLI

// CLI structure
kombify
├── login           # Authenticate with API
├── logout          # Clear credentials
├── stackkit
│   ├── list        # List available StackKits
│   ├── show        # Show StackKit details
│   ├── init        # Initialize new deployment
│   ├── validate    # Validate configuration
│   └── deploy      # Deploy StackKit
├── config
│   ├── get         # Get config value
│   ├── set         # Set config value
│   └── list        # List all config
└── sim
    ├── create      # Create simulation VM
    ├── list        # List VMs
    └── destroy     # Destroy VM
```

- [ ] Initialize CLI project with Commander.js
- [ ] Implement authentication commands
- [ ] Implement stackkit commands
- [ ] Implement config commands
- [ ] Add interactive prompts with Inquirer.js

#### 7.2 Core CLI Commands
```bash
# Initialize a new deployment
kombify stackkit init base-homelab
> Select variant: [default, coolify, beszel, minimal, secure]
> Enter domain (or leave empty for local):
> SSH user: ubuntu
> SSH host: 192.168.1.100
> Created: ./kombify.yaml

# Validate configuration
kombify stackkit validate
> Validating kombify.yaml...
> ✓ Layer 1: Identity configuration valid
> ✓ Layer 2: Platform configuration valid
> ✓ Layer 3: Application configuration valid
> Validation passed!

# Deploy
kombify stackkit deploy
> Deploying base-homelab (variant: default)...
> [1/5] Provisioning infrastructure...
> [2/5] Configuring Layer 1 (Identity)...
> [3/5] Configuring Layer 2 (Platform)...
> [4/5] Deploying Layer 3 (Applications)...
> [5/5] Running health checks...
> ✓ Deployment complete!
```

- [ ] Implement `kombify stackkit init`
- [ ] Implement `kombify stackkit validate`
- [ ] Implement `kombify stackkit deploy`
- [ ] Add progress indicators and logging

### Week 8: Unification Engine

#### 8.1 Unification Process
```
Unification = User Spec + StackKit Schema → Unified Config

User Spec (kombify.yaml):
  - Target nodes (IPs, credentials)
  - Variant selection
  - Custom overrides

StackKit Schema (CUE):
  - Layer definitions
  - Service configurations
  - Validation rules

Unified Config:
  - Terraform variables
  - Docker Compose files
  - Deployment manifests
```

- [ ] Define kombify.yaml schema
- [ ] Implement CUE unification
- [ ] Generate Terraform variables
- [ ] Generate Docker Compose files

#### 8.2 Deployment Orchestration
```
Deployment Flow:
1. Fetch StackKit from API (or local cache)
2. Merge user spec with StackKit defaults
3. Validate unified config against CUE schemas
4. Generate deployment artifacts
5. Execute Terraform (Layer 1-2)
6. Configure PAAS (Dokploy/Coolify)
7. Deploy applications via PAAS API
8. Run health checks
9. Output access URLs
```

- [ ] Implement artifact generation
- [ ] Integrate Terraform execution
- [ ] Integrate PAAS API calls (Dokploy)
- [ ] Implement health checks
- [ ] Generate output report

### Sprint 4 Deliverables
| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| kombifyStack CLI v1.0 | All commands functional |
| Unification Engine | CUE unification working |
| Terraform Integration | Layer 1-2 deployment via Terraform |
| PAAS Integration | Layer 3 deployment via Dokploy API |
| End-to-End Deployment | Full deployment from CLI to running stack |

---

## Sprint 5: kombifySim Integration

**Goal**: Deploy StackKits to simulation VMs for testing

### Week 9: kombifySim Architecture

#### 9.1 VM Provider Integration
```yaml
# Supported VM providers
Local:
  - VirtualBox (via Vagrant)
  - Docker (for lightweight simulation)
  - Lima (macOS)
  - WSL2 (Windows)

Cloud:
  - Hetzner Cloud
  - DigitalOcean
  - AWS EC2
  - GCP Compute
```

- [ ] Define VM provider interface
- [ ] Implement VirtualBox/Vagrant provider
- [ ] Implement Docker provider (for CI)
- [ ] Implement Hetzner provider

#### 9.2 Simulation Workflow
```bash
# Create simulation environment
kombify sim create --provider virtualbox --os ubuntu-24
> Creating VM: kombify-sim-abc123
> OS: Ubuntu 24.04 LTS
> Resources: 4 CPU, 8GB RAM, 50GB disk
> IP: 192.168.56.101
> SSH: ssh ubuntu@192.168.56.101

# Deploy StackKit to simulation
kombify sim deploy base-homelab --vm kombify-sim-abc123
> Deploying to simulation VM...
> [Using existing kombify.yaml with VM overrides]
> ...deployment output...

# Access simulation
kombify sim ssh kombify-sim-abc123
> Connecting to kombify-sim-abc123...

# Destroy simulation
kombify sim destroy kombify-sim-abc123
> Destroying VM: kombify-sim-abc123
> ✓ VM destroyed
```

- [ ] Implement `kombify sim create`
- [ ] Implement `kombify sim deploy`
- [ ] Implement `kombify sim ssh`
- [ ] Implement `kombify sim destroy`
- [ ] Implement `kombify sim list`

### Week 10: Snapshot & Testing

#### 10.1 Snapshot Management
```bash
# Take snapshot after successful deployment
kombify sim snapshot create kombify-sim-abc123 --name "post-deploy"
> Creating snapshot: post-deploy
> ✓ Snapshot created

# Restore to snapshot
kombify sim snapshot restore kombify-sim-abc123 --name "post-deploy"
> Restoring snapshot: post-deploy
> ✓ Snapshot restored

# List snapshots
kombify sim snapshot list kombify-sim-abc123
> NAME         CREATED              SIZE
> post-deploy  2026-01-30 10:00:00  2.5GB
> clean        2026-01-30 09:00:00  1.2GB
```

- [ ] Implement snapshot creation
- [ ] Implement snapshot restoration
- [ ] Implement snapshot listing
- [ ] Add snapshot to deployment workflow

#### 10.2 Automated Testing
```yaml
# .github/workflows/stackkit-e2e.yml
name: StackKit E2E Tests

on:
  push:
    paths:
      - 'base-homelab/**'
      - 'dev-homelab/**'

jobs:
  e2e-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup kombify CLI
        run: npm install -g @kombify/cli

      - name: Create simulation VM
        run: kombify sim create --provider docker --os ubuntu-24

      - name: Deploy StackKit
        run: kombify sim deploy base-homelab --variant default

      - name: Run health checks
        run: kombify stackkit health-check

      - name: Cleanup
        if: always()
        run: kombify sim destroy --all
```

- [ ] Create E2E test workflow
- [ ] Implement health check command
- [ ] Add test reporting
- [ ] Integrate with PR checks

### Sprint 5 Deliverables
| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| kombifySim CLI | All simulation commands working |
| VirtualBox Provider | Local VM creation/destruction |
| Docker Provider | Container-based simulation for CI |
| Snapshot Management | Create/restore/list snapshots |
| E2E Test Pipeline | Automated testing in GitHub Actions |

---

## Sprint 6: Production Hardening & Documentation

**Goal**: Production-ready release with comprehensive documentation

### Week 11: Security & Hardening

#### 11.1 Security Audit
- [ ] Review all API endpoints for auth/authz
- [ ] Audit database access patterns
- [ ] Review secrets management
- [ ] Penetration testing on Kong gateway
- [ ] Validate TLS everywhere

#### 11.2 Production Configuration
```yaml
# Production checklist
Database:
  - [ ] Connection pooling enabled
  - [ ] Backups configured (daily)
  - [ ] Read replicas (if needed)
  - [ ] Monitoring alerts

Kong Gateway:
  - [ ] Rate limiting tuned
  - [ ] DDoS protection
  - [ ] SSL certificates (Let's Encrypt)
  - [ ] Health checks configured

API:
  - [ ] Request validation
  - [ ] Error handling
  - [ ] Logging structured (JSON)
  - [ ] Metrics exported (Prometheus)

CLI:
  - [ ] Credential encryption
  - [ ] Update notifications
  - [ ] Offline fallback
```

- [ ] Configure production database
- [ ] Harden Kong gateway
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure alerting

### Week 12: Documentation & Release

#### 12.1 Documentation
```
docs/
├── getting-started/
│   ├── quick-start.md
│   ├── installation.md
│   └── first-deployment.md
├── stackkits/
│   ├── base-homelab.md
│   ├── dev-homelab.md
│   └── creating-stackkits.md
├── api/
│   ├── authentication.md
│   ├── endpoints.md
│   └── openapi.yaml
├── cli/
│   ├── commands.md
│   ├── configuration.md
│   └── troubleshooting.md
└── architecture/
    ├── overview.md
    ├── layers.md
    └── unification.md
```

- [ ] Write getting-started guides
- [ ] Document all StackKits
- [ ] Generate API documentation
- [ ] Write CLI documentation
- [ ] Create architecture diagrams

#### 12.2 Release Process
```bash
# Version tagging
v1.0.0 - Initial production release

Components:
- stackkits v3.0.0 (base-homelab, dev-homelab)
- kombify-admin v1.0.0 (API)
- kombify-cli v1.0.0 (CLI)
- kombify-sim v1.0.0 (Simulation)
```

- [ ] Create release branches
- [ ] Tag versions
- [ ] Publish npm packages
- [ ] Create GitHub releases
- [ ] Announce release

### Sprint 6 Deliverables
| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| Security Audit | All critical issues resolved |
| Production Config | All components production-ready |
| Documentation | Complete docs for all components |
| v1.0.0 Release | All packages published |

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Self-Hosters / Users                         │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           kombify CLI                                │
│                     (kombify stackkit deploy)                        │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
┌──────────────────────────────────┐    ┌──────────────────────────────┐
│        Kong API Gateway           │    │         kombifySim           │
│     (api.kombify.io:443)         │    │    (Local/Cloud VMs)         │
│                                  │    │                              │
│  ┌─────────────────────────────┐ │    │  ┌─────────────────────────┐ │
│  │ /api/v1/admin/*             │ │    │  │ VirtualBox Provider     │ │
│  │ /api/v1/stack/*             │ │    │  │ Docker Provider         │ │
│  │ /api/v1/public/*            │ │    │  │ Hetzner Provider        │ │
│  └─────────────────────────────┘ │    │  └─────────────────────────┘ │
└──────────────────────────────────┘    └──────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│  kombify-admin   │    │  kombify-stack   │
│  (Hono.js API)   │    │  (Orchestrator)  │
│                  │    │                  │
│  - StackKits     │    │  - Unification   │
│  - Tools         │    │  - Terraform     │
│  - Validation    │    │  - PAAS API      │
│  - Settings      │    │  - Health Check  │
└──────────────────┘    └──────────────────┘
        │                       │
        ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│   PostgreSQL     │    │   Target Hosts   │
│  (kombify_admin) │    │  (Homelabs)      │
│                  │    │                  │
│  - StackKits     │    │  L1: LLDAP,CA    │
│  - Tools         │    │  L2: Traefik,    │
│  - Rules         │    │      Dokploy     │
│  - Settings      │    │  L3: Apps        │
└──────────────────┘    └──────────────────┘
```

---

## Risk Register

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| CUE validation complexity | High | Medium | Invest in comprehensive test suite |
| Kong configuration errors | High | Low | Use declarative config, test in staging |
| Database migration failures | High | Low | Backup before migration, rollback plan |
| CLI cross-platform issues | Medium | Medium | Test on Windows, macOS, Linux |
| PAAS API changes (Dokploy) | Medium | Low | Abstract PAAS layer, version pin |
| VM provider API changes | Low | Low | Provider abstraction layer |

---

## Success Metrics

### Sprint 1
- [ ] `cue vet` passes for all StackKits
- [ ] E2E deployment succeeds for base-homelab
- [ ] All 5 variants tested

### Sprint 2
- [ ] API response time < 100ms (p95)
- [ ] Database migration completes without data loss
- [ ] OpenAPI spec validates

### Sprint 3
- [ ] Kong handles 1000 req/min without errors
- [ ] CLI authentication works on all platforms
- [ ] Public API serves StackKit downloads

### Sprint 4
- [ ] Full deployment completes in < 15 minutes
- [ ] Unification produces valid Terraform
- [ ] Health checks pass for all layers

### Sprint 5
- [ ] VM creation time < 5 minutes
- [ ] Snapshot restore < 2 minutes
- [ ] E2E tests run in CI

### Sprint 6
- [ ] Zero critical security issues
- [ ] Documentation coverage > 90%
- [ ] v1.0.0 released to npm

---

## Appendix A: Technical Specifications

### A.1 kombify.yaml Schema
```yaml
# kombify.yaml - User specification file
apiVersion: kombify.io/v1
kind: Deployment

metadata:
  name: my-homelab

spec:
  stackkit: base-homelab
  version: "3.0.0"
  variant: default

  nodes:
    - name: main
      role: main
      ssh:
        host: 192.168.1.100
        user: ubuntu
        privateKeyPath: ~/.ssh/id_ed25519
      resources:
        cpu: 4
        memory: 8
        disk: 100

  overrides:
    network:
      defaults:
        domain: homelab.local
    identity:
      lldap:
        domain:
          base: "dc=homelab,dc=local"
```

### A.2 API Authentication Flow
```
1. User creates account on kombify.io
2. User generates API key in dashboard
3. CLI stores API key in ~/.kombify/credentials
4. CLI sends API key in X-API-Key header
5. Kong validates key against consumer database
6. Request forwarded to backend with consumer context
```

### A.3 CUE Generation Pipeline
```
1. Admin updates database via UI/API
2. Database trigger or webhook fires
3. GitHub Action triggered
4. Action runs generate-cue.ts
5. Generated CUE files committed
6. PR created for review (optional)
7. Merge updates base/generated/
```

---

## Appendix B: Component Dependencies

```mermaid
graph TD
    A[StackKits CUE Schemas] --> B[kombify-admin API]
    B --> C[Kong API Gateway]
    C --> D[kombify CLI]
    D --> E[kombifySim]
    D --> F[Target Hosts]

    B --> G[PostgreSQL]
    D --> H[Terraform]
    D --> I[Dokploy API]

    E --> J[VirtualBox]
    E --> K[Docker]
    E --> L[Hetzner]
```

---

## Appendix C: Previous Roadmap (Archived)

The previous roadmap focused on single-stack development. Key completed items:

### ✅ Completed (from v1.0 plan)
- [x] CUE schema architecture (3-layer model)
- [x] CLI scaffold (`init`, `validate`, `plan`, `apply`, `destroy`, `status`)
- [x] base-homelab templates (simple mode)
- [x] CI/CD pipeline (GitHub Actions)
- [x] Documentation structure (TARGET_STATE, STATUS_QUO, ADRs)
- [x] PaaS strategy: Dokploy (no domain) / Coolify (with domain)
- [x] CUE → Terraform Bridge
- [x] Variant System (default, coolify, beszel, minimal, secure)
- [x] Documentation Alignment

### Deferred Items
- Terramate integration → Sprint 4 (Unification Engine)
- Network standards enforcement → Sprint 1 (E2E Testing)
- Release automation → Sprint 6 (Documentation & Release)

---

## Contributing

We welcome contributions! Priority areas:

1. **Sprint 1**: E2E testing for base-homelab
2. **Sprint 2**: API endpoint implementations
3. **Sprint 3**: Kong plugin configurations
4. **Sprint 4**: CLI command implementations
5. **Sprint 5**: VM provider implementations
6. **Sprint 6**: Documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

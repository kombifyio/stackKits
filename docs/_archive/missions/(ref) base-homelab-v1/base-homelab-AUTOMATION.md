# Base Homelab StackKit - Automation & Data Structures

> **Last Updated:** 2026-01-29  
> **Status:** Planning Document  
> **Purpose:** Define automation processes and data structures for StackKit management  
> **Scope:** Kombify Administration, PostgreSQL/Prisma backend, tool integration

---

## 1. Executive Summary

This document defines the requirements for:
1. **Automated StackKit management** - Create, update, remove StackKits programmatically
2. **Tool evaluation integration** - How new tools get added to StackKits
3. **Data structures** - PostgreSQL + Prisma schema for central administration
4. **Change propagation** - How updates flow through the system

---

## 2. Automation Requirements

### 2.1 StackKit Lifecycle Operations

| Operation | Trigger | Actions |
|-----------|---------|---------|
| **Create** | New StackKit defined | Generate CUE schemas, templates, docs |
| **Update** | Service version change | Update images, test, regenerate |
| **Extend** | Add new service | Add service definition, update variants |
| **Deprecate** | Service EOL | Mark deprecated, suggest alternatives |
| **Remove** | StackKit retired | Archive, remove from registry |

### 2.2 Automated Tasks

| Task | Frequency | Automation Level |
|------|-----------|------------------|
| Version check for images | Daily | Full auto |
| Security scan | Daily | Full auto |
| CUE validation | On change | Full auto |
| Template regeneration | On change | Semi-auto (review) |
| Documentation update | On change | Semi-auto (review) |
| Migration script | On breaking change | Manual + assist |

---

## 3. Tool Evaluation Integration

### 3.1 New Tool Discovery Flow

```
┌────────────────────────────────────────────────────────────────┐
│                    TOOL EVALUATION PIPELINE                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │  Discovery  │───▶│  Evaluation │───▶│  Decision   │        │
│  │             │    │             │    │             │        │
│  │ • GitHub    │    │ • Fit check │    │ • Approve   │        │
│  │ • Awesome   │    │ • Test      │    │ • Reject    │        │
│  │ • Community │    │ • Document  │    │ • Defer     │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                  │             │
│                                                  ▼             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │  Registry   │◀───│ Integration │◀───│  Approval   │        │
│  │             │    │             │    │             │        │
│  │ • Catalog   │    │ • Schema    │    │ • Review    │        │
│  │ • Metadata  │    │ • Template  │    │ • Testing   │        │
│  │ • Versions  │    │ • Docs      │    │ • Sign-off  │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### 3.2 Integration Checklist

When a new tool is discovered and approved:

| Step | Action | Automated |
|------|--------|-----------|
| 1 | Create tool entry in database | ✅ Yes |
| 2 | Fetch Docker image metadata | ✅ Yes |
| 3 | Generate CUE service definition | 🟡 Template + manual |
| 4 | Create Traefik labels | ✅ Yes |
| 5 | Add to variant(s) | 🟡 Suggest + approve |
| 6 | Update OpenTofu templates | 🟡 Template + manual |
| 7 | Write documentation section | 🔴 Manual |
| 8 | Create test cases | 🟡 Template + manual |
| 9 | Update version registry | ✅ Yes |
| 10 | Trigger CI/CD validation | ✅ Yes |

### 3.3 Tool Evaluation Criteria

| Criterion | Weight | Scoring |
|-----------|--------|---------|
| **Maintenance** | 25% | Active repo, recent commits |
| **Community** | 20% | Stars, forks, contributors |
| **Documentation** | 15% | Quality of docs |
| **Security** | 20% | CVE history, update frequency |
| **Fit** | 20% | Matches homelab use case |

---

## 4. Data Structures (PostgreSQL + Prisma)

### 4.1 Entity Relationship Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    StackKit     │     │     Variant     │     │     Service     │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id              │◀───┐│ id              │     │ id              │
│ name            │    ││ name            │     │ name            │
│ displayName     │    ││ stackKitId (FK) │────▶│ displayName     │
│ version         │    │├─────────────────┤     │ category        │
│ description     │    ││ serviceConfigs[]│────▶│ type            │
│ status          │    │└─────────────────┘     │ image           │
│ createdAt       │    │                        │ tag             │
│ updatedAt       │    │                        │ ports[]         │
└─────────────────┘    │                        │ volumes[]       │
         │             │                        └─────────────────┘
         │             │                                 │
         │             │     ┌─────────────────┐         │
         │             │     │ VariantService  │         │
         │             └────▶├─────────────────┤◀────────┘
         │                   │ variantId (FK)  │
         │                   │ serviceId (FK)  │
         │                   │ enabled         │
         │                   │ config (JSON)   │
         │                   └─────────────────┘
         │
         │     ┌─────────────────┐     ┌─────────────────┐
         │     │   ImageVersion  │     │   ToolEval      │
         │     ├─────────────────┤     ├─────────────────┤
         └────▶│ serviceId (FK)  │     │ id              │
               │ tag             │     │ serviceId (FK)  │
               │ digest          │     │ status          │
               │ releaseDate     │     │ score           │
               │ isLatest        │     │ evaluatedAt     │
               │ isRecommended   │     │ notes           │
               └─────────────────┘     └─────────────────┘
```

### 4.2 Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================================================
// STACKKIT ENTITIES
// ============================================================================

model StackKit {
  id           String    @id @default(cuid())
  name         String    @unique // e.g., "base-homelab"
  displayName  String
  version      String    @default("1.0.0")
  description  String
  longDesc     String?   @db.Text
  status       StackKitStatus @default(DRAFT)
  license      String    @default("MIT")
  repository   String?
  author       String?
  
  // Requirements
  minCpu       Int       @default(2)
  minMemoryGB  Int       @default(4)
  minDiskGB    Int       @default(50)
  supportedOS  String[]  @default(["ubuntu-24", "ubuntu-22", "debian-12"])
  
  // Relations
  variants     Variant[]
  deployments  Deployment[]
  
  // Metadata
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  
  @@index([name])
  @@index([status])
}

enum StackKitStatus {
  DRAFT
  BETA
  STABLE
  DEPRECATED
  ARCHIVED
}

model Variant {
  id           String    @id @default(cuid())
  name         String    // e.g., "default", "coolify"
  displayName  String
  description  String
  isDefault    Boolean   @default(false)
  
  // Parent StackKit
  stackKitId   String
  stackKit     StackKit  @relation(fields: [stackKitId], references: [id])
  
  // Services in this variant
  services     VariantService[]
  
  // Selection rules (JSON)
  selectionRules Json?
  
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  
  @@unique([stackKitId, name])
  @@index([stackKitId])
}

// ============================================================================
// SERVICE ENTITIES
// ============================================================================

model Service {
  id           String    @id @default(cuid())
  name         String    @unique // e.g., "traefik", "dokploy"
  displayName  String
  description  String
  category     ServiceCategory
  type         String    // e.g., "reverse-proxy", "paas"
  
  // Docker image
  image        String    // e.g., "traefik"
  defaultTag   String    @default("latest")
  
  // Configuration
  ports        Json      // Array of port mappings
  volumes      Json      // Array of volume mounts
  environment  Json?     // Default env vars
  labels       Json?     // Default labels
  
  // Health check
  healthCheck  Json?
  
  // Resources
  minMemory    String?   // e.g., "256m"
  maxMemory    String?   // e.g., "1g"
  cpuLimit     Float?
  
  // Relations
  variants     VariantService[]
  imageVersions ImageVersion[]
  dependencies  ServiceDependency[] @relation("DependentService")
  dependedBy    ServiceDependency[] @relation("RequiredService")
  evaluations   ToolEvaluation[]
  
  // Metadata
  homepage     String?
  docs         String?
  status       ServiceStatus @default(ACTIVE)
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  
  @@index([category])
  @@index([status])
}

enum ServiceCategory {
  CORE
  PLATFORM
  MONITORING
  MANAGEMENT
  DATABASE
  STORAGE
  NETWORKING
  SECURITY
  MEDIA
  PRODUCTIVITY
  DEVTOOLS
  OTHER
}

enum ServiceStatus {
  EVALUATING
  ACTIVE
  DEPRECATED
  REMOVED
}

model VariantService {
  id         String   @id @default(cuid())
  
  variantId  String
  variant    Variant  @relation(fields: [variantId], references: [id])
  
  serviceId  String
  service    Service  @relation(fields: [serviceId], references: [id])
  
  enabled    Boolean  @default(true)
  required   Boolean  @default(false)
  
  // Override configuration (merged with service defaults)
  configOverride Json?
  
  // Display order in UI
  order      Int      @default(0)
  
  @@unique([variantId, serviceId])
  @@index([variantId])
  @@index([serviceId])
}

model ServiceDependency {
  id              String  @id @default(cuid())
  
  dependentId     String
  dependent       Service @relation("DependentService", fields: [dependentId], references: [id])
  
  requiredId      String
  required        Service @relation("RequiredService", fields: [requiredId], references: [id])
  
  // Dependency type
  type            DependencyType @default(REQUIRES)
  
  @@unique([dependentId, requiredId])
}

enum DependencyType {
  REQUIRES      // Hard dependency
  RECOMMENDS    // Soft dependency
  CONFLICTS     // Cannot coexist
}

// ============================================================================
// VERSION TRACKING
// ============================================================================

model ImageVersion {
  id           String   @id @default(cuid())
  
  serviceId    String
  service      Service  @relation(fields: [serviceId], references: [id])
  
  tag          String
  digest       String?  // SHA256 digest
  releaseDate  DateTime?
  
  isLatest     Boolean  @default(false)
  isRecommended Boolean @default(false)
  
  // Security info
  vulnerabilities Json?  // CVE scan results
  lastScanned  DateTime?
  
  createdAt    DateTime @default(now())
  
  @@unique([serviceId, tag])
  @@index([serviceId])
  @@index([isRecommended])
}

// ============================================================================
// TOOL EVALUATION
// ============================================================================

model ToolEvaluation {
  id           String   @id @default(cuid())
  
  serviceId    String
  service      Service  @relation(fields: [serviceId], references: [id])
  
  status       EvalStatus @default(PENDING)
  
  // Scoring (0-100)
  maintenanceScore  Int?
  communityScore    Int?
  documentationScore Int?
  securityScore     Int?
  fitScore          Int?
  overallScore      Int?
  
  // Details
  notes        String?  @db.Text
  pros         String[] @default([])
  cons         String[] @default([])
  
  // Reviewer
  evaluatedBy  String?
  evaluatedAt  DateTime?
  
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  @@index([serviceId])
  @@index([status])
}

enum EvalStatus {
  PENDING
  IN_REVIEW
  APPROVED
  REJECTED
  DEFERRED
}

// ============================================================================
// DEPLOYMENTS (Tracking)
// ============================================================================

model Deployment {
  id           String   @id @default(cuid())
  
  stackKitId   String
  stackKit     StackKit @relation(fields: [stackKitId], references: [id])
  
  variantName  String
  modeName     String   @default("simple")
  
  // Configuration snapshot
  specSnapshot Json
  
  // Status
  status       DeploymentStatus @default(PENDING)
  
  // Tracking
  startedAt    DateTime?
  completedAt  DateTime?
  lastChecked  DateTime?
  
  // Errors
  errors       Json?
  
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  @@index([stackKitId])
  @@index([status])
}

enum DeploymentStatus {
  PENDING
  DEPLOYING
  RUNNING
  DEGRADED
  FAILED
  DESTROYED
}

// ============================================================================
// CHANGE TRACKING
// ============================================================================

model ChangeLog {
  id           String   @id @default(cuid())
  
  entityType   String   // "StackKit", "Service", "Variant"
  entityId     String
  
  changeType   ChangeType
  description  String
  
  // Before/After snapshots
  previousValue Json?
  newValue     Json?
  
  // Who made the change
  changedBy    String?
  
  createdAt    DateTime @default(now())
  
  @@index([entityType, entityId])
  @@index([createdAt])
}

enum ChangeType {
  CREATED
  UPDATED
  DEPRECATED
  REMOVED
  VERSION_BUMP
  CONFIG_CHANGE
}
```

### 4.3 Sample Data

```typescript
// Sample StackKit
const baseHomelabStackKit = {
  name: "base-homelab",
  displayName: "Base Homelab",
  version: "2.0.0",
  description: "Single-server homelab with Docker, PaaS, and monitoring",
  status: "STABLE",
  minCpu: 2,
  minMemoryGB: 4,
  minDiskGB: 50,
  supportedOS: ["ubuntu-24", "ubuntu-22", "debian-12"]
};

// Sample Service
const traefikService = {
  name: "traefik",
  displayName: "Traefik",
  description: "Modern reverse proxy with automatic HTTPS",
  category: "CORE",
  type: "reverse-proxy",
  image: "traefik",
  defaultTag: "v3.1",
  ports: [
    { host: 80, container: 80, protocol: "tcp" },
    { host: 443, container: 443, protocol: "tcp" },
    { host: 8080, container: 8080, protocol: "tcp" }
  ],
  volumes: [
    { source: "/var/run/docker.sock", target: "/var/run/docker.sock", type: "bind" },
    { source: "traefik-certs", target: "/certs", type: "volume" }
  ]
};

// Sample Variant
const defaultVariant = {
  name: "default",
  displayName: "Standard",
  description: "Dokploy PaaS with Uptime Kuma monitoring",
  isDefault: true,
  selectionRules: {
    when: "!domain || domain.endsWith('.local')"
  }
};
```

---

## 5. Automation API

### 5.1 StackKit Management API

```typescript
// Internal API for StackKit management

interface StackKitAPI {
  // CRUD
  create(data: CreateStackKitInput): Promise<StackKit>;
  update(id: string, data: UpdateStackKitInput): Promise<StackKit>;
  deprecate(id: string, reason: string): Promise<StackKit>;
  archive(id: string): Promise<StackKit>;
  
  // Variants
  addVariant(stackKitId: string, data: CreateVariantInput): Promise<Variant>;
  updateVariant(variantId: string, data: UpdateVariantInput): Promise<Variant>;
  
  // Services
  addService(variantId: string, serviceId: string, config?: Json): Promise<VariantService>;
  removeService(variantId: string, serviceId: string): Promise<void>;
  
  // Generation
  generateCUE(id: string): Promise<string>;
  generateTerraform(id: string, variantName: string): Promise<string>;
  generateDocs(id: string): Promise<string>;
  
  // Validation
  validate(id: string): Promise<ValidationResult>;
  
  // Publishing
  publish(id: string, channel: 'beta' | 'stable'): Promise<void>;
}
```

### 5.2 Service Management API

```typescript
interface ServiceAPI {
  // CRUD
  create(data: CreateServiceInput): Promise<Service>;
  update(id: string, data: UpdateServiceInput): Promise<Service>;
  deprecate(id: string, replacement?: string): Promise<Service>;
  
  // Versions
  addVersion(serviceId: string, data: ImageVersionInput): Promise<ImageVersion>;
  setRecommendedVersion(serviceId: string, tag: string): Promise<void>;
  
  // Evaluation
  startEvaluation(serviceId: string): Promise<ToolEvaluation>;
  submitEvaluation(evalId: string, data: EvalResultInput): Promise<ToolEvaluation>;
  
  // Dependencies
  addDependency(fromId: string, toId: string, type: DependencyType): Promise<void>;
  removeDependency(fromId: string, toId: string): Promise<void>;
  
  // Scanning
  scanVulnerabilities(serviceId: string): Promise<VulnerabilityReport>;
  checkForUpdates(serviceId: string): Promise<UpdateInfo[]>;
}
```

### 5.3 Change Propagation API

```typescript
interface ChangeAPI {
  // Track changes
  logChange(data: ChangeLogInput): Promise<ChangeLog>;
  
  // Propagate changes
  propagateServiceUpdate(serviceId: string): Promise<PropagationResult>;
  propagateVersionBump(serviceId: string, newTag: string): Promise<PropagationResult>;
  
  // Impact analysis
  analyzeImpact(changeData: ChangeData): Promise<ImpactAnalysis>;
  
  // Notifications
  notifyStakeholders(changeId: string): Promise<void>;
}

interface PropagationResult {
  affectedStackKits: string[];
  affectedVariants: string[];
  actionsRequired: PropagationAction[];
}

interface PropagationAction {
  type: 'REGENERATE_CUE' | 'REGENERATE_TF' | 'UPDATE_DOCS' | 'RUN_TESTS';
  target: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED';
}
```

---

## 6. Change Propagation Workflow

### 6.1 When Service Version Changes

```
┌─────────────────────────────────────────────────────────────────┐
│                    VERSION UPDATE WORKFLOW                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Detect new version (daily scan)                            │
│     │                                                           │
│     ▼                                                           │
│  2. Create ImageVersion record                                  │
│     │                                                           │
│     ▼                                                           │
│  3. Run security scan                                          │
│     │                                                           │
│     ├─ Vulnerabilities found? → Create alert, block update     │
│     │                                                           │
│     ▼                                                           │
│  4. Find affected StackKits/Variants                           │
│     │                                                           │
│     ▼                                                           │
│  5. For each affected:                                         │
│     │   a. Regenerate CUE service definition                   │
│     │   b. Regenerate OpenTofu templates                       │
│     │   c. Update documentation                                │
│     │   d. Create PR for review                                │
│     │                                                           │
│     ▼                                                           │
│  6. Run automated tests                                        │
│     │                                                           │
│     ├─ Tests fail? → Notify maintainer, block update           │
│     │                                                           │
│     ▼                                                           │
│  7. Mark version as recommended (if auto-update enabled)       │
│     │                                                           │
│     ▼                                                           │
│  8. Notify users (changelog, release notes)                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 When New Tool is Approved

```
┌─────────────────────────────────────────────────────────────────┐
│                    NEW TOOL INTEGRATION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. ToolEvaluation.status → APPROVED                           │
│     │                                                           │
│     ▼                                                           │
│  2. Create Service record                                      │
│     │                                                           │
│     ▼                                                           │
│  3. Fetch image metadata (ports, volumes, env)                 │
│     │                                                           │
│     ▼                                                           │
│  4. Generate CUE service definition                            │
│     │                                                           │
│     ├─ Review by maintainer                                    │
│     │                                                           │
│     ▼                                                           │
│  5. Determine variant placement                                │
│     │   a. New variant needed?                                 │
│     │   b. Add to existing variant?                            │
│     │   c. Replace existing service?                           │
│     │                                                           │
│     ▼                                                           │
│  6. Create VariantService records                              │
│     │                                                           │
│     ▼                                                           │
│  7. Regenerate affected templates                              │
│     │                                                           │
│     ▼                                                           │
│  8. Write documentation                                        │
│     │                                                           │
│     ▼                                                           │
│  9. Create test cases                                          │
│     │                                                           │
│     ▼                                                           │
│  10. Create PR, run CI, merge                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Code Generation

### 7.1 CUE Generation Template

```typescript
function generateCUEService(service: Service): string {
  return `
// #${toPascalCase(service.name)}Service - ${service.description}
#${toPascalCase(service.name)}Service: base.#ServiceDefinition & {
    name:        "${service.name}"
    displayName: "${service.displayName}"
    category:    "${service.category.toLowerCase()}"
    type:        "${service.type}"
    image:       "${service.image}"
    tag:         "${service.defaultTag}"
    description: "${service.description}"
    ${service.dependencies?.length ? `needs: [${service.dependencies.map(d => `"${d}"`).join(', ')}]` : ''}

    network: {
        ports: [
            ${service.ports.map(p => `{host: ${p.host}, container: ${p.container}, protocol: "${p.protocol}"}`).join(',\n            ')}
        ]
    }

    volumes: [
        ${service.volumes.map(v => `{source: "${v.source}", target: "${v.target}", type: "${v.type}"}`).join(',\n        ')}
    ]

    ${service.healthCheck ? `healthCheck: ${JSON.stringify(service.healthCheck, null, 4)}` : ''}

    restartPolicy: "unless-stopped"
}`;
}
```

### 7.2 OpenTofu Generation Template

```typescript
function generateTerraformResource(service: Service, variant: Variant): string {
  const enabled = variant.services.find(s => s.serviceId === service.id)?.enabled ?? false;
  
  return `
# ${service.displayName}
resource "docker_container" "${service.name}" {
  count = ${enabled} && var.variant == "${variant.name}" ? 1 : 0
  
  name  = "${service.name}"
  image = docker_image.${service.name}[0].image_id

  restart = "unless-stopped"

  ${service.ports.map(p => `
  ports {
    internal = ${p.container}
    external = var.access_mode == "ports" ? var.${service.name}_port : null
  }`).join('\n')}

  ${service.volumes.map(v => `
  volumes {
    host_path      = "${v.type === 'bind' ? v.source : ''}"
    container_path = "${v.target}"
    ${v.type === 'volume' ? `volume_name = docker_volume.${v.source.replace('-', '_')}[0].name` : ''}
  }`).join('\n')}

  networks_advanced {
    name = docker_network.kombi_net.name
  }

  ${service.labels ? `
  labels {
    ${Object.entries(service.labels).map(([k, v]) => `label = "${k}"\n    value = "${v}"`).join('\n    ')}
  }` : ''}
}`;
}
```

---

## 8. Best Practices & Tools

### 8.1 Recommended Tools

| Purpose | Tool | Notes |
|---------|------|-------|
| **Database** | PostgreSQL 16 | JSONB for flexible schemas |
| **ORM** | Prisma | Type-safe, migrations, studio |
| **Validation** | Zod | Runtime type validation |
| **Queue** | BullMQ + Redis | Background jobs |
| **CI/CD** | GitHub Actions | Native integration |
| **Container Scanning** | Trivy | OSS, comprehensive |
| **Image Registry** | GitHub GHCR | Free for public repos |

### 8.2 Best Practices

| Practice | Rationale |
|----------|-----------|
| **Immutable versions** | Never modify published versions |
| **Changelog per change** | Audit trail |
| **Automated testing** | Catch regressions |
| **Semantic versioning** | Clear upgrade expectations |
| **Deprecation notices** | Give users migration time |
| **Feature flags** | Roll out gradually |

### 8.3 Monitoring & Alerting

| Metric | Alert Threshold |
|--------|-----------------|
| Failed deployments | > 5% in 1h |
| Security vulnerabilities | Any critical/high |
| Image update lag | > 7 days behind latest |
| Test failures | Any in main branch |

---

## 9. Questions to Answer

### 9.1 Architecture Questions

1. **Centralized vs. Distributed:**
   - Should the registry be centralized (hosted by Kombify) or distributed (per-user)?
   - How do we handle offline scenarios?

2. **Version Pinning:**
   - Should StackKits pin to specific image digests or tags?
   - How do we balance stability vs. freshness?

3. **Custom Services:**
   - How do users add custom services without forking?
   - Should custom services be shareable?

### 9.2 Process Questions

1. **Approval Workflow:**
   - Who approves new services? Single maintainer or committee?
   - What's the SLA for evaluation?

2. **Breaking Changes:**
   - How do we handle breaking changes in services?
   - What migration tooling do we need?

3. **Community Contributions:**
   - How do external contributors add services?
   - What quality gates apply?

### 9.3 Technical Questions

1. **CUE Generation:**
   - Generate CUE from database or maintain manually?
   - How do we ensure CUE stays in sync?

2. **Testing Strategy:**
   - How do we test generated templates?
   - Full deployment tests or unit tests only?

3. **Rollback:**
   - If a generated template breaks, how do we rollback?
   - Do we keep historical versions?

---

## 10. Next Steps

### 10.1 Phase 1: Foundation (2 weeks)

- [ ] Create PostgreSQL database
- [ ] Set up Prisma schema
- [ ] Seed initial data (base-homelab, services)
- [ ] Create basic CRUD API

### 10.2 Phase 2: Automation (3 weeks)

- [ ] Image version scanner (daily cron)
- [ ] Security scanner integration
- [ ] CUE generation from database
- [ ] OpenTofu generation from database

### 10.3 Phase 3: Integration (2 weeks)

- [ ] Connect to CLI (`stackkit list` from registry)
- [ ] Connect to Kombify Unifier
- [ ] Admin UI for management
- [ ] Webhook for change notifications

### 10.4 Phase 4: Polish (2 weeks)

- [ ] Documentation
- [ ] Testing
- [ ] Performance optimization
- [ ] Production deployment

---

## Appendix: API Endpoints

```yaml
# OpenAPI spec outline

paths:
  # StackKits
  /api/stackkits:
    get:
      summary: List all StackKits
    post:
      summary: Create StackKit
  
  /api/stackkits/{id}:
    get:
      summary: Get StackKit by ID
    patch:
      summary: Update StackKit
    delete:
      summary: Archive StackKit
  
  /api/stackkits/{id}/variants:
    get:
      summary: List variants
    post:
      summary: Add variant
  
  # Services
  /api/services:
    get:
      summary: List all services
    post:
      summary: Create service
  
  /api/services/{id}:
    get:
      summary: Get service by ID
    patch:
      summary: Update service
  
  /api/services/{id}/versions:
    get:
      summary: List versions
    post:
      summary: Add version
  
  # Evaluations
  /api/evaluations:
    get:
      summary: List evaluations
    post:
      summary: Start evaluation
  
  /api/evaluations/{id}:
    patch:
      summary: Submit evaluation result
  
  # Generation
  /api/generate/cue/{stackKitId}:
    post:
      summary: Generate CUE files
  
  /api/generate/terraform/{stackKitId}:
    post:
      summary: Generate Terraform files
```

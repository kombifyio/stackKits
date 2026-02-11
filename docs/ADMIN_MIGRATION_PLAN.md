# kombify-admin Migration Plan: Consolidating Old Admin + Websearch-UI Patterns

**Date:** 2026-02-11  
**Status:** Planning  
**Author:** GitHub Copilot Analysis

---

## Executive Summary

This document analyzes the **old kombify Administration** system and compares it to the **current kombify-admin** implementation in StackKits. The goal is to identify which functionalities should be migrated, which are already present, and which are no longer needed for StackKits' internal tool management use case.

### Key Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Tool Discovery** | ✅ Migrate enhanced crawler scheduling | Old system has mature crawl source management with scheduling, retry logic, and failure handling |
| **Deduplication** | ✅ Add to current | Critical for avoiding duplicate tool entries; old system has proven strategy |
| **Evaluation Workflow** | ⚠️ Partial migration | Current has ToolEvaluation; need to add state machine transitions |
| **User Evaluations** | ❌ Not needed | StackKits is internal; no community reviews |
| **AI Evaluations** | ✅ Already in current | Tool model has aiSummary, aiQualityScore, aiPros, aiCons |
| **Multi-tenancy** | ❌ Not needed | Single internal deployment |
| **Billing/Stripe** | ❌ Not needed | StackKits is not monetized at this level |
| **User Management** | ❌ Not needed | Internal use, no Zitadel/auth needed |
| **SimulationPreview** | ❌ Not needed | KombiSim is separate product |
| **Support Tickets** | ❌ Not needed | Internal tooling |

---

## System Comparison

### 1. Database Schema Comparison

#### Core Tool Model

| Feature | Old Admin (PocketBase → Prisma) | Current kombify-admin | Action |
|---------|----------------------------------|----------------------|--------|
| Basic fields (name, slug, description) | ✅ | ✅ | None |
| Layer classification | ❌ | ✅ Built-in enum | Keep current |
| Category | ✅ Via junction table | ✅ String field | Keep current (simpler) |
| Lifecycle state | ✅ status + evaluation_status | ✅ Single lifecycleState | Keep current |
| Discovery tracking | ✅ discoverySource, discoveredAt | ✅ discoverySource, discoveredAt | Already aligned |
| Deduplication fields | ✅ normalizedName, canonicalRepoUrl | ❌ Missing | **ADD** |
| AI enrichment | ✅ Separate AiEvaluation model | ✅ Inline on Tool | Keep current (simpler) |
| Resource requirements | ✅ minResources JSON | ✅ minMemoryMB, supportsArm, etc. | Keep current (typed) |
| Scraped data | ✅ source_metadata JSON | ✅ scrapedData JSON, contentHash | Already aligned |

#### Discovery Infrastructure

| Feature | Old Admin | Current | Action |
|---------|-----------|---------|--------|
| CrawlSource (scheduled sources) | ✅ Full model with scheduling | ❌ Only ToolCategory.firecrawlQueries | **ADD CrawlSource model** |
| CrawlJob (job tracking) | ✅ Detailed with results | ✅ DiscoveryJob (simpler) | Enhance current |
| CrawlJobResults | ✅ Per-tool results | ❌ Missing | **ADD relation** |
| SearchSource (custom sources) | ✅ | ❌ | Not needed (Firecrawl handles) |
| Deduplication service | ✅ Architecture planned | ❌ Missing | **ADD deduplication logic** |
| Schedule types (interval, cron) | ✅ | ❌ | **ADD to CrawlSource** |
| Retry/failure handling | ✅ Designed | ❌ Missing | **ADD retry logic** |

#### Evaluation System

| Feature | Old Admin | Current | Action |
|---------|-----------|---------|--------|
| Internal evaluation | ✅ evaluation_status enum | ✅ ToolEvaluation model | Keep current |
| Evaluation scores | ✅ In AiEvaluation | ✅ In ToolEvaluation (score*) | Already aligned |
| Community reviews | ✅ Evaluation model (user ratings) | ❌ | Not needed |
| Evaluation history tracking | ✅ evaluation_history JSON | ❌ | **ADD to ToolEvaluation** |
| State transition validation | ✅ Designed | ❌ | **ADD validation logic** |

### 2. What's GOOD in Current That Old Lacks

The current kombify-admin has several v4 architecture concepts that the old system doesn't have:

| Feature | Description | Status |
|---------|-------------|--------|
| **Architecture Patterns** | BASE, MODERN, HA enum | ✅ Keep |
| **Add-On System** | Composable extensions replacing monolithic variants | ✅ Keep |
| **Context System** | LOCAL, CLOUD, PI runtime detection | ✅ Keep |
| **CUE Generation** | Generate validation schemas from DB | ✅ Keep |
| **n8n Integration** | Workflow automation registry | ✅ Keep |
| **Settings Classification** | PERMA vs FLEXIBLE settings | ✅ Keep |
| **Pattern Library** | Reusable patterns with evaluation | ✅ Keep |
| **Decision Registry** | ADRs in database | ✅ Keep |
| **ScrapeResult Storage** | Raw scrape data with processing status | ✅ Keep |

---

## Migration Plan

### Phase 1: Deduplication Infrastructure (Priority: HIGH)

Add deduplication capabilities to prevent duplicate tool entries during discovery.

**Schema Changes:**
```prisma
model Tool {
  // ... existing fields ...
  
  // ADD: Deduplication fields
  normalizedName    String?   // Lowercase, trimmed, special chars removed
  canonicalRepoUrl  String?   // Normalized repository URL
  
  @@index([normalizedName])
  @@index([canonicalRepoUrl])
}
```

**New Helper Functions (scripts/lib/deduplication.ts):**
```typescript
function normalizeToolName(name: string): string
function normalizeRepoUrl(url: string): string
function generateDeduplicationKey(tool: Tool): string
function findDuplicates(db: PrismaClient, tool: Partial<Tool>): Promise<Tool[]>
```

**Effort:** ~4 hours

### Phase 2: Crawl Source Management (Priority: HIGH)

Add scheduled crawl sources for automated tool discovery (currently only one-shot scripts).

**Schema Changes:**
```prisma
// New model for scheduled discovery sources
model CrawlSource {
  id                String    @id @default(uuid())
  name              String    @unique
  sourceType        String    // "firecrawl", "github", "docker-hub"
  sourceUrl         String?
  query             String?
  
  // Scheduling
  scheduleType      String?   // "manual", "interval", "cron"
  scheduleValue     String?   // "1d", "6h", "0 0 * * *"
  nextRunAt         DateTime?
  lastRunAt         DateTime?
  
  // Targeting
  categoryId        String?   // Link to ToolCategory
  priority          Int       @default(0)
  
  // Health
  isActive          Boolean   @default(true)
  isPaused          Boolean   @default(false)
  consecutiveFailures Int     @default(0)
  maxRetries        Int       @default(3)
  
  // Relations
  discoveryJobs     DiscoveryJob[]
  
  @@index([isActive])
  @@index([nextRunAt])
}

// Enhance DiscoveryJob with source reference
model DiscoveryJob {
  // ... existing fields ...
  
  // ADD: Link to crawl source
  crawlSourceId     String?
  crawlSource       CrawlSource? @relation(...)
  
  // ADD: Per-tool results tracking
  results           DiscoveryJobResult[]
}

// New model for per-tool discovery results
model DiscoveryJobResult {
  id                String    @id @default(uuid())
  jobId             String
  toolId            String?   // If matched to existing
  action            String    // "created", "updated", "skipped", "failed"
  toolData          Json      // Discovered data
  deduplicationKey  String?
  errorMessage      String?
  
  job               DiscoveryJob @relation(...)
  
  @@index([jobId])
  @@index([action])
}
```

**n8n Workflow:**
- Scheduled trigger (cron)
- Read active CrawlSources where nextRunAt <= now
- For each source: trigger tool-discover.ts script
- Update source.lastRunAt, calculate nextRunAt

**Effort:** ~8 hours

### Phase 3: Evaluation State Machine (Priority: MEDIUM)

Add proper state transitions and history tracking for tool evaluation workflow.

**Schema Changes:**
```prisma
model ToolEvaluation {
  // ... existing fields ...
  
  // ADD: State tracking
  previousVerdict   EvaluationVerdict?
  transitionReason  String?
  
  // ADD: History is already on Tool but consider:
  // - Move history to separate table for complex queries
}

// Or simpler: Add evaluation_history to Tool
model Tool {
  // ... existing fields ...
  
  // ADD: Evaluation workflow history
  evaluationHistory Json?  // [{timestamp, from, to, by, notes}]
}
```

**Validation Rules (scripts/lib/evaluation.ts):**
```typescript
const VALID_TRANSITIONS: Record<string, string[]> = {
  'DISCOVERED': ['EVALUATED', 'ARCHIVED'],
  'DRAFT': ['EVALUATED', 'ARCHIVED'],
  'EVALUATED': ['APPROVED', 'DEPRECATED', 'DRAFT'],
  'APPROVED': ['DEPRECATED', 'EVALUATED'],
  'DEPRECATED': ['ARCHIVED', 'APPROVED'],
  'ARCHIVED': ['DRAFT'],  // Resurrection
};

function validateTransition(from: LifecycleState, to: LifecycleState): boolean
function recordTransition(tool: Tool, to: LifecycleState, by: string, notes: string): Tool
```

**Effort:** ~4 hours

### Phase 4: Discovery Job Failure Handling (Priority: MEDIUM)

Add retry logic with exponential backoff for failed discovery jobs.

**Implementation:**
```typescript
// In tool-discover.ts
const RETRY_DELAYS = [5000, 15000, 45000, 135000]; // Exponential backoff

async function runDiscoveryWithRetry(source: CrawlSource): Promise<void> {
  let attempt = 0;
  while (attempt <= source.maxRetries) {
    try {
      await runDiscovery(source);
      await resetFailureCount(source);
      return;
    } catch (error) {
      attempt++;
      if (attempt > source.maxRetries) {
        await incrementFailureCount(source);
        if (source.consecutiveFailures >= 5) {
          await pauseSource(source);
          await notifyAdmin(source, 'Auto-paused after 5 failures');
        }
        throw error;
      }
      await sleep(RETRY_DELAYS[attempt - 1] || 135000);
    }
  }
}
```

**Effort:** ~4 hours

---

## What NOT to Migrate

### 1. User Management / Authentication
- **Old:** Zitadel integration, user roles, impersonation
- **Why skip:** StackKits is internal tooling; no user auth needed
- **Alternative:** Scripts run locally with DB access

### 2. Billing / Stripe Integration
- **Old:** Subscriptions, webhooks, usage metrics
- **Why skip:** StackKits is not monetized
- **Alternative:** None needed

### 3. Multi-Tenancy
- **Old:** tenant_id on all tables
- **Why skip:** Single deployment for internal use
- **Alternative:** None needed

### 4. Community Evaluations
- **Old:** User reviews with ratings, pros/cons
- **Why skip:** Internal team evaluation only
- **Alternative:** ToolEvaluation already covers internal review

### 5. SimulationPreview (KombiSim)
- **Old:** Tool preview in sandbox environment
- **Why skip:** KombiSim is separate product
- **Alternative:** None needed for StackKits

### 6. Support System
- **Old:** Tickets, comments
- **Why skip:** Not applicable for internal tooling
- **Alternative:** Use GitHub issues

### 7. Webhook Infrastructure
- **Old:** WebhookLog, SyncEvent for Stripe
- **Why skip:** No external webhooks needed
- **Alternative:** n8n handles any integrations

---

## Unified Discovery Pipeline Design

The migrated system will have this pipeline:

```
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│   CrawlSource    │────▶│  DiscoveryJob     │────▶│  ScrapeResult    │
│  (scheduled)     │     │  (execution)      │     │  (raw data)      │
└──────────────────┘     └───────────────────┘     └──────────────────┘
                                  │
                                  ▼
                         ┌───────────────────┐
                         │ DiscoveryJobResult│
                         │ (per-tool action) │
                         └───────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌─────────┐  ┌─────────────┐ ┌──────────┐
              │ CREATE  │  │   UPDATE    │ │   SKIP   │
              │new Tool │  │existing Tool│ │duplicate │
              └─────────┘  └─────────────┘ └──────────┘
                    │             │
                    ▼             ▼
              ┌─────────────────────────────────────┐
              │          Tool (DISCOVERED)          │
              │  + normalizedName, canonicalRepoUrl │
              └─────────────────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
              ┌─────────┐  ┌─────────────┐ ┌──────────┐
              │ ENRICH  │  │   REVIEW    │ │ AUTO-CUE │
              │AI scores│  │manual eval  │ │generation│
              └─────────┘  └─────────────┘ └──────────┘
```

---

## Implementation Priority

### P0 (This Week) - Foundation
1. ✅ Database running (done)
2. ✅ Seed working (done)
3. ✅ CUE generation working (done)
4. Add deduplication fields to Tool model
5. Implement deduplication helper functions

### P1 (Next Week) - Automation
1. Add CrawlSource model with scheduling
2. Link DiscoveryJob to CrawlSource
3. Add DiscoveryJobResult model
4. Update tool-discover.ts to use CrawlSource
5. Create n8n workflow for scheduled discovery

### P2 (Following Week) - Polish
1. Add evaluation state machine
2. Add evaluation history tracking
3. Add retry logic with backoff
4. Enhance tool-review.ts with state transitions
5. Add failure notifications

---

## Beads Tasks to Create

```
EPIC: StackKits-admin-migration
├── Add deduplication fields to Tool schema
├── Implement deduplication helper functions
├── Add CrawlSource model with scheduling
├── Link DiscoveryJob to CrawlSource
├── Add DiscoveryJobResult model
├── Update tool-discover.ts to use new models
├── Create n8n workflow for scheduled discovery
├── Add evaluation state machine
├── Add retry logic with exponential backoff
└── Write migration guide documentation
```

---

## Appendix: Files Changed/Created

### New Files to Create
- `kombify-admin/prisma/migrations/002_deduplication.sql`
- `kombify-admin/prisma/migrations/003_crawl_sources.sql`
- `kombify-admin/scripts/lib/deduplication.ts`
- `kombify-admin/scripts/lib/evaluation.ts`
- `kombify-admin/scripts/crawl-scheduler.ts`

### Files to Modify
- `kombify-admin/prisma/schema.prisma` (add models)
- `kombify-admin/scripts/tool-discover.ts` (use CrawlSource)
- `kombify-admin/scripts/tool-review.ts` (state validation)

### Files NOT Needed (from old admin)
- All Zitadel/auth code
- All Stripe/billing code
- All multi-tenant isolation code
- Support ticket code
- User impersonation code

---

## Conclusion

The current kombify-admin already has a strong foundation with v4 architecture concepts (Add-Ons, Contexts, CUE generation) that the old admin lacks. The key migration items are:

1. **Deduplication** - Essential for avoiding duplicate tools
2. **Crawl scheduling** - For automated continuous discovery
3. **State machine** - For proper evaluation workflow

The old admin's user management, billing, and multi-tenancy features are intentionally skipped as they don't apply to StackKits' internal tooling use case.

**Total Estimated Effort:** ~20-24 hours across 3 phases

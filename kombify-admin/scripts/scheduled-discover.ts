/**
 * Scheduled Discovery Trigger
 *
 * Called by n8n to run scheduled tool discovery from CrawlSources.
 * Designed to be invoked via HTTP webhook or command line.
 *
 * Usage:
 *   # Run all due sources
 *   npx ts-node scripts/scheduled-discover.ts
 *
 *   # Run specific source
 *   npx ts-node scripts/scheduled-discover.ts --source <crawlSourceId>
 *
 *   # Dry run (no database changes)
 *   npx ts-node scripts/scheduled-discover.ts --dry-run
 *
 * Environment:
 *   DATABASE_URL       - PostgreSQL connection string
 *   FIRECRAWL_API_KEY  - Firecrawl API key
 *   N8N_EXECUTION_ID   - Set by n8n for tracking (optional)
 *   N8N_WORKFLOW_ID    - Set by n8n for tracking (optional)
 *
 * Returns (for n8n):
 *   { success: boolean, sourcesProcessed: number, toolsDiscovered: number, errors: string[] }
 */

import {
  PrismaClient,
  CrawlSource,
  JobType,
  JobStatus,
  DiscoverySource,
  LifecycleState,
  LayerType,
} from '@prisma/client';
import { scheduleNextRun, updateCrawlSourceFailures, withRetry, FIRECRAWL_RETRY_OPTIONS } from './retry';
import { findDuplicates, computeDeduplicationFields } from './deduplication';
import * as crypto from 'crypto';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const FIRECRAWL_API_KEY = process.env.FIRECRAWL_API_KEY || '';
const FIRECRAWL_BASE_URL = process.env.FIRECRAWL_BASE_URL || 'https://api.firecrawl.dev/v1';
const N8N_EXECUTION_ID = process.env.N8N_EXECUTION_ID;
const N8N_WORKFLOW_ID = process.env.N8N_WORKFLOW_ID;
const MAX_RESULTS_PER_SOURCE = 10;
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

function parseArgs(): { sourceId?: string } {
  const args: { sourceId?: string } = {};
  const sourceIdx = process.argv.indexOf('--source');
  if (sourceIdx !== -1 && process.argv[sourceIdx + 1]) {
    args.sourceId = process.argv[sourceIdx + 1];
  }
  return args;
}

// ---------------------------------------------------------------------------
// Firecrawl API
// ---------------------------------------------------------------------------

interface FirecrawlSearchResult {
  url: string;
  title?: string;
  description?: string;
  markdown?: string;
}

async function firecrawlSearch(query: string): Promise<FirecrawlSearchResult[]> {
  if (!FIRECRAWL_API_KEY) {
    return [];
  }

  try {
    return await withRetry(async () => {
      const response = await fetch(`${FIRECRAWL_BASE_URL}/search`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${FIRECRAWL_API_KEY}`,
        },
        body: JSON.stringify({
          query,
          limit: MAX_RESULTS_PER_SOURCE,
        }),
      });

      if (!response.ok) {
        throw new Error(`Firecrawl search failed: ${response.status}`);
      }

      const data = await response.json() as { data?: FirecrawlSearchResult[] };
      return data.data || [];
    }, FIRECRAWL_RETRY_OPTIONS);
  } catch {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Discovery Logic
// ---------------------------------------------------------------------------

interface DiscoveryResult {
  source: CrawlSource;
  discovered: number;
  skipped: number;
  errors: string[];
}

async function processSource(source: CrawlSource, jobId: string): Promise<DiscoveryResult> {
  const result: DiscoveryResult = {
    source,
    discovered: 0,
    skipped: 0,
    errors: [],
  };

  if (!source.query) {
    result.errors.push('No query configured');
    return result;
  }

  console.log(`Processing source: ${source.name} (${source.sourceType})`);
  console.log(`  Query: ${source.query}`);

  const searchResults = await firecrawlSearch(source.query);
  console.log(`  Found ${searchResults.length} results`);

  for (const searchResult of searchResults) {
    // Extract basic tool info
    const name = searchResult.title
      ?.toLowerCase()
      .replace(/\s*[-–|]\s*GitHub$/i, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    if (!name) continue;

    // Check for duplicates
    const dedup = await findDuplicates(prisma, {
      name,
      homepageUrl: searchResult.url,
    });

    if (dedup.isDuplicate) {
      console.log(`  [SKIP] Duplicate: ${name} (${dedup.matchReason})`);
      result.skipped++;

      // Log to DiscoveryJobResult
      if (!DRY_RUN) {
        await prisma.discoveryJobResult.create({
          data: {
            jobId,
            toolId: dedup.matchedTool?.id,
            action: 'skipped',
            toolData: searchResult as any,
            deduplicationKey: dedup.normalizedName || dedup.canonicalRepoUrl,
          },
        });
      }
      continue;
    }

    if (DRY_RUN) {
      console.log(`  [DRY-RUN] Would create: ${name}`);
      result.discovered++;
      continue;
    }

    // Compute dedup fields
    const dedupFields = computeDeduplicationFields({ name });

    // Create tool
    try {
      const tool = await prisma.tool.create({
        data: {
          name,
          displayName: searchResult.title || name,
          description: searchResult.description || `Discovered from ${searchResult.url}`,
          layer: (source.targetCategory === 'paas' ? 'APPLICATION' : 'SYSTEM') as LayerType,
          category: source.targetCategory || 'uncategorized',
          image: 'unknown',
          defaultTag: 'latest',
          lifecycleState: LifecycleState.DISCOVERED,
          discoverySource: source.sourceType === 'github' ? DiscoverySource.GITHUB_SEARCH : DiscoverySource.FIRECRAWL,
          homepageUrl: searchResult.url,
          normalizedName: dedupFields.normalizedName,
          canonicalRepoUrl: dedupFields.canonicalRepoUrl,
          discoveredAt: new Date(),
        },
      });

      await prisma.discoveryJobResult.create({
        data: {
          jobId,
          toolId: tool.id,
          action: 'created',
          toolData: searchResult as any,
          deduplicationKey: dedupFields.normalizedName,
        },
      });

      console.log(`  [NEW] ${name}`);
      result.discovered++;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`  [ERROR] Failed to create ${name}: ${msg}`);
      result.errors.push(`${name}: ${msg}`);

      await prisma.discoveryJobResult.create({
        data: {
          jobId,
          action: 'failed',
          toolData: searchResult as any,
          errorMessage: msg,
        },
      });
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const args = parseArgs();

  console.log('='.repeat(60));
  console.log('Scheduled Tool Discovery');
  console.log('='.repeat(60));
  console.log(`Dry run: ${DRY_RUN}`);
  console.log(`n8n execution: ${N8N_EXECUTION_ID || 'direct'}`);
  console.log('');

  // Find sources to process
  let sources: CrawlSource[];
  if (args.sourceId) {
    const source = await prisma.crawlSource.findUnique({ where: { id: args.sourceId } });
    sources = source ? [source] : [];
  } else {
    // Get all due sources (nextRunAt <= now, active, not paused)
    sources = await prisma.crawlSource.findMany({
      where: {
        isActive: true,
        isPaused: false,
        OR: [
          { nextRunAt: { lte: new Date() } },
          { nextRunAt: null, scheduleType: 'manual' }, // Manual sources only run when explicitly called
        ],
      },
      orderBy: [{ priority: 'desc' }, { nextRunAt: 'asc' }],
    });

    // For initial run, also include sources with no nextRunAt set
    if (sources.length === 0) {
      sources = await prisma.crawlSource.findMany({
        where: {
          isActive: true,
          isPaused: false,
          scheduleType: { not: 'manual' },
        },
        orderBy: [{ priority: 'desc' }],
        take: 5,
      });
    }
  }

  if (sources.length === 0) {
    console.log('No sources to process');
    console.log(JSON.stringify({ success: true, sourcesProcessed: 0, toolsDiscovered: 0, errors: [] }));
    return;
  }

  console.log(`Processing ${sources.length} sources`);

  // Create discovery job
  const job = DRY_RUN
    ? { id: 'dry-run' }
    : await prisma.discoveryJob.create({
        data: {
          jobType: JobType.TOOL_DISCOVERY,
          status: JobStatus.RUNNING,
          source: DiscoverySource.FIRECRAWL,
          n8nExecutionId: N8N_EXECUTION_ID,
          n8nWorkflowId: N8N_WORKFLOW_ID,
          startedAt: new Date(),
        },
      });

  let totalDiscovered = 0;
  let totalSkipped = 0;
  const allErrors: string[] = [];

  for (const source of sources) {
    try {
      const result = await processSource(source, job.id);
      totalDiscovered += result.discovered;
      totalSkipped += result.skipped;
      allErrors.push(...result.errors);

      // Update source failure tracking
      if (!DRY_RUN) {
        const failed = result.errors.length > 0 && result.discovered === 0;
        await updateCrawlSourceFailures(prisma, source.id, failed);
        await scheduleNextRun(prisma, source.id);
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`Error processing source ${source.name}: ${msg}`);
      allErrors.push(`${source.name}: ${msg}`);

      if (!DRY_RUN) {
        await updateCrawlSourceFailures(prisma, source.id, true);
      }
    }
  }

  // Update job
  if (!DRY_RUN) {
    await prisma.discoveryJob.update({
      where: { id: job.id },
      data: {
        status: allErrors.length > 0 ? JobStatus.COMPLETED : JobStatus.COMPLETED,
        completedAt: new Date(),
        toolsDiscovered: totalDiscovered,
        toolsSkipped: totalSkipped,
        durationMs: Date.now() - new Date((job as any).startedAt || Date.now()).getTime(),
        errorMessage: allErrors.length > 0 ? allErrors.join('\n') : null,
      },
    });
  }

  // Output for n8n
  const output = {
    success: allErrors.length === 0,
    sourcesProcessed: sources.length,
    toolsDiscovered: totalDiscovered,
    toolsSkipped: totalSkipped,
    errors: allErrors,
    jobId: job.id,
  };

  console.log('\n' + '='.repeat(60));
  console.log('Results:');
  console.log(`  Sources processed: ${sources.length}`);
  console.log(`  Tools discovered: ${totalDiscovered}`);
  console.log(`  Tools skipped: ${totalSkipped}`);
  console.log(`  Errors: ${allErrors.length}`);
  console.log('');
  console.log('JSON output for n8n:');
  console.log(JSON.stringify(output, null, 2));
}

main()
  .catch((e) => {
    console.error('Fatal error:', e);
    console.log(JSON.stringify({ success: false, error: e.message }));
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

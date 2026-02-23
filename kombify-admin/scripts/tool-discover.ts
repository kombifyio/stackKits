/**
 * Tool Discovery Script
 *
 * Discovers new self-hosted tools using Firecrawl search and scraping.
 * Follows the Websearch-UI pattern: Search → Scrape → Extract → Store.
 *
 * Usage:
 *   npx ts-node scripts/tool-discover.ts [category]
 *
 * Arguments:
 *   category  - Tool category slug to search for (e.g., "paas", "monitoring")
 *               If omitted, searches all categories.
 *
 * Environment:
 *   FIRECRAWL_API_KEY  - Firecrawl API key (required)
 *   DATABASE_URL       - PostgreSQL connection string (required)
 *
 * Pipeline:
 *   1. Load ToolCategory entries with firecrawlQueries
 *   2. Search via Firecrawl for each query
 *   3. Scrape top results for detailed tool information
 *   4. Extract structured data (name, description, Docker image, etc.)
 *   5. Store as ScrapeResult + create/update Tool entries with DISCOVERED state
 *   6. Log DiscoveryJob with results
 */

import {
  PrismaClient,
  DiscoverySource,
  JobType,
  JobStatus,
  LifecycleState,
  LayerType,
} from '@prisma/client';
import * as crypto from 'crypto';
import {
  findDuplicates,
  computeDeduplicationFields,
} from './deduplication';
import { withRetry, FIRECRAWL_RETRY_OPTIONS } from './retry';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const FIRECRAWL_API_KEY = process.env.FIRECRAWL_API_KEY || '';
const FIRECRAWL_BASE_URL = process.env.FIRECRAWL_BASE_URL || 'https://api.firecrawl.dev/v1';
const MAX_RESULTS_PER_QUERY = 5;
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Firecrawl API helpers
// ---------------------------------------------------------------------------

interface FirecrawlSearchResult {
  url: string;
  title?: string;
  description?: string;
  markdown?: string;
}

interface FirecrawlScrapeResult {
  markdown?: string;
  html?: string;
  metadata?: {
    title?: string;
    description?: string;
    ogImage?: string;
    sourceURL?: string;
  };
  links?: string[];
}

async function firecrawlSearch(query: string): Promise<FirecrawlSearchResult[]> {
  if (!FIRECRAWL_API_KEY) {
    console.warn('  [SKIP] No FIRECRAWL_API_KEY set — returning empty results');
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
          limit: MAX_RESULTS_PER_QUERY,
        }),
      });

      if (!response.ok) {
        const text = await response.text();
        throw new Error(`Firecrawl search failed: ${response.status} ${text}`);
      }

      const data = await response.json() as { data?: FirecrawlSearchResult[] };
      return data.data || [];
    }, FIRECRAWL_RETRY_OPTIONS);
  } catch (error) {
    console.error(`  [ERROR] ${(error as Error).message}`);
    return [];
  }
}

async function firecrawlScrape(url: string): Promise<FirecrawlScrapeResult | null> {
  if (!FIRECRAWL_API_KEY) {
    console.warn('  [SKIP] No FIRECRAWL_API_KEY set — skipping scrape');
    return null;
  }

  try {
    return await withRetry(async () => {
      const response = await fetch(`${FIRECRAWL_BASE_URL}/scrape`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${FIRECRAWL_API_KEY}`,
        },
        body: JSON.stringify({
          url,
          formats: ['markdown'],
          onlyMainContent: true,
        }),
      });

      if (!response.ok) {
        const text = await response.text();
        throw new Error(`Firecrawl scrape failed for ${url}: ${response.status} ${text}`);
      }

      const data = await response.json() as { data?: FirecrawlScrapeResult };
      return data.data || null;
    }, FIRECRAWL_RETRY_OPTIONS);
  } catch (error) {
    console.error(`  [ERROR] ${(error as Error).message}`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Tool extraction heuristics
// ---------------------------------------------------------------------------

interface ExtractedTool {
  name: string;
  displayName: string;
  description: string;
  dockerImage?: string;
  githubUrl?: string;
  homepageUrl: string;
  supportsArm?: boolean;
  license?: string;
}

/**
 * Extract tool metadata from scraped content using heuristics.
 * This is a Tier-1 extraction (structural). AI enrichment is done separately.
 */
function extractToolFromMarkdown(
  url: string,
  title: string | undefined,
  markdown: string | undefined
): Partial<ExtractedTool> {
  const result: Partial<ExtractedTool> = {
    homepageUrl: url,
  };

  if (title) {
    // Clean title — remove common suffixes
    result.displayName = title
      .replace(/\s*[-–|]\s*GitHub$/i, '')
      .replace(/\s*[-–|]\s*Docker Hub$/i, '')
      .replace(/\s*[-–|]\s*Official.*$/i, '')
      .trim();

    // Generate machine name from display name
    result.name = result.displayName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
  }

  if (!markdown) return result;

  // Extract GitHub URL
  const githubMatch = markdown.match(
    /https:\/\/github\.com\/[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+/
  );
  if (githubMatch) {
    result.githubUrl = githubMatch[0];
  }

  // Extract Docker image
  const dockerPatterns = [
    /docker\s+pull\s+([a-z0-9_/-]+(?::[a-z0-9._-]+)?)/i,
    /image:\s*['"]?([a-z0-9_/-]+(?::[a-z0-9._-]+)?)/i,
    /ghcr\.io\/[a-z0-9_/-]+/i,
  ];
  for (const pattern of dockerPatterns) {
    const match = markdown.match(pattern);
    if (match) {
      result.dockerImage = match[1] || match[0];
      break;
    }
  }

  // Extract description — first paragraph-like content
  const descMatch = markdown.match(
    /(?:^|\n)(?:#{1,3}\s+.+\n+)?([A-Z][^#\n]{30,200})/
  );
  if (descMatch) {
    result.description = descMatch[1].trim();
  }

  // Detect ARM support
  if (/arm64|aarch64|raspberry\s*pi|multi-arch/i.test(markdown)) {
    result.supportsArm = true;
  }

  // Detect license
  const licenseMatch = markdown.match(
    /(?:license|licensed)\s*(?:under)?\s*:?\s*(MIT|Apache[- ]2\.0|GPL[- ]?v?[23]|AGPL|BSD|MPL)/i
  );
  if (licenseMatch) {
    result.license = licenseMatch[1].toUpperCase();
  }

  return result;
}

// ---------------------------------------------------------------------------
// Discovery pipeline
// ---------------------------------------------------------------------------

async function discoverForCategory(
  category: {
    slug: string;
    displayName: string;
    layer: LayerType;
    standardTool: string | null;
    alternativeTools: string[];
    firecrawlQueries: string[];
  },
  jobId: string
): Promise<{ discovered: number; updated: number; skipped: number }> {
  console.log(`\n--- Discovering tools for: ${category.displayName} (${category.slug}) ---`);
  let discovered = 0;
  let updated = 0;

  // Track skipped duplicates for reporting
  let skipped = 0;

  for (const query of category.firecrawlQueries) {
    console.log(`  Searching: "${query}"`);

    const searchResults = await firecrawlSearch(query);
    console.log(`  Found ${searchResults.length} results`);

    for (const result of searchResults) {


      // Extract basic info from search result
      const extracted = extractToolFromMarkdown(
        result.url,
        result.title,
        result.markdown || result.description
      );

      if (!extracted.name) {
        console.log(`  [SKIP] Could not extract name from: ${result.url}`);
        continue;
      }

      // Deduplication check using normalized fields
      const dedup = await findDuplicates(prisma, {
        name: extracted.name,
        githubUrl: extracted.githubUrl,
        homepageUrl: extracted.homepageUrl,
        dockerImage: extracted.dockerImage,
      });

      if (dedup.isDuplicate && dedup.matchedTool) {
        console.log(`  [SKIP] Duplicate of "${dedup.matchedTool.name}" (${dedup.matchReason})`);
        skipped++;
        continue;
      }

      // Scrape for more detail
      console.log(`  Scraping: ${result.url}...`);
      const scraped = await firecrawlScrape(result.url);

      if (scraped?.markdown) {
        // Re-extract with full content
        const fullExtracted = extractToolFromMarkdown(
          result.url,
          scraped.metadata?.title || result.title,
          scraped.markdown
        );
        Object.assign(extracted, fullExtracted);
      }

      // Content hash for change detection
      const contentHash = crypto
        .createHash('sha256')
        .update(scraped?.markdown || result.description || '')
        .digest('hex');

      if (DRY_RUN) {
        console.log(`  [DRY-RUN] Would create tool: ${extracted.name}`);
        console.log(`    Display: ${extracted.displayName}`);
        console.log(`    Docker:  ${extracted.dockerImage || 'unknown'}`);
        console.log(`    GitHub:  ${extracted.githubUrl || 'unknown'}`);
        discovered++;
        continue;
      }

      // Store scrape result
      await prisma.scrapeResult.create({
        data: {
          url: result.url,
          toolName: extracted.name,
          discoveryJobId: jobId,
          markdownContent: scraped?.markdown?.substring(0, 50000), // Truncate large pages
          extractedData: extracted as any,
          pageTitle: scraped?.metadata?.title || result.title,
          pageDescription: scraped?.metadata?.description || result.description,
          contentHash,
          httpStatusCode: 200,
          firecrawlMeta: scraped?.metadata as any,
          isProcessed: false,
        },
      });

      // Compute deduplication fields for the new tool
      const dedupFields = computeDeduplicationFields({
        name: extracted.name,
        githubUrl: extracted.githubUrl,
      });

      // Create discovered tool entry with deduplication fields
      await prisma.tool.create({
        data: {
          name: extracted.name,
          displayName: extracted.displayName || extracted.name,
          description: extracted.description || `Discovered from ${result.url}`,
          layer: category.layer,
          category: category.slug,
          image: extracted.dockerImage || 'unknown',
          defaultTag: 'latest',
          lifecycleState: LifecycleState.DISCOVERED,
          discoverySource: DiscoverySource.FIRECRAWL,
          homepageUrl: extracted.homepageUrl,
          sourceUrl: extracted.githubUrl,
          licenseType: extracted.license,
          supportsArm: extracted.supportsArm,
          contentHash,
          lastScrapedAt: new Date(),
          // Deduplication fields
          normalizedName: dedupFields.normalizedName,
          canonicalRepoUrl: dedupFields.canonicalRepoUrl,
        },
      });
      discovered++;
      console.log(`  [NEW] Discovered: ${extracted.name} (${extracted.displayName})`);
    }
  }

  return { discovered, updated, skipped };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const targetCategory = process.argv[2];

  console.log('='.repeat(60));
  console.log('Tool Discovery - kombify-admin');
  console.log('='.repeat(60));
  console.log(`Target: ${targetCategory || 'all categories'}`);
  console.log(`Dry run: ${DRY_RUN}`);
  console.log(`Firecrawl: ${FIRECRAWL_API_KEY ? 'configured' : 'NOT SET'}`);
  console.log('');

  // Load categories
  const whereClause = targetCategory ? { slug: targetCategory } : {};
  const categories = await prisma.toolCategory.findMany({
    where: whereClause,
  });

  if (categories.length === 0) {
    console.error(`No categories found${targetCategory ? ` for slug "${targetCategory}"` : ''}`);
    process.exit(1);
  }

  console.log(`Found ${categories.length} categories to search`);

  // Create discovery job
  const job = DRY_RUN
    ? { id: 'dry-run' }
    : await prisma.discoveryJob.create({
        data: {
          jobType: JobType.TOOL_DISCOVERY,
          status: JobStatus.RUNNING,
          query: targetCategory || 'all',
          source: DiscoverySource.FIRECRAWL,
          startedAt: new Date(),
        },
      });

  let totalDiscovered = 0;
  let totalUpdated = 0;
  let totalSkipped = 0;

  for (const category of categories) {
    try {
      const result = await discoverForCategory(category, job.id);
      totalDiscovered += result.discovered;
      totalUpdated += result.updated;
      totalSkipped += result.skipped;
    } catch (error) {
      console.error(`Error discovering for ${category.slug}:`, error);
    }
  }

  // Update job
  if (!DRY_RUN) {
    await prisma.discoveryJob.update({
      where: { id: job.id },
      data: {
        status: JobStatus.COMPLETED,
        completedAt: new Date(),
        toolsDiscovered: totalDiscovered,
        toolsUpdated: totalUpdated,
        toolsSkipped: totalSkipped,
        durationMs: Date.now() - (job as any).startedAt?.getTime() || 0,
      },
    });
  }

  console.log('\n' + '='.repeat(60));
  console.log(`Discovery complete!`);
  console.log(`  New tools discovered: ${totalDiscovered}`);
  console.log(`  Existing tools updated: ${totalUpdated}`);
  console.log(`  Duplicates skipped: ${totalSkipped}`);
  console.log('');
  console.log('Next steps:');
  console.log('  1. Review discovered tools: npx ts-node scripts/tool-review.ts');
  console.log('  2. Enrich with AI: npx ts-node scripts/tool-enrich.ts');
  console.log('  3. Evaluate: npx ts-node scripts/tool-evaluate.ts');
}

main()
  .catch((e) => {
    console.error('Discovery failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

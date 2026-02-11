/**
 * Tool Enrichment Script
 *
 * Enriches discovered tools with AI-generated summaries, quality scores,
 * and structured metadata extracted from scraped content.
 *
 * This is Tier-3 of the extraction pipeline (AI fallback),
 * following the Websearch-UI pattern.
 *
 * Usage:
 *   npx ts-node scripts/tool-enrich.ts [tool-name]
 *   npx ts-node scripts/tool-enrich.ts --discovered   # Enrich only DISCOVERED tools
 *   npx ts-node scripts/tool-enrich.ts --all           # Re-enrich all tools
 *
 * Environment:
 *   FIRECRAWL_API_KEY  - Firecrawl API key (for AI extraction)
 *   DATABASE_URL       - PostgreSQL connection string
 */

import {
  PrismaClient,
  LifecycleState,
} from '@prisma/client';

const prisma = new PrismaClient();

const FIRECRAWL_API_KEY = process.env.FIRECRAWL_API_KEY || '';
const FIRECRAWL_BASE_URL = process.env.FIRECRAWL_BASE_URL || 'https://api.firecrawl.dev/v1';

// ---------------------------------------------------------------------------
// AI extraction via Firecrawl /extract endpoint
// ---------------------------------------------------------------------------

interface ToolExtractionSchema {
  name: string;
  description: string;
  dockerImage: string;
  latestVersion: string;
  license: string;
  features: string[];
  pros: string[];
  cons: string[];
  setupComplexity: 'simple' | 'moderate' | 'complex';
  resourceUsage: 'low' | 'medium' | 'high';
  supportsArm: boolean;
  hasWebUI: boolean;
  hasAPI: boolean;
  activelyMaintained: boolean;
  communitySize: 'small' | 'medium' | 'large';
}

async function firecrawlExtract(
  url: string,
  prompt: string,
  schema: object
): Promise<any | null> {
  if (!FIRECRAWL_API_KEY) {
    console.warn('  [SKIP] No FIRECRAWL_API_KEY set');
    return null;
  }

  const response = await fetch(`${FIRECRAWL_BASE_URL}/extract`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${FIRECRAWL_API_KEY}`,
    },
    body: JSON.stringify({
      urls: [url],
      prompt,
      schema,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    console.error(`  [ERROR] Extract failed: ${response.status} ${text}`);
    return null;
  }

  const data = await response.json();
  return data.data || null;
}

// ---------------------------------------------------------------------------
// GitHub API helper (optional, for star count etc.)
// ---------------------------------------------------------------------------

interface GitHubRepoInfo {
  stars: number;
  forks: number;
  openIssues: number;
  lastPush: string;
  license: string | null;
  archived: boolean;
  language: string | null;
}

async function fetchGitHubStats(repoUrl: string): Promise<GitHubRepoInfo | null> {
  const match = repoUrl.match(/github\.com\/([^/]+)\/([^/]+)/);
  if (!match) return null;

  const [, owner, repo] = match;
  const apiUrl = `https://api.github.com/repos/${owner}/${repo}`;

  try {
    const response = await fetch(apiUrl, {
      headers: {
        Accept: 'application/vnd.github.v3+json',
        ...(process.env.GITHUB_TOKEN
          ? { Authorization: `token ${process.env.GITHUB_TOKEN}` }
          : {}),
      },
    });

    if (!response.ok) return null;

    const data = await response.json();
    return {
      stars: data.stargazers_count,
      forks: data.forks_count,
      openIssues: data.open_issues_count,
      lastPush: data.pushed_at,
      license: data.license?.spdx_id || null,
      archived: data.archived,
      language: data.language,
    };
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Docker Hub helper (optional, for pull count)
// ---------------------------------------------------------------------------

async function fetchDockerHubPulls(image: string): Promise<number | null> {
  // Parse image name: "user/repo" or "library/repo"
  const parts = image.split('/');
  const namespace = parts.length === 1 ? 'library' : parts[0];
  const repo = parts.length === 1 ? parts[0] : parts[1];

  try {
    const response = await fetch(
      `https://hub.docker.com/v2/repositories/${namespace}/${repo}/`
    );
    if (!response.ok) return null;

    const data = await response.json();
    return data.pull_count || null;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Enrichment pipeline
// ---------------------------------------------------------------------------

async function enrichTool(tool: {
  id: string;
  name: string;
  displayName: string;
  homepageUrl: string | null;
  sourceUrl: string | null;
  image: string;
}): Promise<void> {
  console.log(`\n--- Enriching: ${tool.displayName} (${tool.name}) ---`);

  const updates: any = {};

  // Step 1: GitHub stats (if source URL available)
  if (tool.sourceUrl && tool.sourceUrl.includes('github.com')) {
    console.log('  Fetching GitHub stats...');
    const ghStats = await fetchGitHubStats(tool.sourceUrl);
    if (ghStats) {
      updates.githubStars = ghStats.stars;
      updates.isActiveMaintained = !ghStats.archived;
      updates.licenseType = ghStats.license || undefined;
      updates.lastReleaseDate = ghStats.lastPush ? new Date(ghStats.lastPush) : undefined;
      console.log(`    Stars: ${ghStats.stars}, Archived: ${ghStats.archived}`);
    }
  }

  // Step 2: Docker Hub pull count
  if (tool.image && tool.image !== 'unknown') {
    console.log('  Fetching Docker Hub stats...');
    const pulls = await fetchDockerHubPulls(tool.image);
    if (pulls !== null) {
      updates.dockerPulls = pulls;
      console.log(`    Pulls: ${pulls.toLocaleString()}`);
    }
  }

  // Step 3: AI extraction via Firecrawl (if homepage available)
  if (tool.homepageUrl) {
    console.log('  Running AI extraction...');
    const extraction = await firecrawlExtract(
      tool.homepageUrl,
      `Extract detailed information about the self-hosted tool "${tool.displayName}". Focus on: Docker setup, features, resource requirements, architecture compatibility, and community health.`,
      {
        type: 'object',
        properties: {
          description: { type: 'string', description: 'One-paragraph tool description' },
          features: {
            type: 'array',
            items: { type: 'string' },
            description: 'Key features list',
          },
          pros: {
            type: 'array',
            items: { type: 'string' },
            description: 'Advantages of this tool',
          },
          cons: {
            type: 'array',
            items: { type: 'string' },
            description: 'Disadvantages or limitations',
          },
          supportsArm: { type: 'boolean', description: 'Supports ARM64/aarch64' },
          hasWebUI: { type: 'boolean', description: 'Has a web user interface' },
          setupComplexity: {
            type: 'string',
            enum: ['simple', 'moderate', 'complex'],
          },
        },
      }
    );

    if (extraction) {
      const ex = Array.isArray(extraction) ? extraction[0] : extraction;
      updates.aiSummary = ex.description || undefined;
      updates.aiPros = ex.pros || undefined;
      updates.aiCons = ex.cons || undefined;
      updates.aiQualityScore = calculateQualityScore(ex, updates);
      updates.aiEnrichedAt = new Date();
      updates.supportsArm = ex.supportsArm ?? updates.supportsArm;
      updates.scrapedData = ex;

      console.log(`    AI Summary: ${(ex.description || '').substring(0, 100)}...`);
      console.log(`    Quality Score: ${updates.aiQualityScore}/100`);
    }
  }

  // Step 4: Apply updates
  if (Object.keys(updates).length > 0) {
    await prisma.tool.update({
      where: { id: tool.id },
      data: updates,
    });
    console.log(`  Updated ${Object.keys(updates).length} fields`);
  } else {
    console.log('  No updates to apply');
  }
}

/**
 * Calculate a quality score (0-100) based on available data.
 * Weighted scoring:
 *   - GitHub stars (0-20)
 *   - Docker pulls (0-15)
 *   - Active maintenance (0-15)
 *   - ARM support (0-10)
 *   - Web UI (0-10)
 *   - License (0-10)
 *   - Description quality (0-10)
 *   - Setup simplicity (0-10)
 */
function calculateQualityScore(extraction: any, updates: any): number {
  let score = 0;

  // GitHub stars
  const stars = updates.githubStars || 0;
  if (stars >= 10000) score += 20;
  else if (stars >= 5000) score += 16;
  else if (stars >= 1000) score += 12;
  else if (stars >= 500) score += 8;
  else if (stars >= 100) score += 4;

  // Docker pulls
  const pulls = updates.dockerPulls || 0;
  if (pulls >= 10000000) score += 15;
  else if (pulls >= 1000000) score += 12;
  else if (pulls >= 100000) score += 8;
  else if (pulls >= 10000) score += 4;

  // Active maintenance
  if (updates.isActiveMaintained) score += 15;

  // ARM support
  if (extraction.supportsArm) score += 10;

  // Web UI
  if (extraction.hasWebUI) score += 10;

  // License (open source)
  if (updates.licenseType && updates.licenseType !== 'NOASSERTION') score += 10;

  // Description quality
  if (extraction.description && extraction.description.length > 50) score += 10;

  // Setup simplicity
  if (extraction.setupComplexity === 'simple') score += 10;
  else if (extraction.setupComplexity === 'moderate') score += 5;

  return Math.min(100, score);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const arg = process.argv[2];

  console.log('='.repeat(60));
  console.log('Tool Enrichment - kombify-admin');
  console.log('='.repeat(60));

  let tools;
  if (arg === '--discovered') {
    tools = await prisma.tool.findMany({
      where: { lifecycleState: LifecycleState.DISCOVERED },
    });
    console.log(`Enriching ${tools.length} DISCOVERED tools`);
  } else if (arg === '--all') {
    tools = await prisma.tool.findMany();
    console.log(`Enriching all ${tools.length} tools`);
  } else if (arg && !arg.startsWith('--')) {
    tools = await prisma.tool.findMany({
      where: { name: arg },
    });
    console.log(`Enriching tool: ${arg}`);
  } else {
    // Default: enrich tools that haven't been enriched yet
    tools = await prisma.tool.findMany({
      where: { aiEnrichedAt: null },
    });
    console.log(`Enriching ${tools.length} un-enriched tools`);
  }

  if (tools.length === 0) {
    console.log('No tools to enrich.');
    return;
  }

  for (const tool of tools) {
    try {
      await enrichTool(tool);
    } catch (error) {
      console.error(`Error enriching ${tool.name}:`, error);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('Enrichment complete!');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Review enriched data: npx prisma studio');
  console.log('  2. Evaluate tools: npx ts-node scripts/tool-evaluate.ts');
}

main()
  .catch((e) => {
    console.error('Enrichment failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

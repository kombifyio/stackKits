/**
 * Tool Deduplication Utilities
 *
 * Provides normalized name computation and duplicate detection.
 * Based on old admin's tool-discovery-architecture.md:
 *   - normalizedName: lowercase, trimmed, no special chars
 *   - canonicalRepoUrl: GitHub URL normalization
 *
 * Usage:
 *   import { normalizeToolName, normalizeRepoUrl, findDuplicates } from './deduplication';
 *
 *   const norm = normalizeToolName("Nginx Proxy Manager");  // "nginx-proxy-manager"
 *   const repo = normalizeRepoUrl("https://github.com/portainer/portainer.git");
 *   const dupe = await findDuplicates(prisma, { name, githubUrl, homepageUrl });
 */

import { PrismaClient, Tool } from '@prisma/client';

// ---------------------------------------------------------------------------
// Name Normalization
// ---------------------------------------------------------------------------

/**
 * Normalize a tool name for deduplication.
 *
 * Rules:
 *   1. Lowercase
 *   2. Replace special characters and spaces with hyphens
 *   3. Remove leading/trailing hyphens
 *   4. Collapse multiple hyphens
 *   5. Remove common prefixes/suffixes: "self-hosted-", "-server", etc.
 *
 * Examples:
 *   "Nginx Proxy Manager"  -> "nginx-proxy-manager"
 *   "Self-Hosted Portainer" -> "portainer"
 *   "Gitea Server"          -> "gitea"
 *   "Home-Assistant"        -> "home-assistant"
 */
export function normalizeToolName(name: string): string {
  if (!name) return '';

  let normalized = name
    .toLowerCase()
    .trim()
    // Replace special chars/spaces with hyphens
    .replace(/[^a-z0-9]+/g, '-')
    // Remove leading/trailing hyphens
    .replace(/^-+|-+$/g, '')
    // Collapse multiple hyphens
    .replace(/-+/g, '-');

  // Remove common prefixes
  const prefixes = ['self-hosted-', 'selfhosted-', 'docker-', 'my-'];
  for (const prefix of prefixes) {
    if (normalized.startsWith(prefix)) {
      normalized = normalized.slice(prefix.length);
    }
  }

  // Remove common suffixes
  const suffixes = ['-server', '-app', '-ui', '-web', '-docker'];
  for (const suffix of suffixes) {
    if (normalized.endsWith(suffix)) {
      normalized = normalized.slice(0, -suffix.length);
    }
  }

  return normalized;
}

// ---------------------------------------------------------------------------
// Repository URL Normalization
// ---------------------------------------------------------------------------

/**
 * Normalize a GitHub repository URL to canonical form.
 *
 * Rules:
 *   1. Extract owner/repo from any GitHub URL format
 *   2. Remove .git suffix
 *   3. Lowercase
 *   4. Standard format: https://github.com/{owner}/{repo}
 *
 * Examples:
 *   "https://github.com/Foo/Bar.git"     -> "https://github.com/foo/bar"
 *   "git@github.com:Foo/Bar.git"          -> "https://github.com/foo/bar"
 *   "https://github.com/Foo/Bar/issues"   -> "https://github.com/foo/bar"
 *   "https://gitlab.com/foo/bar"          -> null (not GitHub)
 */
export function normalizeRepoUrl(url: string | null | undefined): string | null {
  if (!url) return null;

  // Handle git@ format
  if (url.startsWith('git@github.com:')) {
    const match = url.match(/git@github\.com:([^/]+)\/([^/.]+)/);
    if (match) {
      return `https://github.com/${match[1].toLowerCase()}/${match[2].toLowerCase()}`;
    }
    return null;
  }

  // Handle https:// format
  const httpsMatch = url.match(
    /https?:\/\/github\.com\/([a-zA-Z0-9_.-]+)\/([a-zA-Z0-9_.-]+)/
  );
  if (httpsMatch) {
    const owner = httpsMatch[1].toLowerCase();
    const repo = httpsMatch[2].toLowerCase().replace(/\.git$/, '');
    return `https://github.com/${owner}/${repo}`;
  }

  return null;
}

// ---------------------------------------------------------------------------
// Duplicate Detection
// ---------------------------------------------------------------------------

export interface DeduplicationInput {
  name?: string | null;
  githubUrl?: string | null;
  homepageUrl?: string | null;
  dockerImage?: string | null;
}

export interface DuplicationResult {
  isDuplicate: boolean;
  matchedTool: Tool | null;
  matchReason: 'normalizedName' | 'canonicalRepoUrl' | 'homepageUrl' | 'dockerImage' | null;
  normalizedName: string | null;
  canonicalRepoUrl: string | null;
}

/**
 * Check if a tool is a duplicate of an existing tool.
 *
 * Matching priority:
 *   1. canonicalRepoUrl (GitHub URL) - strongest match
 *   2. normalizedName - name-based match
 *   3. homepageUrl - exact URL match
 *   4. dockerImage - Docker image match (if available)
 *
 * Returns matched tool and reason if duplicate found.
 */
export async function findDuplicates(
  prisma: PrismaClient,
  input: DeduplicationInput
): Promise<DuplicationResult> {
  const normalizedName = input.name ? normalizeToolName(input.name) : null;
  const canonicalRepoUrl = normalizeRepoUrl(input.githubUrl);

  // Check by canonical repo URL first (strongest match)
  if (canonicalRepoUrl) {
    const byRepo = await prisma.tool.findFirst({
      where: { canonicalRepoUrl },
    });
    if (byRepo) {
      return {
        isDuplicate: true,
        matchedTool: byRepo,
        matchReason: 'canonicalRepoUrl',
        normalizedName,
        canonicalRepoUrl,
      };
    }
  }

  // Check by normalized name
  if (normalizedName) {
    const byName = await prisma.tool.findFirst({
      where: { normalizedName },
    });
    if (byName) {
      return {
        isDuplicate: true,
        matchedTool: byName,
        matchReason: 'normalizedName',
        normalizedName,
        canonicalRepoUrl,
      };
    }
  }

  // Check by exact homepage URL
  if (input.homepageUrl) {
    const byHomepage = await prisma.tool.findFirst({
      where: { homepageUrl: input.homepageUrl },
    });
    if (byHomepage) {
      return {
        isDuplicate: true,
        matchedTool: byHomepage,
        matchReason: 'homepageUrl',
        normalizedName,
        canonicalRepoUrl,
      };
    }
  }

  // Check by Docker image
  if (input.dockerImage) {
    const byDocker = await prisma.tool.findFirst({
      where: { image: input.dockerImage },
    });
    if (byDocker) {
      return {
        isDuplicate: true,
        matchedTool: byDocker,
        matchReason: 'dockerImage',
        normalizedName,
        canonicalRepoUrl,
      };
    }
  }

  // No duplicate found
  return {
    isDuplicate: false,
    matchedTool: null,
    matchReason: null,
    normalizedName,
    canonicalRepoUrl,
  };
}

/**
 * Populate deduplication fields for a new tool.
 * Call this before creating/updating a tool to ensure fields are set.
 */
export function computeDeduplicationFields(input: DeduplicationInput): {
  normalizedName: string | null;
  canonicalRepoUrl: string | null;
} {
  return {
    normalizedName: input.name ? normalizeToolName(input.name) : null,
    canonicalRepoUrl: normalizeRepoUrl(input.githubUrl),
  };
}

// ---------------------------------------------------------------------------
// Batch Deduplication
// ---------------------------------------------------------------------------

/**
 * Deduplicate a batch of discovered tools.
 * Returns separate arrays for new tools and duplicates.
 */
export async function deduplicateBatch<T extends DeduplicationInput>(
  prisma: PrismaClient,
  tools: T[]
): Promise<{
  newTools: Array<T & { normalizedName: string | null; canonicalRepoUrl: string | null }>;
  duplicates: Array<{
    tool: T;
    matchedTool: Tool;
    matchReason: DuplicationResult['matchReason'];
  }>;
}> {
  const newTools: Array<T & { normalizedName: string | null; canonicalRepoUrl: string | null }> = [];
  const duplicates: Array<{
    tool: T;
    matchedTool: Tool;
    matchReason: DuplicationResult['matchReason'];
  }> = [];

  // Build a set of normalized names in this batch to detect in-batch duplicates
  const seenNormalizedNames = new Set<string>();
  const seenRepoUrls = new Set<string>();

  for (const tool of tools) {
    const result = await findDuplicates(prisma, tool);

    if (result.isDuplicate && result.matchedTool) {
      duplicates.push({
        tool,
        matchedTool: result.matchedTool,
        matchReason: result.matchReason,
      });
      continue;
    }

    // Check for in-batch duplicates
    if (result.normalizedName && seenNormalizedNames.has(result.normalizedName)) {
      console.log(`  [SKIP] In-batch duplicate (name): ${tool.name}`);
      continue;
    }
    if (result.canonicalRepoUrl && seenRepoUrls.has(result.canonicalRepoUrl)) {
      console.log(`  [SKIP] In-batch duplicate (repo): ${tool.name}`);
      continue;
    }

    // Track this tool
    if (result.normalizedName) seenNormalizedNames.add(result.normalizedName);
    if (result.canonicalRepoUrl) seenRepoUrls.add(result.canonicalRepoUrl);

    newTools.push({
      ...tool,
      normalizedName: result.normalizedName,
      canonicalRepoUrl: result.canonicalRepoUrl,
    });
  }

  return { newTools, duplicates };
}

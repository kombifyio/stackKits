/**
 * Tool Version Check Script
 *
 * Checks all approved tools for new versions via GitHub releases
 * and Docker Hub tags. Creates ToolVersion entries for tracking.
 *
 * Usage:
 *   npx ts-node scripts/tool-version-check.ts [tool-name]
 *   npx ts-node scripts/tool-version-check.ts --all
 *
 * Environment:
 *   GITHUB_TOKEN  - GitHub personal access token (optional, increases rate limit)
 *   DATABASE_URL  - PostgreSQL connection string
 */

import {
  PrismaClient,
  LifecycleState,
  JobType,
  JobStatus,
} from '@prisma/client';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// GitHub API
// ---------------------------------------------------------------------------

interface GitHubRelease {
  tag_name: string;
  name: string;
  published_at: string;
  prerelease: boolean;
  html_url: string;
  body: string;
}

async function fetchLatestRelease(repoUrl: string): Promise<GitHubRelease | null> {
  const match = repoUrl.match(/github\.com\/([^/]+)\/([^/]+)/);
  if (!match) return null;

  const [, owner, repo] = match;

  try {
    const response = await fetch(
      `https://api.github.com/repos/${owner}/${repo}/releases/latest`,
      {
        headers: {
          Accept: 'application/vnd.github.v3+json',
          ...(process.env.GITHUB_TOKEN
            ? { Authorization: `token ${process.env.GITHUB_TOKEN}` }
            : {}),
        },
      }
    );

    if (!response.ok) return null;
    return await response.json();
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Docker Hub API
// ---------------------------------------------------------------------------

interface DockerTag {
  name: string;
  last_updated: string;
  digest: string;
  images: Array<{
    architecture: string;
    os: string;
  }>;
}

async function fetchDockerTags(
  image: string,
  limit = 10
): Promise<DockerTag[]> {
  const parts = image.split('/');
  const namespace = parts.length === 1 ? 'library' : parts[0];
  const repo = parts.length === 1 ? parts[0] : parts.slice(1).join('/');

  try {
    const response = await fetch(
      `https://hub.docker.com/v2/repositories/${namespace}/${repo}/tags/?page_size=${limit}&ordering=last_updated`
    );
    if (!response.ok) return [];

    const data = await response.json();
    return data.results || [];
  } catch {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Semver comparison helper
// ---------------------------------------------------------------------------

function parseVersion(v: string): number[] {
  return v
    .replace(/^v/i, '')
    .split('.')
    .map((n) => parseInt(n, 10) || 0);
}

function isNewerVersion(current: string, candidate: string): boolean {
  const c = parseVersion(current);
  const n = parseVersion(candidate);
  for (let i = 0; i < Math.max(c.length, n.length); i++) {
    if ((n[i] || 0) > (c[i] || 0)) return true;
    if ((n[i] || 0) < (c[i] || 0)) return false;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Version check pipeline
// ---------------------------------------------------------------------------

async function checkToolVersion(tool: {
  id: string;
  name: string;
  displayName: string;
  image: string;
  defaultTag: string;
  sourceUrl: string | null;
  latestVersion: string | null;
}): Promise<{ hasUpdate: boolean; newVersion?: string }> {
  console.log(`\n--- Checking: ${tool.displayName} (${tool.name}) ---`);

  const currentVersion = tool.latestVersion || tool.defaultTag;

  // Step 1: GitHub releases
  if (tool.sourceUrl && tool.sourceUrl.includes('github.com')) {
    console.log('  Checking GitHub releases...');
    const release = await fetchLatestRelease(tool.sourceUrl);

    if (release && !release.prerelease) {
      const ghVersion = release.tag_name.replace(/^v/i, '');
      console.log(`    Latest GitHub: ${ghVersion} (current: ${currentVersion})`);

      if (currentVersion && isNewerVersion(currentVersion, ghVersion)) {
        console.log(`    [UPDATE] New version available: ${ghVersion}`);

        // Create version entry
        await prisma.toolVersion.create({
          data: {
            toolId: tool.id,
            version: ghVersion,
            releaseDate: new Date(release.published_at),
            releaseNotesUrl: release.html_url,
            changelog: release.body?.substring(0, 5000),
            isLatest: true,
          },
        });

        // Mark previous as not latest
        await prisma.toolVersion.updateMany({
          where: {
            toolId: tool.id,
            version: { not: ghVersion },
          },
          data: { isLatest: false },
        });

        // Update tool
        await prisma.tool.update({
          where: { id: tool.id },
          data: {
            latestVersion: ghVersion,
            lastReleaseDate: new Date(release.published_at),
          },
        });

        return { hasUpdate: true, newVersion: ghVersion };
      } else {
        console.log('    Up to date');
      }
    }
  }

  // Step 2: Docker Hub tags
  if (tool.image && tool.image !== 'unknown') {
    console.log('  Checking Docker Hub tags...');
    const tags = await fetchDockerTags(tool.image);

    // Filter for version-like tags (exclude "latest", "stable", etc.)
    const versionTags = tags.filter((t) => /^\d+\.\d+/.test(t.name));

    if (versionTags.length > 0) {
      const latestDockerTag = versionTags[0];
      console.log(`    Latest Docker tag: ${latestDockerTag.name}`);

      // Check ARM support from image architectures
      const architectures = latestDockerTag.images?.map((i) => i.architecture) || [];
      const supportsArm = architectures.includes('arm64') || architectures.includes('arm');
      const supportsX86 = architectures.includes('amd64');

      if (supportsArm || supportsX86) {
        await prisma.tool.update({
          where: { id: tool.id },
          data: { supportsArm, supportsX86 },
        });
        console.log(
          `    Architectures: ${architectures.join(', ')} (ARM: ${supportsArm}, x86: ${supportsX86})`
        );
      }
    }
  }

  return { hasUpdate: false };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const arg = process.argv[2];

  console.log('='.repeat(60));
  console.log('Tool Version Check - kombify-admin');
  console.log('='.repeat(60));

  let tools;
  if (arg === '--all') {
    tools = await prisma.tool.findMany({
      where: {
        lifecycleState: {
          in: [LifecycleState.APPROVED, LifecycleState.EVALUATED],
        },
      },
    });
  } else if (arg && !arg.startsWith('--')) {
    tools = await prisma.tool.findMany({
      where: { name: arg },
    });
  } else {
    // Default: only approved tools
    tools = await prisma.tool.findMany({
      where: { lifecycleState: LifecycleState.APPROVED },
    });
  }

  console.log(`Checking ${tools.length} tools for updates`);

  // Create job
  const job = await prisma.discoveryJob.create({
    data: {
      jobType: JobType.VERSION_CHECK,
      status: JobStatus.RUNNING,
      startedAt: new Date(),
    },
  });

  let updatesFound = 0;

  for (const tool of tools) {
    try {
      const result = await checkToolVersion(tool);
      if (result.hasUpdate) updatesFound++;
    } catch (error) {
      console.error(`Error checking ${tool.name}:`, error);
    }
  }

  // Update job
  await prisma.discoveryJob.update({
    where: { id: job.id },
    data: {
      status: JobStatus.COMPLETED,
      completedAt: new Date(),
      toolsUpdated: updatesFound,
      durationMs: Date.now() - job.startedAt!.getTime(),
    },
  });

  console.log('\n' + '='.repeat(60));
  console.log(`Version check complete!`);
  console.log(`  Tools checked: ${tools.length}`);
  console.log(`  Updates found: ${updatesFound}`);
}

main()
  .catch((e) => {
    console.error('Version check failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

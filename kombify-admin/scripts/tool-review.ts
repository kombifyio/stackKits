/**
 * Tool Review Script
 *
 * Interactive review of DISCOVERED tools. Lists unreviewed tools and
 * allows batch operations (approve, reject, defer).
 *
 * Usage:
 *   npx ts-node scripts/tool-review.ts              # List all discovered tools
 *   npx ts-node scripts/tool-review.ts --summary     # Summary statistics
 *   npx ts-node scripts/tool-review.ts approve <name> # Approve a tool
 *   npx ts-node scripts/tool-review.ts reject <name>  # Reject a tool
 *   npx ts-node scripts/tool-review.ts defer <name>   # Defer for later review
 */

import {
  PrismaClient,
  LifecycleState,
} from '@prisma/client';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Display helpers
// ---------------------------------------------------------------------------

function formatScore(score: number | null): string {
  if (score === null) return '–';
  if (score >= 80) return `\x1b[32m${score}\x1b[0m`; // Green
  if (score >= 50) return `\x1b[33m${score}\x1b[0m`; // Yellow
  return `\x1b[31m${score}\x1b[0m`; // Red
}

function formatState(state: LifecycleState): string {
  const colors: Record<string, string> = {
    DISCOVERED: '\x1b[36m', // Cyan
    EVALUATED: '\x1b[33m',  // Yellow
    APPROVED: '\x1b[32m',   // Green
    DEPRECATED: '\x1b[31m', // Red
    ARCHIVED: '\x1b[90m',   // Gray
    DRAFT: '\x1b[37m',      // White
  };
  return `${colors[state] || ''}${state}\x1b[0m`;
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

async function listDiscovered(): Promise<void> {
  const tools = await prisma.tool.findMany({
    where: { lifecycleState: LifecycleState.DISCOVERED },
    orderBy: [{ category: 'asc' }, { aiQualityScore: 'desc' }],
  });

  if (tools.length === 0) {
    console.log('No discovered tools awaiting review.');
    return;
  }

  console.log(`\n${'Name'.padEnd(25)} ${'Category'.padEnd(18)} ${'Score'.padEnd(8)} ${'Stars'.padEnd(10)} ${'Source'.padEnd(15)} URL`);
  console.log('-'.repeat(120));

  for (const tool of tools) {
    console.log(
      `${tool.displayName.padEnd(25).substring(0, 25)} ` +
      `${tool.category.padEnd(18)} ` +
      `${formatScore(tool.aiQualityScore).padEnd(16)} ` +
      `${(tool.githubStars?.toLocaleString() || '–').padEnd(10)} ` +
      `${(tool.discoverySource || 'MANUAL').padEnd(15)} ` +
      `${tool.homepageUrl || ''}`
    );
  }

  console.log(`\nTotal: ${tools.length} tools awaiting review`);
}

async function showSummary(): Promise<void> {
  const counts = await prisma.tool.groupBy({
    by: ['lifecycleState'],
    _count: true,
  });

  const byCategory = await prisma.tool.groupBy({
    by: ['category'],
    _count: true,
    where: { lifecycleState: LifecycleState.DISCOVERED },
  });

  console.log('\n--- Tool Inventory Summary ---\n');
  for (const { lifecycleState, _count } of counts) {
    console.log(`  ${formatState(lifecycleState)}: ${_count}`);
  }

  if (byCategory.length > 0) {
    console.log('\n--- Discovered by Category ---\n');
    for (const { category, _count } of byCategory) {
      console.log(`  ${category}: ${_count}`);
    }
  }

  // Recent discovery jobs
  const recentJobs = await prisma.discoveryJob.findMany({
    orderBy: { createdAt: 'desc' },
    take: 5,
  });

  if (recentJobs.length > 0) {
    console.log('\n--- Recent Discovery Jobs ---\n');
    for (const job of recentJobs) {
      console.log(
        `  ${job.createdAt.toISOString().split('T')[0]} ` +
        `${job.jobType.padEnd(20)} ` +
        `${job.status.padEnd(12)} ` +
        `discovered=${job.toolsDiscovered} updated=${job.toolsUpdated}`
      );
    }
  }
}

async function changeTool(
  action: 'approve' | 'reject' | 'defer',
  toolName: string
): Promise<void> {
  const tool = await prisma.tool.findUnique({
    where: { name: toolName },
  });

  if (!tool) {
    console.error(`Tool not found: ${toolName}`);
    process.exit(1);
  }

  const stateMap: Record<string, LifecycleState> = {
    approve: LifecycleState.EVALUATED,
    reject: LifecycleState.ARCHIVED,
    defer: LifecycleState.DRAFT,
  };

  const newState = stateMap[action];

  await prisma.tool.update({
    where: { name: toolName },
    data: { lifecycleState: newState },
  });

  console.log(
    `${tool.displayName}: ${formatState(tool.lifecycleState)} → ${formatState(newState)}`
  );

  // Log the action
  await prisma.auditLog.create({
    data: {
      action: `tool.${action}`,
      entityType: 'Tool',
      entityId: tool.id,
      details: {
        toolName: tool.name,
        previousState: tool.lifecycleState,
        newState,
      },
      performedBy: 'admin-cli',
    },
  });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const action = process.argv[2];
  const target = process.argv[3];

  console.log('='.repeat(60));
  console.log('Tool Review - kombify-admin');
  console.log('='.repeat(60));

  if (action === '--summary') {
    await showSummary();
  } else if (['approve', 'reject', 'defer'].includes(action) && target) {
    await changeTool(action as 'approve' | 'reject' | 'defer', target);
  } else {
    await listDiscovered();
  }
}

main()
  .catch((e) => {
    console.error('Review failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

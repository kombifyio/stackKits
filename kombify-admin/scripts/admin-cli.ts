#!/usr/bin/env npx ts-node
/**
 * Admin CLI - Add-On and Context Management
 *
 * Provides commands for managing Add-Ons, NodeContexts, and tool associations.
 *
 * Usage:
 *   npx ts-node scripts/admin-cli.ts <command> [options]
 *
 * Commands:
 *   addon list                      - List all add-ons
 *   addon show <name>               - Show add-on details
 *   addon create <name> [options]   - Create a new add-on
 *
 *   context list                    - List all node contexts
 *   context show <type>             - Show context defaults
 *   context create <type>           - Create context with defaults
 *
 *   tool list [--layer] [--category] - List tools
 *   tool assign <tool> <kit>         - Assign tool to StackKit
 *   tool unassign <tool> <kit>       - Remove tool from StackKit
 *
 * Examples:
 *   npx ts-node scripts/admin-cli.ts addon list
 *   npx ts-node scripts/admin-cli.ts addon create vpn --category networking
 *   npx ts-node scripts/admin-cli.ts context show CLOUD
 */

import {
  PrismaClient,
  LayerType,
  NodeContext,
  LifecycleState,
  ArchitecturePattern,
} from '@prisma/client';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Argument Parsing
// ---------------------------------------------------------------------------

interface ParsedArgs {
  command: string;
  subcommand: string;
  args: string[];
  flags: Record<string, string | boolean>;
}

function parseArgs(argv: string[]): ParsedArgs {
  const args = argv.slice(2);
  const command = args[0] || 'help';
  const subcommand = args[1] || '';
  const positionalArgs: string[] = [];
  const flags: Record<string, string | boolean> = {};

  for (let i = 2; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--')) {
      const [key, value] = arg.slice(2).split('=');
      flags[key] = value || true;
    } else {
      positionalArgs.push(arg);
    }
  }

  return { command, subcommand, args: positionalArgs, flags };
}

// ---------------------------------------------------------------------------
// Add-On Commands
// ---------------------------------------------------------------------------

async function addonList(): Promise<void> {
  const addons = await prisma.addOn.findMany({
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  });

  console.log('\nAdd-Ons:\n');
  console.log('Name'.padEnd(20) + 'Category'.padEnd(15) + 'Version'.padEnd(10) + 'State'.padEnd(12) + 'Compatible Kits');
  console.log('-'.repeat(80));

  for (const addon of addons) {
    console.log(
      addon.name.padEnd(20) +
      addon.category.padEnd(15) +
      addon.version.padEnd(10) +
      addon.lifecycleState.padEnd(12) +
      addon.compatibleKits.join(', ')
    );
  }
  console.log(`\nTotal: ${addons.length} add-ons`);
}

async function addonShow(name: string): Promise<void> {
  const addon = await prisma.addOn.findUnique({
    where: { name },
  });

  if (!addon) {
    console.error(`Add-on not found: ${name}`);
    process.exit(1);
  }

  console.log('\nAdd-On Details:\n');
  console.log(`Name:        ${addon.name}`);
  console.log(`Display:     ${addon.displayName}`);
  console.log(`Category:    ${addon.category}`);
  console.log(`Version:     ${addon.version}`);
  console.log(`State:       ${addon.lifecycleState}`);
  console.log(`Kits:        ${addon.compatibleKits.join(', ')}`);
  console.log(`Contexts:    ${addon.compatibleContexts.join(', ')}`);
  console.log(`Description: ${addon.description || 'N/A'}`);
  console.log(`Tools:       ${addon.includedTools.join(', ') || 'None'}`);
  if (addon.dependsOn.length > 0) {
    console.log(`Depends On:  ${addon.dependsOn.join(', ')}`);
  }
  if (addon.exampleConfig) {
    console.log(`\nExample Config:\n${addon.exampleConfig}`);
  }
}

async function addonCreate(
  name: string,
  flags: Record<string, string | boolean>
): Promise<void> {
  const displayName = (flags.display as string) || name;
  const category = (flags.category as string) || 'general';
  const description = flags.description as string;
  const version = (flags.version as string) || '1.0.0';
  const tools = flags.tools ? (flags.tools as string).split(',') : [];
  
  // Parse compatible kits
  let compatibleKits: ArchitecturePattern[] = [ArchitecturePattern.BASE, ArchitecturePattern.MODERN, ArchitecturePattern.HA];
  if (flags.kits) {
    compatibleKits = (flags.kits as string).split(',').map(k => k.toUpperCase() as ArchitecturePattern);
  }

  const addon = await prisma.addOn.create({
    data: {
      name,
      displayName,
      category,
      description,
      version,
      includedTools: tools,
      compatibleKits,
      lifecycleState: LifecycleState.DRAFT,
    },
  });

  console.log(`\n✓ Created add-on: ${addon.name}`);
  console.log(`  Category: ${addon.category}`);
  console.log(`  Version: ${addon.version}`);
  console.log(`  Compatible Kits: ${addon.compatibleKits.join(', ')}`);
}

// ---------------------------------------------------------------------------
// Context Commands
// ---------------------------------------------------------------------------

async function contextList(): Promise<void> {
  const contexts = await prisma.contextDefaults.findMany({
    orderBy: { context: 'asc' },
  });

  console.log('\nNode Context Defaults:\n');
  console.log('Context'.padEnd(12) + 'Display Name'.padEnd(20) + 'PAAS'.padEnd(12) + 'TLS Mode'.padEnd(15) + 'Memory Limit');
  console.log('-'.repeat(80));

  for (const ctx of contexts) {
    console.log(
      ctx.context.padEnd(12) +
      ctx.displayName.padEnd(20) +
      (ctx.defaultPaas || 'N/A').padEnd(12) +
      (ctx.defaultTlsMode || 'N/A').padEnd(15) +
      (ctx.defaultMemoryLimitMB ? `${ctx.defaultMemoryLimitMB}MB` : 'N/A')
    );
  }
  console.log(`\nTotal: ${contexts.length} context configurations`);
}

async function contextShow(contextType: string): Promise<void> {
  const nodeContext = contextType.toUpperCase() as NodeContext;
  const ctx = await prisma.contextDefaults.findUnique({
    where: { context: nodeContext },
  });

  if (!ctx) {
    console.log(`No defaults found for context: ${nodeContext}`);
    console.log(`\nAvailable contexts: LOCAL, CLOUD, HYBRID, AIRGAPPED`);
    return;
  }

  console.log(`\nDefaults for ${nodeContext}:\n`);
  console.log(`  Display Name:    ${ctx.displayName}`);
  console.log(`  Description:     ${ctx.description || 'N/A'}`);
  console.log(`  Default PAAS:    ${ctx.defaultPaas || 'N/A'}`);
  console.log(`  TLS Mode:        ${ctx.defaultTlsMode || 'N/A'}`);
  console.log(`  Compute Tier:    ${ctx.defaultComputeTier || 'N/A'}`);
  console.log(`  Memory Limit:    ${ctx.defaultMemoryLimitMB ? `${ctx.defaultMemoryLimitMB}MB` : 'N/A'}`);
  console.log(`  CPU Shares:      ${ctx.defaultCpuShares || 'N/A'}`);
  console.log(`  Storage Driver:  ${ctx.defaultStorageDriver || 'N/A'}`);
  console.log(`  DNS Strategy:    ${ctx.defaultDnsStrategy || 'N/A'}`);
  console.log(`  Backup Target:   ${ctx.defaultBackupTarget || 'N/A'}`);
  if (ctx.cueDefaults) {
    console.log(`\nCUE Defaults:\n${ctx.cueDefaults}`);
  }
}

async function contextCreate(
  contextType: string,
  flags: Record<string, string | boolean>
): Promise<void> {
  const nodeContext = contextType.toUpperCase() as NodeContext;
  const displayName = (flags.display as string) || contextType;
  const description = flags.description as string;

  const existing = await prisma.contextDefaults.findUnique({
    where: { context: nodeContext },
  });

  if (existing) {
    // Update existing
    await prisma.contextDefaults.update({
      where: { context: nodeContext },
      data: {
        displayName,
        description,
        defaultPaas: flags.paas as string,
        defaultTlsMode: flags.tls as string,
        defaultComputeTier: flags.tier as string,
        defaultMemoryLimitMB: flags.memory ? parseInt(flags.memory as string) : undefined,
        defaultCpuShares: flags.cpu ? parseInt(flags.cpu as string) : undefined,
        defaultStorageDriver: flags.storage as string,
        defaultDnsStrategy: flags.dns as string,
      },
    });
    console.log(`✓ Updated context: ${nodeContext}`);
  } else {
    await prisma.contextDefaults.create({
      data: {
        context: nodeContext,
        displayName,
        description,
        defaultPaas: flags.paas as string,
        defaultTlsMode: flags.tls as string,
        defaultComputeTier: flags.tier as string,
        defaultMemoryLimitMB: flags.memory ? parseInt(flags.memory as string) : undefined,
        defaultCpuShares: flags.cpu ? parseInt(flags.cpu as string) : undefined,
        defaultStorageDriver: flags.storage as string,
        defaultDnsStrategy: flags.dns as string,
      },
    });
    console.log(`✓ Created context: ${nodeContext}`);
  }
}

// ---------------------------------------------------------------------------
// Tool Commands
// ---------------------------------------------------------------------------

async function toolList(flags: Record<string, string | boolean>): Promise<void> {
  const where: any = {};
  if (flags.layer) where.layer = flags.layer;
  if (flags.category) where.category = flags.category;

  const tools = await prisma.tool.findMany({
    where,
    orderBy: [{ layer: 'asc' }, { category: 'asc' }, { name: 'asc' }],
    select: {
      name: true,
      displayName: true,
      layer: true,
      category: true,
      lifecycleState: true,
      image: true,
    },
  });

  console.log('\nTools:\n');
  console.log('Name'.padEnd(20) + 'Display'.padEnd(25) + 'Layer'.padEnd(15) + 'Category'.padEnd(20) + 'State');
  console.log('-'.repeat(100));

  for (const tool of tools) {
    console.log(
      tool.name.padEnd(20) +
      tool.displayName.substring(0, 23).padEnd(25) +
      tool.layer.padEnd(15) +
      tool.category.padEnd(20) +
      tool.lifecycleState
    );
  }
  console.log(`\nTotal: ${tools.length} tools`);
}

async function toolAssign(toolName: string, kitName: string): Promise<void> {
  const tool = await prisma.tool.findUnique({ where: { name: toolName } });
  if (!tool) {
    console.error(`Tool not found: ${toolName}`);
    process.exit(1);
  }

  const kit = await prisma.stackKit.findUnique({ where: { name: kitName } });
  if (!kit) {
    console.error(`StackKit not found: ${kitName}`);
    process.exit(1);
  }

  // Check if already assigned
  const existing = await prisma.stackKitTool.findFirst({
    where: { stackkitId: kit.id, toolId: tool.id },
  });

  if (existing) {
    console.log(`Tool ${toolName} is already assigned to ${kitName}`);
    return;
  }

  await prisma.stackKitTool.create({
    data: {
      stackkitId: kit.id,
      toolId: tool.id,
      isRequired: false,
    },
  });

  console.log(`✓ Assigned ${toolName} to ${kitName}`);
}

async function toolUnassign(toolName: string, kitName: string): Promise<void> {
  const tool = await prisma.tool.findUnique({ where: { name: toolName } });
  if (!tool) {
    console.error(`Tool not found: ${toolName}`);
    process.exit(1);
  }

  const kit = await prisma.stackKit.findUnique({ where: { name: kitName } });
  if (!kit) {
    console.error(`StackKit not found: ${kitName}`);
    process.exit(1);
  }

  const result = await prisma.stackKitTool.deleteMany({
    where: { stackkitId: kit.id, toolId: tool.id },
  });

  if (result.count > 0) {
    console.log(`✓ Unassigned ${toolName} from ${kitName}`);
  } else {
    console.log(`Tool ${toolName} was not assigned to ${kitName}`);
  }
}

// ---------------------------------------------------------------------------
// Help
// ---------------------------------------------------------------------------

function showHelp(): void {
  console.log(`
Admin CLI - Add-On and Context Management

Usage:
  npx ts-node scripts/admin-cli.ts <command> [options]

Commands:
  addon list                      List all add-ons
  addon show <name>               Show add-on details
  addon create <name> [options]   Create a new add-on
      --display=<name>            Display name
      --category=<category>       Category (observability, networking, etc.)
      --version=<ver>             Version (default: 1.0.0)
      --tools=<tool1,tool2>       Comma-separated tool names
      --kits=<BASE,MODERN,HA>     Compatible StackKits
      --description=<text>        Description

  context list                    List all node context defaults
  context show <type>             Show defaults for a context (LOCAL, CLOUD, etc.)
  context create <type> [opts]    Create/update context defaults
      --display=<name>            Display name
      --paas=<type>               Default PAAS provider
      --tls=<mode>                TLS mode
      --tier=<tier>               Compute tier
      --memory=<MB>               Memory limit in MB
      --cpu=<shares>              CPU shares
      --storage=<driver>          Storage driver
      --dns=<strategy>            DNS strategy
      --description=<text>        Description

  tool list [options]             List tools
      --layer=<layer>             Filter by layer
      --category=<category>       Filter by category
  tool assign <tool> <kit>        Assign tool to StackKit
  tool unassign <tool> <kit>      Remove tool from StackKit

Examples:
  npx ts-node scripts/admin-cli.ts addon list
  npx ts-node scripts/admin-cli.ts addon create monitoring --category=observability --tools=prometheus,grafana
  npx ts-node scripts/admin-cli.ts context show CLOUD
  npx ts-node scripts/admin-cli.ts context create LOCAL --paas=docker --tls=self-signed
  npx ts-node scripts/admin-cli.ts tool list --layer=PLATFORM
  npx ts-node scripts/admin-cli.ts tool assign traefik base-homelab
`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const { command, subcommand, args, flags } = parseArgs(process.argv);

  try {
    switch (command) {
      case 'addon':
        switch (subcommand) {
          case 'list':
            await addonList();
            break;
          case 'show':
            await addonShow(args[0]);
            break;
          case 'create':
            await addonCreate(args[0], flags);
            break;
          default:
            showHelp();
        }
        break;

      case 'context':
        switch (subcommand) {
          case 'list':
            await contextList();
            break;
          case 'show':
            await contextShow(args[0]);
            break;
          case 'create':
            await contextCreate(args[0], flags);
            break;
          default:
            showHelp();
        }
        break;

      case 'tool':
        switch (subcommand) {
          case 'list':
            await toolList(flags);
            break;
          case 'assign':
            await toolAssign(args[0], args[1]);
            break;
          case 'unassign':
            await toolUnassign(args[0], args[1]);
            break;
          default:
            showHelp();
        }
        break;

      case 'help':
      default:
        showHelp();
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : error);
    process.exit(1);
  }
}

main()
  .finally(() => prisma.$disconnect());

/**
 * CUE Generator Script
 *
 * Generates CUE validation files from the PostgreSQL database (source of truth).
 * This script is called by GitHub Actions on database changes.
 *
 * Usage:
 *   npx ts-node scripts/generate-cue.ts [target]
 *
 * Targets:
 *   all              - Generate all CUE files (default)
 *   validation-rules - Generate validation rules only
 *   settings         - Generate settings metadata only
 *   addons           - Generate add-on definitions only
 *   contexts         - Generate context defaults only
 *   tool-catalog     - Generate tool catalog only
 */

import { PrismaClient, LayerType, SettingType, LifecycleState, ArchitecturePattern, NodeContext } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

// Output directory for generated CUE files (relative to project root)
const OUTPUT_DIR = path.resolve(process.cwd(), '../base/generated');

/**
 * Ensure output directory exists
 */
function ensureOutputDir(): void {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }
}

/**
 * Convert LayerType enum to CUE layer string
 */
function layerToCue(layer: LayerType): string {
  switch (layer) {
    case LayerType.FOUNDATION:
      return '1';
    case LayerType.PLATFORM:
      return '2';
    case LayerType.APPLICATION:
      return '3';
    default:
      return 'unknown';
  }
}

/**
 * Escape string for CUE
 */
function escapeCueString(str: string): string {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
    .replace(/\t/g, '\\t');
}

/**
 * Generate validation rules CUE file
 */
async function generateValidationRules(): Promise<void> {
  console.log('Generating validation rules...');

  const rules = await prisma.validationRule.findMany({
    where: {
      lifecycleState: {
        in: [LifecycleState.APPROVED, LifecycleState.EVALUATED],
      },
    },
    orderBy: [{ layer: 'asc' }, { code: 'asc' }],
  });

  const header = `// =============================================================================
// GENERATED FILE - DO NOT EDIT DIRECTLY
// =============================================================================
// This file is auto-generated from the kombify-admin database.
// To modify validation rules, update the database and re-run the generator.
//
// Generated: ${new Date().toISOString()}
// Source: kombify-admin/prisma/seed.ts → ValidationRule table
// =============================================================================

package base
`;

  // Group rules by layer
  const rulesByLayer = {
    [LayerType.FOUNDATION]: rules.filter((r) => r.layer === LayerType.FOUNDATION),
    [LayerType.PLATFORM]: rules.filter((r) => r.layer === LayerType.PLATFORM),
    [LayerType.APPLICATION]: rules.filter((r) => r.layer === LayerType.APPLICATION),
  };

  let content = header;

  // Generate rule definitions
  content += `
// =============================================================================
// VALIDATION RULE DEFINITIONS
// =============================================================================

#ValidationRuleCode: ${rules.map((r) => `"${r.code}"`).join(' | ')}

#ValidationRuleSeverity: "error" | "warning" | "info"

#ValidationRule: {
  code:         #ValidationRuleCode
  layer:        "1" | "2" | "3"
  fieldPath:    string
  ruleType:     "required" | "type" | "constraint" | "custom"
  cueExpression: string
  errorMessage: string
  hint?:        string
  severity:     #ValidationRuleSeverity
}
`;

  // Generate rules registry
  content += `
// =============================================================================
// VALIDATION RULES REGISTRY
// =============================================================================

#ValidationRulesRegistry: {
`;

  // Layer 1 rules
  content += `  // Layer 1: Foundation Rules
  layer1: [\n`;
  for (const rule of rulesByLayer[LayerType.FOUNDATION]) {
    content += `    {
      code:          "${rule.code}"
      layer:         "${layerToCue(rule.layer)}"
      fieldPath:     "${escapeCueString(rule.fieldPath)}"
      ruleType:      "${rule.ruleType}"
      cueExpression: "${escapeCueString(rule.cueExpression)}"
      errorMessage:  "${escapeCueString(rule.errorMessage)}"
      ${rule.hint ? `hint:          "${escapeCueString(rule.hint)}"` : ''}
      severity:      "${rule.severity}"
    },
`;
  }
  content += `  ]

`;

  // Layer 2 rules
  content += `  // Layer 2: Platform Rules
  layer2: [\n`;
  for (const rule of rulesByLayer[LayerType.PLATFORM]) {
    content += `    {
      code:          "${rule.code}"
      layer:         "${layerToCue(rule.layer)}"
      fieldPath:     "${escapeCueString(rule.fieldPath)}"
      ruleType:      "${rule.ruleType}"
      cueExpression: "${escapeCueString(rule.cueExpression)}"
      errorMessage:  "${escapeCueString(rule.errorMessage)}"
      ${rule.hint ? `hint:          "${escapeCueString(rule.hint)}"` : ''}
      severity:      "${rule.severity}"
    },
`;
  }
  content += `  ]

`;

  // Layer 3 rules
  content += `  // Layer 3: Application Rules
  layer3: [\n`;
  for (const rule of rulesByLayer[LayerType.APPLICATION]) {
    content += `    {
      code:          "${rule.code}"
      layer:         "${layerToCue(rule.layer)}"
      fieldPath:     "${escapeCueString(rule.fieldPath)}"
      ruleType:      "${rule.ruleType}"
      cueExpression: "${escapeCueString(rule.cueExpression)}"
      errorMessage:  "${escapeCueString(rule.errorMessage)}"
      ${rule.hint ? `hint:          "${escapeCueString(rule.hint)}"` : ''}
      severity:      "${rule.severity}"
    },
`;
  }
  content += `  ]
}
`;

  // Write file
  const outputPath = path.join(OUTPUT_DIR, 'validation_rules.cue');
  fs.writeFileSync(outputPath, content);
  console.log(`  Written: ${outputPath} (${rules.length} rules)`);
}

/**
 * Generate settings metadata CUE file
 */
async function generateSettingsMetadata(): Promise<void> {
  console.log('Generating settings metadata...');

  const settings = await prisma.setting.findMany({
    orderBy: [{ layer: 'asc' }, { settingType: 'asc' }, { path: 'asc' }],
  });

  const header = `// =============================================================================
// GENERATED FILE - DO NOT EDIT DIRECTLY
// =============================================================================
// This file is auto-generated from the kombify-admin database.
// To modify settings classification, update the database and re-run the generator.
//
// Generated: ${new Date().toISOString()}
// Source: kombify-admin/prisma/seed.ts → Setting table
// =============================================================================

package base
`;

  let content = header;

  // Generate setting type definitions
  content += `
// =============================================================================
// SETTINGS TYPE DEFINITIONS
// =============================================================================

#SettingType: "perma" | "flexible"

#SettingClassification: {
  layer:             "1" | "2" | "3"
  path:              string
  name:              string
  settingType:       #SettingType
  description?:      string
  whyClassification?: string
  changeMethod?:     string
  defaultValue?:     _
  cueType?:          string
}
`;

  // Group by layer and type
  const permaByLayer = {
    [LayerType.FOUNDATION]: settings.filter(
      (s) => s.layer === LayerType.FOUNDATION && s.settingType === SettingType.PERMA
    ),
    [LayerType.PLATFORM]: settings.filter(
      (s) => s.layer === LayerType.PLATFORM && s.settingType === SettingType.PERMA
    ),
    [LayerType.APPLICATION]: settings.filter(
      (s) => s.layer === LayerType.APPLICATION && s.settingType === SettingType.PERMA
    ),
  };

  const flexibleByLayer = {
    [LayerType.FOUNDATION]: settings.filter(
      (s) => s.layer === LayerType.FOUNDATION && s.settingType === SettingType.FLEXIBLE
    ),
    [LayerType.PLATFORM]: settings.filter(
      (s) => s.layer === LayerType.PLATFORM && s.settingType === SettingType.FLEXIBLE
    ),
    [LayerType.APPLICATION]: settings.filter(
      (s) => s.layer === LayerType.APPLICATION && s.settingType === SettingType.FLEXIBLE
    ),
  };

  // Generate registry
  content += `
// =============================================================================
// SETTINGS CLASSIFICATION REGISTRY
// =============================================================================

#SettingsRegistry: {
  // Perma-settings: Immutable after deployment
  perma: {
`;

  // Layer 1 perma
  content += `    // Layer 1: Foundation
    layer1: [\n`;
  for (const setting of permaByLayer[LayerType.FOUNDATION]) {
    content += `      {
        layer:             "${layerToCue(setting.layer)}"
        path:              "${setting.path}"
        name:              "${escapeCueString(setting.name)}"
        settingType:       "perma"
        ${setting.description ? `description:      "${escapeCueString(setting.description)}"` : ''}
        ${setting.whyClassification ? `whyClassification: "${escapeCueString(setting.whyClassification)}"` : ''}
        ${setting.cueType ? `cueType:          "${escapeCueString(setting.cueType)}"` : ''}
      },
`;
  }
  content += `    ]

`;

  // Layer 2 perma
  content += `    // Layer 2: Platform
    layer2: [\n`;
  for (const setting of permaByLayer[LayerType.PLATFORM]) {
    content += `      {
        layer:             "${layerToCue(setting.layer)}"
        path:              "${setting.path}"
        name:              "${escapeCueString(setting.name)}"
        settingType:       "perma"
        ${setting.description ? `description:      "${escapeCueString(setting.description)}"` : ''}
        ${setting.whyClassification ? `whyClassification: "${escapeCueString(setting.whyClassification)}"` : ''}
        ${setting.cueType ? `cueType:          "${escapeCueString(setting.cueType)}"` : ''}
      },
`;
  }
  content += `    ]
  }

  // Flexible-settings: Can be changed via Day-2 operations
  flexible: {
`;

  // Layer 1 flexible
  content += `    // Layer 1: Foundation
    layer1: [\n`;
  for (const setting of flexibleByLayer[LayerType.FOUNDATION]) {
    content += `      {
        layer:             "${layerToCue(setting.layer)}"
        path:              "${setting.path}"
        name:              "${escapeCueString(setting.name)}"
        settingType:       "flexible"
        ${setting.description ? `description:      "${escapeCueString(setting.description)}"` : ''}
        ${setting.changeMethod ? `changeMethod:     "${escapeCueString(setting.changeMethod)}"` : ''}
        ${setting.cueType ? `cueType:          "${escapeCueString(setting.cueType)}"` : ''}
      },
`;
  }
  content += `    ]

`;

  // Layer 2 flexible
  content += `    // Layer 2: Platform
    layer2: [\n`;
  for (const setting of flexibleByLayer[LayerType.PLATFORM]) {
    content += `      {
        layer:             "${layerToCue(setting.layer)}"
        path:              "${setting.path}"
        name:              "${escapeCueString(setting.name)}"
        settingType:       "flexible"
        ${setting.description ? `description:      "${escapeCueString(setting.description)}"` : ''}
        ${setting.changeMethod ? `changeMethod:     "${escapeCueString(setting.changeMethod)}"` : ''}
        ${setting.cueType ? `cueType:          "${escapeCueString(setting.cueType)}"` : ''}
      },
`;
  }
  content += `    ]
  }
}
`;

  // Write file
  const outputPath = path.join(OUTPUT_DIR, 'settings_metadata.cue');
  fs.writeFileSync(outputPath, content);

  const permaCount = Object.values(permaByLayer).flat().length;
  const flexibleCount = Object.values(flexibleByLayer).flat().length;
  console.log(`  Written: ${outputPath} (${permaCount} perma, ${flexibleCount} flexible)`);
}

/**
 * Main entry point
 */
async function main(): Promise<void> {
  const target = process.argv[2] || 'all';

  console.log('='.repeat(60));
  console.log('CUE Generator - kombify-admin');
  console.log('='.repeat(60));
  console.log(`Target: ${target}`);
  console.log(`Output: ${OUTPUT_DIR}`);
  console.log('');

  ensureOutputDir();

  switch (target) {
    case 'all':
      await generateValidationRules();
      await generateSettingsMetadata();
      await generateAddonDefinitions();
      await generateContextDefaults();
      await generateToolCatalog();
      break;
    case 'validation-rules':
      await generateValidationRules();
      break;
    case 'settings':
      await generateSettingsMetadata();
      break;
    case 'addons':
      await generateAddonDefinitions();
      break;
    case 'contexts':
      await generateContextDefaults();
      break;
    case 'tool-catalog':
      await generateToolCatalog();
      break;
    default:
      console.error(`Unknown target: ${target}`);
      console.error('Valid targets: all, validation-rules, settings, addons, contexts, tool-catalog');
      process.exit(1);
  }

  console.log('');
  console.log('Generation complete!');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Validate generated CUE: cue vet ./base/...');
  console.log('  2. Commit changes if valid');
}

/**
 * Generate add-on definitions CUE file
 */
async function generateAddonDefinitions(): Promise<void> {
  console.log('Generating add-on definitions...');

  const addons = await prisma.addOn.findMany({
    where: {
      lifecycleState: {
        in: [LifecycleState.APPROVED, LifecycleState.EVALUATED, LifecycleState.DRAFT],
      },
    },
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  });

  const header = `// =============================================================================
// GENERATED FILE - DO NOT EDIT DIRECTLY
// =============================================================================
// This file is auto-generated from the kombify-admin database.
// To modify add-ons, update the database and re-run the generator.
//
// Generated: ${new Date().toISOString()}
// Source: kombify-admin/prisma/seed.ts → AddOn table
// =============================================================================

package base
`;

  let content = header;

  // Type definitions
  content += `
// =============================================================================
// ADD-ON TYPE DEFINITIONS
// =============================================================================

#ArchitecturePattern: "BASE" | "MODERN" | "HA"
#NodeContext:          "LOCAL" | "CLOUD" | "PI"

#AddOn: {
  name:               string
  displayName:        string
  description?:       string
  category:           string
  version:            string
  compatibleKits:     [...#ArchitecturePattern]
  compatibleContexts: [...#NodeContext]
  dependsOn:          [...string]
  conflictsWith:      [...string]
  minMemoryMB:        int & >=0
  minCpuCores:        number & >=0
  requiresGpu:        bool
  includedTools:      [...string]
  autoActivate:       bool
  autoActivateCondition?: string
}
`;

  // Add-on registry
  content += `
// =============================================================================
// ADD-ON REGISTRY
// =============================================================================

#AddOnRegistry: {
`;

  // Group by category
  const categories = [...new Set(addons.map((a) => a.category))].sort();

  for (const category of categories) {
    const categoryAddons = addons.filter((a) => a.category === category);
    content += `  // ${category.charAt(0).toUpperCase() + category.slice(1)}
`;
    for (const addon of categoryAddons) {
      content += `  "${addon.name}": {
    name:               "${addon.name}"
    displayName:        "${escapeCueString(addon.displayName)}"
    description:        "${escapeCueString(addon.description || '')}"
    category:           "${addon.category}"
    version:            "${addon.version}"
    compatibleKits:     [${addon.compatibleKits.map((k) => `"${k}"`).join(', ')}]
    compatibleContexts: [${addon.compatibleContexts.map((c) => `"${c}"`).join(', ')}]
    dependsOn:          [${addon.dependsOn.map((d) => `"${d}"`).join(', ')}]
    conflictsWith:      [${addon.conflictsWith.map((c) => `"${c}"`).join(', ')}]
    minMemoryMB:        ${addon.minMemoryMB}
    minCpuCores:        ${addon.minCpuCores}
    requiresGpu:        ${addon.requiresGpu}
    includedTools:      [${addon.includedTools.map((t) => `"${t}"`).join(', ')}]
    autoActivate:       ${addon.autoActivate}
    ${addon.autoActivateCondition ? `autoActivateCondition: "${escapeCueString(addon.autoActivateCondition)}"` : ''}
  }
`;
    }
    content += '\n';
  }

  content += '}\n';

  // Validation constraints
  content += `
// =============================================================================
// ADD-ON COMPATIBILITY CONSTRAINTS
// =============================================================================

// These constraints can be imported in StackKit definitions to validate
// that activated add-ons are compatible with the selected pattern/context.

#ValidateAddOnCompatibility: {
  pattern:   #ArchitecturePattern
  context:   #NodeContext
  addons:    [...string]

  // Every activated add-on must be compatible
  _valid: true & and([
    for a in addons {
      let addon = #AddOnRegistry[a]
      // Pattern must be in compatibleKits
      or([ for k in addon.compatibleKits { k == pattern } ])
      // Context must be in compatibleContexts
      or([ for c in addon.compatibleContexts { c == context } ])
    }
  ])
}
`;

  const outputPath = path.join(OUTPUT_DIR, 'addons.cue');
  fs.writeFileSync(outputPath, content);
  console.log(`  Written: ${outputPath} (${addons.length} add-ons)`);
}

/**
 * Generate context defaults CUE file
 */
async function generateContextDefaults(): Promise<void> {
  console.log('Generating context defaults...');

  const contexts = await prisma.contextDefaults.findMany({
    orderBy: { context: 'asc' },
  });

  const header = `// =============================================================================
// GENERATED FILE - DO NOT EDIT DIRECTLY
// =============================================================================
// This file is auto-generated from the kombify-admin database.
// To modify context defaults, update the database and re-run the generator.
//
// Generated: ${new Date().toISOString()}
// Source: kombify-admin/prisma/seed.ts → ContextDefaults table
// =============================================================================

package base
`;

  let content = header;

  // Type definitions
  content += `
// =============================================================================
// CONTEXT DEFAULTS DEFINITION
// =============================================================================

#ContextType: "LOCAL" | "CLOUD" | "PI"

#ContextDefault: {
  context:             #ContextType
  displayName:         string
  description?:        string
  defaultPaas?:        string
  defaultTlsMode?:     string
  defaultComputeTier?: string
  defaultMemoryLimitMB?: int
  defaultCpuShares?:   int
  defaultStorageDriver?: string
  defaultDnsStrategy?: string
  defaultBackupTarget?: string
  detectionCriteria?:  _
  hardwareProfile?:    _
}
`;

  // Context defaults registry
  content += `
// =============================================================================
// CONTEXT DEFAULTS REGISTRY
// =============================================================================

#ContextDefaults: {
`;

  for (const ctx of contexts) {
    content += `  "${ctx.context}": {
    context:             "${ctx.context}"
    displayName:         "${escapeCueString(ctx.displayName)}"
    ${ctx.description ? `description:         "${escapeCueString(ctx.description)}"` : ''}
    ${ctx.defaultPaas ? `defaultPaas:         "${escapeCueString(ctx.defaultPaas)}"` : ''}
    ${ctx.defaultTlsMode ? `defaultTlsMode:      "${escapeCueString(ctx.defaultTlsMode)}"` : ''}
    ${ctx.defaultComputeTier ? `defaultComputeTier:  "${escapeCueString(ctx.defaultComputeTier)}"` : ''}
    ${ctx.defaultMemoryLimitMB ? `defaultMemoryLimitMB: ${ctx.defaultMemoryLimitMB}` : ''}
    ${ctx.defaultCpuShares ? `defaultCpuShares:    ${ctx.defaultCpuShares}` : ''}
    ${ctx.defaultStorageDriver ? `defaultStorageDriver: "${escapeCueString(ctx.defaultStorageDriver)}"` : ''}
    ${ctx.defaultDnsStrategy ? `defaultDnsStrategy:  "${escapeCueString(ctx.defaultDnsStrategy)}"` : ''}
    ${ctx.defaultBackupTarget ? `defaultBackupTarget: "${escapeCueString(ctx.defaultBackupTarget)}"` : ''}
  }
`;
  }

  content += '}\n';

  // Auto-detection helper
  content += `
// =============================================================================
// CONTEXT DETECTION HELPERS
// =============================================================================

// Use this to apply context-specific defaults to a StackKit configuration.
// Example usage in a StackKit definition:
//
//   import "base/generated"
//
//   _detectedContext: #ContextType
//   _defaults: #ContextDefaults[_detectedContext]
//   paas: _defaults.defaultPaas
//
`;

  const outputPath = path.join(OUTPUT_DIR, 'contexts.cue');
  fs.writeFileSync(outputPath, content);
  console.log(`  Written: ${outputPath} (${contexts.length} contexts)`);
}

/**
 * Generate tool catalog CUE file
 */
async function generateToolCatalog(): Promise<void> {
  console.log('Generating tool catalog...');

  const tools = await prisma.tool.findMany({
    where: {
      lifecycleState: {
        in: [LifecycleState.APPROVED, LifecycleState.EVALUATED],
      },
    },
    orderBy: [{ layer: 'asc' }, { category: 'asc' }, { name: 'asc' }],
  });

  const categories = await prisma.toolCategory.findMany({
    orderBy: [{ layer: 'asc' }, { slug: 'asc' }],
  });

  const header = `// =============================================================================
// GENERATED FILE - DO NOT EDIT DIRECTLY
// =============================================================================
// This file is auto-generated from the kombify-admin database.
// To modify the tool catalog, update the database and re-run the generator.
//
// Generated: ${new Date().toISOString()}
// Source: kombify-admin/prisma/seed.ts → Tool + ToolCategory tables
// =============================================================================

package base
`;

  let content = header;

  // Tool definition
  content += `
// =============================================================================
// TOOL CATALOG DEFINITIONS
// =============================================================================

#Layer: "1" | "2" | "3"

#CatalogTool: {
  name:         string
  displayName:  string
  description?: string
  layer:        #Layer
  category:     string
  image:        string
  defaultTag:   string
  supportsArm:  bool | *false
  supportsX86:  bool | *true
  minMemoryMB:  int | *0
}

#ToolCategoryDef: {
  slug:         string
  displayName:  string
  layer:        #Layer
  standardTool: string
  alternatives: [...string]
}
`;

  // Category registry
  content += `
// =============================================================================
// TOOL CATEGORIES
// =============================================================================

#ToolCategories: {
`;

  for (const cat of categories) {
    content += `  "${cat.slug}": {
    slug:         "${cat.slug}"
    displayName:  "${escapeCueString(cat.displayName)}"
    layer:        "${layerToCue(cat.layer)}"
    standardTool: "${cat.standardTool || ''}"
    alternatives: [${cat.alternativeTools.map((t) => `"${t}"`).join(', ')}]
  }
`;
  }

  content += '}\n';

  // Tool catalog
  content += `
// =============================================================================
// APPROVED TOOLS
// =============================================================================

#ToolCatalog: {
`;

  for (const tool of tools) {
    content += `  "${tool.name}": {
    name:        "${tool.name}"
    displayName: "${escapeCueString(tool.displayName)}"
    ${tool.description ? `description: "${escapeCueString(tool.description.substring(0, 200))}"` : ''}
    layer:       "${layerToCue(tool.layer)}"
    category:    "${tool.category}"
    image:       "${escapeCueString(tool.image)}"
    defaultTag:  "${escapeCueString(tool.defaultTag)}"
    supportsArm: ${tool.supportsArm || false}
    supportsX86: ${tool.supportsX86 ?? true}
    minMemoryMB: ${tool.minMemoryMB || 0}
  }
`;
  }

  content += '}\n';

  const outputPath = path.join(OUTPUT_DIR, 'tool_catalog.cue');
  fs.writeFileSync(outputPath, content);
  console.log(`  Written: ${outputPath} (${tools.length} tools, ${categories.length} categories)`);
}

main()
  .catch((e) => {
    console.error('Generation failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

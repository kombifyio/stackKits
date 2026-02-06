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
 */

import { PrismaClient, LayerType, SettingType, LifecycleState } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

// Output directory for generated CUE files
const OUTPUT_DIR = path.resolve(__dirname, '../../base/generated');

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
      break;
    case 'validation-rules':
      await generateValidationRules();
      break;
    case 'settings':
      await generateSettingsMetadata();
      break;
    default:
      console.error(`Unknown target: ${target}`);
      console.error('Valid targets: all, validation-rules, settings');
      process.exit(1);
  }

  console.log('');
  console.log('Generation complete!');
  console.log('');
  console.log('Next steps:');
  console.log('  1. Validate generated CUE: cue vet ./base/...');
  console.log('  2. Commit changes if valid');
}

main()
  .catch((e) => {
    console.error('Generation failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

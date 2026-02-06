import { PrismaClient, LayerType, LifecycleState, SettingType, DecisionStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // ==========================================================================
  // TOOLS INVENTORY
  // ==========================================================================

  const tools = await Promise.all([
    // Layer 1: Foundation - Identity
    prisma.tool.upsert({
      where: { name: 'lldap' },
      update: {},
      create: {
        name: 'lldap',
        displayName: 'LLDAP',
        description: 'Lightweight LDAP server for user/group directory services',
        layer: LayerType.FOUNDATION,
        category: 'identity',
        image: 'lldap/lldap',
        defaultTag: 'stable',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://github.com/lldap/lldap',
        docsUrl: 'https://github.com/lldap/lldap/blob/main/README.md',
        sourceUrl: 'https://github.com/lldap/lldap',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'step-ca' },
      update: {},
      create: {
        name: 'step-ca',
        displayName: 'Step-CA',
        description: 'Private certificate authority for mTLS and internal PKI',
        layer: LayerType.FOUNDATION,
        category: 'identity',
        image: 'smallstep/step-ca',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://smallstep.com/docs/step-ca',
        docsUrl: 'https://smallstep.com/docs/step-ca',
        sourceUrl: 'https://github.com/smallstep/certificates',
      },
    }),

    // Layer 2: Platform - Reverse Proxy
    prisma.tool.upsert({
      where: { name: 'traefik' },
      update: {},
      create: {
        name: 'traefik',
        displayName: 'Traefik',
        description: 'Cloud-native reverse proxy and load balancer',
        layer: LayerType.PLATFORM,
        category: 'reverse-proxy',
        image: 'traefik',
        defaultTag: 'v3.1',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://traefik.io',
        docsUrl: 'https://doc.traefik.io/traefik/',
        sourceUrl: 'https://github.com/traefik/traefik',
      },
    }),

    // Layer 2: Platform - PAAS
    prisma.tool.upsert({
      where: { name: 'dokploy' },
      update: {},
      create: {
        name: 'dokploy',
        displayName: 'Dokploy',
        description: 'Self-hosted PaaS for deploying applications with Docker',
        layer: LayerType.PLATFORM,
        category: 'paas',
        image: 'dokploy/dokploy',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://dokploy.com',
        docsUrl: 'https://docs.dokploy.com',
        sourceUrl: 'https://github.com/Dokploy/dokploy',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'coolify' },
      update: {},
      create: {
        name: 'coolify',
        displayName: 'Coolify',
        description: 'Self-hosted Heroku/Netlify alternative with git deployments',
        layer: LayerType.PLATFORM,
        category: 'paas',
        image: 'ghcr.io/coollabsio/coolify',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://coolify.io',
        docsUrl: 'https://coolify.io/docs',
        sourceUrl: 'https://github.com/coollabsio/coolify',
      },
    }),

    // Layer 2: Platform - Identity
    prisma.tool.upsert({
      where: { name: 'tinyauth' },
      update: {},
      create: {
        name: 'tinyauth',
        displayName: 'TinyAuth',
        description: 'Lightweight authentication proxy for Traefik',
        layer: LayerType.PLATFORM,
        category: 'platform-identity',
        image: 'ghcr.io/steveiliop56/tinyauth',
        defaultTag: 'v3',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://github.com/steveiliop56/tinyauth',
        docsUrl: 'https://github.com/steveiliop56/tinyauth',
        sourceUrl: 'https://github.com/steveiliop56/tinyauth',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'pocketid' },
      update: {},
      create: {
        name: 'pocketid',
        displayName: 'PocketID',
        description: 'Lightweight OIDC provider with LDAP sync',
        layer: LayerType.PLATFORM,
        category: 'platform-identity',
        image: 'stonith404/pocket-id',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://github.com/stonith404/pocket-id',
        docsUrl: 'https://github.com/stonith404/pocket-id',
        sourceUrl: 'https://github.com/stonith404/pocket-id',
      },
    }),

    // Layer 2: Platform - Management
    prisma.tool.upsert({
      where: { name: 'dozzle' },
      update: {},
      create: {
        name: 'dozzle',
        displayName: 'Dozzle',
        description: 'Real-time Docker log viewer',
        layer: LayerType.PLATFORM,
        category: 'management',
        image: 'amir20/dozzle',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://dozzle.dev',
        docsUrl: 'https://dozzle.dev/guide',
        sourceUrl: 'https://github.com/amir20/dozzle',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'portainer' },
      update: {},
      create: {
        name: 'portainer',
        displayName: 'Portainer',
        description: 'Container management UI for Docker and Kubernetes',
        layer: LayerType.PLATFORM,
        category: 'management',
        image: 'portainer/portainer-ce',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://portainer.io',
        docsUrl: 'https://docs.portainer.io',
        sourceUrl: 'https://github.com/portainer/portainer',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'dockge' },
      update: {},
      create: {
        name: 'dockge',
        displayName: 'Dockge',
        description: 'Docker Compose stack manager with web UI',
        layer: LayerType.PLATFORM,
        category: 'management',
        image: 'louislam/dockge',
        defaultTag: '1',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://github.com/louislam/dockge',
        docsUrl: 'https://github.com/louislam/dockge',
        sourceUrl: 'https://github.com/louislam/dockge',
      },
    }),

    // Layer 3: Applications - Monitoring
    prisma.tool.upsert({
      where: { name: 'uptime-kuma' },
      update: {},
      create: {
        name: 'uptime-kuma',
        displayName: 'Uptime Kuma',
        description: 'Self-hosted monitoring tool for endpoints and services',
        layer: LayerType.APPLICATION,
        category: 'monitoring',
        image: 'louislam/uptime-kuma',
        defaultTag: '1',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://uptime.kuma.pet',
        docsUrl: 'https://github.com/louislam/uptime-kuma/wiki',
        sourceUrl: 'https://github.com/louislam/uptime-kuma',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'beszel' },
      update: {},
      create: {
        name: 'beszel',
        displayName: 'Beszel',
        description: 'Lightweight server metrics and monitoring dashboard',
        layer: LayerType.APPLICATION,
        category: 'monitoring',
        image: 'henrygd/beszel',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://github.com/henrygd/beszel',
        docsUrl: 'https://github.com/henrygd/beszel',
        sourceUrl: 'https://github.com/henrygd/beszel',
      },
    }),
    prisma.tool.upsert({
      where: { name: 'netdata' },
      update: {},
      create: {
        name: 'netdata',
        displayName: 'Netdata',
        description: 'Real-time performance and health monitoring',
        layer: LayerType.APPLICATION,
        category: 'monitoring',
        image: 'netdata/netdata',
        defaultTag: 'stable',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://netdata.cloud',
        docsUrl: 'https://learn.netdata.cloud',
        sourceUrl: 'https://github.com/netdata/netdata',
      },
    }),

    // Layer 3: Applications - Utility
    prisma.tool.upsert({
      where: { name: 'whoami' },
      update: {},
      create: {
        name: 'whoami',
        displayName: 'Whoami',
        description: 'Simple HTTP request info service for testing',
        layer: LayerType.APPLICATION,
        category: 'utility',
        image: 'traefik/whoami',
        defaultTag: 'latest',
        lifecycleState: LifecycleState.APPROVED,
        homepageUrl: 'https://github.com/traefik/whoami',
        docsUrl: 'https://github.com/traefik/whoami',
        sourceUrl: 'https://github.com/traefik/whoami',
      },
    }),
  ]);

  console.log(`Created ${tools.length} tools`);

  // ==========================================================================
  // STACKKITS CATALOG
  // ==========================================================================

  const stackkits = await Promise.all([
    prisma.stackKit.upsert({
      where: { name: 'base-homelab' },
      update: {},
      create: {
        name: 'base-homelab',
        displayName: 'Base Homelab',
        description: 'Single-server homelab with Docker, Dokploy/Coolify PAAS, and monitoring. Perfect for personal home servers and development environments.',
        version: '3.0.0',
        foundationModule: 'base',
        platformType: 'docker',
        lifecycleState: LifecycleState.APPROVED,
        author: 'KombiStack Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombihq/stackkits',
        tags: ['homelab', 'single-node', 'docker', 'dokploy', 'professional'],
        minCliVersion: '1.0.0',
      },
    }),
    prisma.stackKit.upsert({
      where: { name: 'dev-homelab' },
      update: {},
      create: {
        name: 'dev-homelab',
        displayName: 'Dev Homelab',
        description: 'Development-focused homelab with enhanced tooling for software development workflows.',
        version: '3.0.0',
        foundationModule: 'base',
        platformType: 'docker',
        lifecycleState: LifecycleState.APPROVED,
        author: 'KombiStack Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombihq/stackkits',
        tags: ['homelab', 'development', 'docker', 'devtools'],
        minCliVersion: '1.0.0',
      },
    }),
    prisma.stackKit.upsert({
      where: { name: 'modern-homelab' },
      update: {},
      create: {
        name: 'modern-homelab',
        displayName: 'Modern Homelab',
        description: 'Modern homelab stack with contemporary tooling and cloud-native patterns.',
        version: '1.0.0',
        foundationModule: 'base',
        platformType: 'docker',
        lifecycleState: LifecycleState.DRAFT,
        author: 'KombiStack Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombihq/stackkits',
        tags: ['homelab', 'modern', 'docker', 'cloud-native'],
        minCliVersion: '1.0.0',
      },
    }),
    prisma.stackKit.upsert({
      where: { name: 'ha-homelab' },
      update: {},
      create: {
        name: 'ha-homelab',
        displayName: 'HA Homelab',
        description: 'High-availability homelab with Docker Swarm for multi-node deployments.',
        version: '1.0.0',
        foundationModule: 'base',
        platformType: 'docker-swarm',
        lifecycleState: LifecycleState.DRAFT,
        author: 'KombiStack Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombihq/stackkits',
        tags: ['homelab', 'ha', 'docker-swarm', 'multi-node'],
        minCliVersion: '1.0.0',
      },
    }),
  ]);

  console.log(`Created ${stackkits.length} stackkits`);

  // ==========================================================================
  // STACKKIT-TOOL RELATIONSHIPS
  // ==========================================================================

  const baseHomelabKit = stackkits.find(s => s.name === 'base-homelab')!;
  const devHomelabKit = stackkits.find(s => s.name === 'dev-homelab')!;

  const toolMap = new Map(tools.map(t => [t.name, t]));

  // Base Homelab tool associations
  const baseHomelabTools = await Promise.all([
    // Required tools (all variants)
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('lldap')!.id, variantName: null } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('lldap')!.id, isRequired: true, isDefault: true, deployOrder: 1 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('step-ca')!.id, variantName: null } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('step-ca')!.id, isRequired: true, isDefault: true, deployOrder: 2 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('traefik')!.id, variantName: null } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('traefik')!.id, isRequired: true, isDefault: true, deployOrder: 10 },
    }),
    // Default variant: Dokploy + Uptime Kuma
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dokploy')!.id, variantName: 'default' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dokploy')!.id, variantName: 'default', isDefault: true, deployOrder: 20 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('uptime-kuma')!.id, variantName: 'default' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('uptime-kuma')!.id, variantName: 'default', isDefault: true, deployOrder: 30 },
    }),
    // Coolify variant
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('coolify')!.id, variantName: 'coolify' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('coolify')!.id, variantName: 'coolify', isDefault: true, deployOrder: 20 },
    }),
    // Beszel variant
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dokploy')!.id, variantName: 'beszel' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dokploy')!.id, variantName: 'beszel', isDefault: true, deployOrder: 20 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('beszel')!.id, variantName: 'beszel' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('beszel')!.id, variantName: 'beszel', isDefault: true, deployOrder: 30 },
    }),
    // Minimal variant
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dockge')!.id, variantName: 'minimal' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dockge')!.id, variantName: 'minimal', isDefault: true, deployOrder: 20 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('portainer')!.id, variantName: 'minimal' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('portainer')!.id, variantName: 'minimal', isDefault: true, deployOrder: 21 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('netdata')!.id, variantName: 'minimal' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('netdata')!.id, variantName: 'minimal', isDefault: true, deployOrder: 30 },
    }),
    // Secure variant adds TinyAuth
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('tinyauth')!.id, variantName: 'secure' } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('tinyauth')!.id, variantName: 'secure', isDefault: true, deployOrder: 15 },
    }),
    // Optional tools (all variants)
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dozzle')!.id, variantName: null } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('dozzle')!.id, isDefault: false, deployOrder: 50 },
    }),
    prisma.stackKitTool.upsert({
      where: { stackkitId_toolId_variantName: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('whoami')!.id, variantName: null } },
      update: {},
      create: { stackkitId: baseHomelabKit.id, toolId: toolMap.get('whoami')!.id, isDefault: false, deployOrder: 99 },
    }),
  ]);

  console.log(`Created ${baseHomelabTools.length} base-homelab tool associations`);

  // ==========================================================================
  // VALIDATION RULES
  // ==========================================================================

  const validationRules = await Promise.all([
    // Layer 1 Rules
    prisma.validationRule.upsert({
      where: { code: 'L1_LLDAP_REQUIRED' },
      update: {},
      create: {
        code: 'L1_LLDAP_REQUIRED',
        layer: LayerType.FOUNDATION,
        fieldPath: 'identity.lldap.enabled',
        ruleType: 'required',
        cueExpression: 'identity.lldap.enabled == true',
        errorMessage: 'LLDAP must be enabled for Zero-Trust architecture',
        hint: 'Set identity.lldap.enabled: true in your stack configuration',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
    prisma.validationRule.upsert({
      where: { code: 'L1_STEPCA_REQUIRED' },
      update: {},
      create: {
        code: 'L1_STEPCA_REQUIRED',
        layer: LayerType.FOUNDATION,
        fieldPath: 'identity.stepCA.enabled',
        ruleType: 'required',
        cueExpression: 'identity.stepCA.enabled == true',
        errorMessage: 'Step-CA must be enabled for mTLS certificate management',
        hint: 'Set identity.stepCA.enabled: true in your stack configuration',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
    prisma.validationRule.upsert({
      where: { code: 'L1_SSH_PORT_VALID' },
      update: {},
      create: {
        code: 'L1_SSH_PORT_VALID',
        layer: LayerType.FOUNDATION,
        fieldPath: 'security.ssh.port',
        ruleType: 'constraint',
        cueExpression: 'security.ssh.port >= 1 & security.ssh.port <= 65535',
        errorMessage: 'SSH port must be between 1 and 65535',
        hint: 'Use a valid port number, typically 22 or a high port like 2222',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
    prisma.validationRule.upsert({
      where: { code: 'L1_FIREWALL_REQUIRED' },
      update: {},
      create: {
        code: 'L1_FIREWALL_REQUIRED',
        layer: LayerType.FOUNDATION,
        fieldPath: 'security.firewall.enabled',
        ruleType: 'required',
        cueExpression: 'security.firewall.enabled == true',
        errorMessage: 'Firewall must be enabled for security',
        hint: 'Set security.firewall.enabled: true',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),

    // Layer 2 Rules
    prisma.validationRule.upsert({
      where: { code: 'L2_PLATFORM_DECLARED' },
      update: {},
      create: {
        code: 'L2_PLATFORM_DECLARED',
        layer: LayerType.PLATFORM,
        fieldPath: 'platform',
        ruleType: 'required',
        cueExpression: 'platform != _|_',
        errorMessage: 'Platform type must be explicitly declared',
        hint: 'Set platform: "docker" | "docker-swarm" | "kubernetes" | "bare-metal"',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
    prisma.validationRule.upsert({
      where: { code: 'L2_NETWORK_DEFAULTS' },
      update: {},
      create: {
        code: 'L2_NETWORK_DEFAULTS',
        layer: LayerType.PLATFORM,
        fieldPath: 'network.defaults',
        ruleType: 'required',
        cueExpression: 'network.defaults != _|_',
        errorMessage: 'Network defaults must be configured',
        hint: 'Configure network.defaults with domain and subnet',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
    prisma.validationRule.upsert({
      where: { code: 'L2_PAAS_TYPE_VALID' },
      update: {},
      create: {
        code: 'L2_PAAS_TYPE_VALID',
        layer: LayerType.PLATFORM,
        fieldPath: 'paas.type',
        ruleType: 'constraint',
        cueExpression: 'paas.type =~ "^(dokploy|coolify|dokku|portainer|dockge)$"',
        errorMessage: 'PAAS type must be one of: dokploy, coolify, dokku, portainer, dockge',
        hint: 'Use a supported PAAS platform',
        severity: 'error',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),

    // Layer 3 Rules
    prisma.validationRule.upsert({
      where: { code: 'L3_SERVICE_LAYER_LABEL' },
      update: {},
      create: {
        code: 'L3_SERVICE_LAYER_LABEL',
        layer: LayerType.APPLICATION,
        fieldPath: 'services[*].labels["stackkit.layer"]',
        ruleType: 'required',
        cueExpression: 'services[_].labels["stackkit.layer"] != _|_',
        errorMessage: 'All services must have stackkit.layer label',
        hint: 'Add labels: {"stackkit.layer": "3-application"} to your service',
        severity: 'warning',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
    prisma.validationRule.upsert({
      where: { code: 'L3_SERVICE_MANAGED_BY' },
      update: {},
      create: {
        code: 'L3_SERVICE_MANAGED_BY',
        layer: LayerType.APPLICATION,
        fieldPath: 'services[*].labels["stackkit.managed-by"]',
        ruleType: 'required',
        cueExpression: 'services[_].labels["stackkit.managed-by"] != _|_',
        errorMessage: 'All services must have stackkit.managed-by label',
        hint: 'Add labels: {"stackkit.managed-by": "dokploy"} to your service',
        severity: 'warning',
        lifecycleState: LifecycleState.APPROVED,
      },
    }),
  ]);

  console.log(`Created ${validationRules.length} validation rules`);

  // ==========================================================================
  // SETTINGS CLASSIFICATION
  // ==========================================================================

  const settings = await Promise.all([
    // Layer 1 - Perma Settings
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.FOUNDATION, path: 'security.ssh.port' } },
      update: {},
      create: {
        layer: LayerType.FOUNDATION,
        path: 'security.ssh.port',
        name: 'SSH Port',
        settingType: SettingType.PERMA,
        description: 'SSH daemon listening port',
        whyClassification: 'Changing requires firewall rules update, client reconfiguration, and potential lockout',
        defaultValue: 22,
        cueType: 'int & >=1 & <=65535',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.FOUNDATION, path: 'security.firewall.backend' } },
      update: {},
      create: {
        layer: LayerType.FOUNDATION,
        path: 'security.firewall.backend',
        name: 'Firewall Backend',
        settingType: SettingType.PERMA,
        description: 'Firewall management backend',
        whyClassification: 'ufw vs iptables vs nftables have incompatible rule formats; migration is manual',
        defaultValue: 'ufw',
        cueType: '"ufw" | "iptables" | "nftables"',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.FOUNDATION, path: 'identity.lldap.domain.base' } },
      update: {},
      create: {
        layer: LayerType.FOUNDATION,
        path: 'identity.lldap.domain.base',
        name: 'LLDAP Base DN',
        settingType: SettingType.PERMA,
        description: 'LDAP base distinguished name',
        whyClassification: 'All user/group references use this; changing invalidates all identity lookups',
        defaultValue: 'dc=homelab,dc=local',
        cueType: 'string',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.FOUNDATION, path: 'identity.stepCA.pki.rootCommonName' } },
      update: {},
      create: {
        layer: LayerType.FOUNDATION,
        path: 'identity.stepCA.pki.rootCommonName',
        name: 'Root CA Name',
        settingType: SettingType.PERMA,
        description: 'Root certificate authority common name',
        whyClassification: 'Changing requires complete PKI rebuild and re-issuing all certificates',
        defaultValue: 'StackKits Root CA',
        cueType: 'string',
      },
    }),

    // Layer 1 - Flexible Settings
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.FOUNDATION, path: 'system.timezone' } },
      update: {},
      create: {
        layer: LayerType.FOUNDATION,
        path: 'system.timezone',
        name: 'System Timezone',
        settingType: SettingType.FLEXIBLE,
        description: 'System timezone configuration',
        changeMethod: 'terramate run -- tofu apply',
        defaultValue: 'UTC',
        cueType: 'string',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.FOUNDATION, path: 'packages.extra' } },
      update: {},
      create: {
        layer: LayerType.FOUNDATION,
        path: 'packages.extra',
        name: 'Extra Packages',
        settingType: SettingType.FLEXIBLE,
        description: 'Additional system packages to install',
        changeMethod: 'terramate run -- tofu apply',
        defaultValue: [],
        cueType: '[...string]',
      },
    }),

    // Layer 2 - Perma Settings
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.PLATFORM, path: 'platform' } },
      update: {},
      create: {
        layer: LayerType.PLATFORM,
        path: 'platform',
        name: 'Platform Type',
        settingType: SettingType.PERMA,
        description: 'Container orchestration platform',
        whyClassification: 'Migration from docker to swarm/k8s requires workload evacuation and complete redeployment',
        defaultValue: 'docker',
        cueType: '"docker" | "docker-swarm" | "kubernetes" | "bare-metal"',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.PLATFORM, path: 'network.defaults.subnet' } },
      update: {},
      create: {
        layer: LayerType.PLATFORM,
        path: 'network.defaults.subnet',
        name: 'Network Subnet',
        settingType: SettingType.PERMA,
        description: 'Docker network subnet',
        whyClassification: 'All containers use this; changing requires network recreation',
        defaultValue: '172.20.0.0/16',
        cueType: 'string',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.PLATFORM, path: 'paas.type' } },
      update: {},
      create: {
        layer: LayerType.PLATFORM,
        path: 'paas.type',
        name: 'PAAS Type',
        settingType: SettingType.PERMA,
        description: 'Platform-as-a-Service selection',
        whyClassification: 'Migrating applications between Dokploy/Coolify requires manual export/import',
        defaultValue: 'dokploy',
        cueType: '"dokploy" | "coolify" | "dokku" | "portainer" | "dockge"',
      },
    }),

    // Layer 2 - Flexible Settings
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.PLATFORM, path: 'network.defaults.domain' } },
      update: {},
      create: {
        layer: LayerType.PLATFORM,
        path: 'network.defaults.domain',
        name: 'Domain',
        settingType: SettingType.FLEXIBLE,
        description: 'Base domain for services',
        changeMethod: 'terramate run -- tofu apply (updates Traefik rules)',
        defaultValue: 'local',
        cueType: 'string',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.PLATFORM, path: 'paas.dokploy.version' } },
      update: {},
      create: {
        layer: LayerType.PLATFORM,
        path: 'paas.dokploy.version',
        name: 'Dokploy Version',
        settingType: SettingType.FLEXIBLE,
        description: 'Dokploy container image version',
        changeMethod: 'terramate run -- tofu apply',
        defaultValue: 'latest',
        cueType: 'string',
      },
    }),
    prisma.setting.upsert({
      where: { layer_path: { layer: LayerType.PLATFORM, path: 'platformIdentity.tinyauth.enabled' } },
      update: {},
      create: {
        layer: LayerType.PLATFORM,
        path: 'platformIdentity.tinyauth.enabled',
        name: 'TinyAuth Enabled',
        settingType: SettingType.FLEXIBLE,
        description: 'Enable TinyAuth authentication proxy',
        changeMethod: 'terramate run -- tofu apply',
        defaultValue: false,
        cueType: 'bool',
      },
    }),
  ]);

  console.log(`Created ${settings.length} settings`);

  // ==========================================================================
  // PATTERNS
  // ==========================================================================

  const patterns = await Promise.all([
    prisma.pattern.upsert({
      where: { name: 'zero-trust-identity' },
      update: {},
      create: {
        name: 'zero-trust-identity',
        category: 'security',
        layer: LayerType.FOUNDATION,
        description: 'Zero-Trust identity pattern with LLDAP directory and Step-CA PKI',
        problemStatement: 'Services need authenticated access without public trust chains',
        solution: 'Deploy LLDAP for user/group directory, Step-CA for internal PKI, integrate with platform identity (TinyAuth/PocketID)',
        cueExample: `identity: {
  lldap: { enabled: true, domain: { base: "dc=homelab,dc=local" } }
  stepCA: { enabled: true, pki: { rootCommonName: "Homelab Root CA" } }
}`,
        lifecycleState: LifecycleState.APPROVED,
        relatedAdr: 'ADR-0001',
        tags: ['security', 'identity', 'zero-trust', 'ldap', 'pki'],
      },
    }),
    prisma.pattern.upsert({
      where: { name: 'paas-selection' },
      update: {},
      create: {
        name: 'paas-selection',
        category: 'platform',
        layer: LayerType.PLATFORM,
        description: 'PAAS selection strategy based on domain availability',
        problemStatement: 'Users need different PAAS platforms depending on their domain setup',
        solution: 'Use Dokploy for no-domain/local setups, Coolify when domain is available for git-based deploys',
        cueExample: `paas: {
  type: *"dokploy" | "coolify"
  // Coolify requires domain for webhooks
  if network.defaults.domain != "local" {
    type: "coolify"
  }
}`,
        lifecycleState: LifecycleState.APPROVED,
        relatedAdr: 'ADR-0003',
        tags: ['platform', 'paas', 'dokploy', 'coolify'],
      },
    }),
    prisma.pattern.upsert({
      where: { name: 'service-layer-labeling' },
      update: {},
      create: {
        name: 'service-layer-labeling',
        category: 'organization',
        description: 'Consistent service labeling for layer identification',
        problemStatement: 'Services need clear layer identification for management and validation',
        solution: 'Add stackkit.layer and stackkit.managed-by labels to all services',
        cueExample: `labels: {
  "stackkit.layer": "3-application"
  "stackkit.managed-by": "dokploy"
}`,
        lifecycleState: LifecycleState.APPROVED,
        tags: ['organization', 'labels', 'services'],
      },
    }),
  ]);

  console.log(`Created ${patterns.length} patterns`);

  // ==========================================================================
  // DECISIONS (ADRs)
  // ==========================================================================

  const decisions = await Promise.all([
    prisma.decision.upsert({
      where: { adrNumber: 'ADR-0001' },
      update: {},
      create: {
        adrNumber: 'ADR-0001',
        title: 'Zero-Trust Identity Required for All StackKits',
        context: 'StackKits need a consistent security foundation. Optional identity services lead to inconsistent security postures across deployments.',
        decision: 'LLDAP and Step-CA are REQUIRED for all StackKits. These services form the Layer 1 identity foundation that all other services depend on.',
        consequencesPositive: 'Consistent security posture, simplified service integration, mTLS everywhere',
        consequencesNegative: 'Increased minimum resource requirements, more initial setup complexity',
        alternativesConsidered: ['Optional identity (rejected: inconsistent security)', 'External identity only (rejected: self-hosted focus)'],
        status: DecisionStatus.APPROVED,
        affectedLayers: [LayerType.FOUNDATION, LayerType.PLATFORM],
        proposedBy: 'Architecture Team',
        decidedBy: 'Architecture Team',
        decidedAt: new Date(),
      },
    }),
    prisma.decision.upsert({
      where: { adrNumber: 'ADR-0002' },
      update: {},
      create: {
        adrNumber: 'ADR-0002',
        title: '3-Layer Architecture Model',
        context: 'StackKits need clear separation of concerns between infrastructure, platform, and applications.',
        decision: 'Adopt 3-layer model: L1 Foundation (system, security, identity), L2 Platform (container runtime, PAAS, ingress), L3 Applications (user services deployed via PAAS)',
        consequencesPositive: 'Clear responsibility boundaries, easier validation, modular upgrades',
        consequencesNegative: 'More complex initial understanding, stricter placement rules',
        alternativesConsidered: ['2-layer model (rejected: insufficient separation)', '4-layer model (rejected: over-engineered)'],
        status: DecisionStatus.APPROVED,
        affectedLayers: [LayerType.FOUNDATION, LayerType.PLATFORM, LayerType.APPLICATION],
        proposedBy: 'Architecture Team',
        decidedBy: 'Architecture Team',
        decidedAt: new Date(),
      },
    }),
    prisma.decision.upsert({
      where: { adrNumber: 'ADR-0003' },
      update: {},
      create: {
        adrNumber: 'ADR-0003',
        title: 'PAAS Selection Strategy',
        context: 'Users have different needs based on domain availability. Some have custom domains, others run locally.',
        decision: 'Default to Dokploy for simple/local deployments. Use Coolify when domain is configured for git-based workflows.',
        consequencesPositive: 'Appropriate tool for each use case, better user experience',
        consequencesNegative: 'Two PAAS platforms to maintain, migration complexity',
        alternativesConsidered: ['Dokploy only (rejected: limited for domain users)', 'Coolify only (rejected: complex for local-only)'],
        status: DecisionStatus.APPROVED,
        affectedLayers: [LayerType.PLATFORM],
        affectedStackKits: ['base-homelab', 'dev-homelab'],
        proposedBy: 'Architecture Team',
        decidedBy: 'Architecture Team',
        decidedAt: new Date(),
      },
    }),
    prisma.decision.upsert({
      where: { adrNumber: 'ADR-0004' },
      update: {},
      create: {
        adrNumber: 'ADR-0004',
        title: 'Database as Master for CUE Generation',
        context: 'Need single source of truth for validation rules, settings, and metadata.',
        decision: 'PostgreSQL database is the master source. CUE validation files are generated from the database via GitHub Actions.',
        consequencesPositive: 'Single source of truth, easier UI-based management, consistent generation',
        consequencesNegative: 'Requires generation pipeline, database dependency for changes',
        alternativesConsidered: ['CUE as master (rejected: harder to manage programmatically)', 'Dual sources (rejected: sync complexity)'],
        status: DecisionStatus.APPROVED,
        affectedLayers: [LayerType.FOUNDATION, LayerType.PLATFORM, LayerType.APPLICATION],
        proposedBy: 'Architecture Team',
        decidedBy: 'Architecture Team',
        decidedAt: new Date(),
      },
    }),
  ]);

  console.log(`Created ${decisions.length} decisions`);

  console.log('Seeding complete!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

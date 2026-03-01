import {
  PrismaClient,
  LayerType,
  LifecycleState,
  SettingType,
  DecisionStatus,
  ArchitecturePattern,
  NodeContext,
  DiscoverySource,
  EvaluationVerdict,
  JobType,
} from '@prisma/client';

const prisma = new PrismaClient();

// Helper for StackKitTool upsert with nullable variantName
async function upsertStackKitTool(data: {
  stackkitId: string;
  toolId: string;
  variantName?: string | null;
  isRequired?: boolean;
  isDefault?: boolean;
  deployOrder?: number;
}) {
  const existing = await prisma.stackKitTool.findFirst({
    where: {
      stackkitId: data.stackkitId,
      toolId: data.toolId,
      variantName: data.variantName ?? null,
    },
  });
  if (existing) return existing;
  return prisma.stackKitTool.create({
    data: {
      stackkitId: data.stackkitId,
      toolId: data.toolId,
      variantName: data.variantName,
      isRequired: data.isRequired ?? false,
      isDefault: data.isDefault ?? false,
      deployOrder: data.deployOrder ?? 0,
    },
  });
}

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
      where: { name: 'base-kit' },
      update: {},
      create: {
        name: 'base-kit',
        displayName: 'Base Kit',
        description: 'Single-environment homelab with Docker, Dokploy/Coolify PAAS, and monitoring. Everything runs in one logical deployment target — local server or cloud VPS.',
        version: '4.0.0',
        architecturePattern: ArchitecturePattern.BASE,
        foundationModule: 'base',
        platformType: 'docker',
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD, NodeContext.PI],
        lifecycleState: LifecycleState.APPROVED,
        author: 'kombify Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombify/stackkits',
        tags: ['homelab', 'single-node', 'docker', 'dokploy', 'professional'],
        minCliVersion: '1.0.0',
        minNodes: 1,
        tagline: 'Your first homelab, done right',
      },
    }),
    prisma.stackKit.upsert({
      where: { name: 'dev-homelab' },
      update: {},
      create: {
        name: 'dev-homelab',
        displayName: 'Dev Kit',
        description: 'Development-focused homelab with enhanced tooling for software development workflows.',
        version: '4.0.0',
        architecturePattern: ArchitecturePattern.BASE,
        foundationModule: 'base',
        platformType: 'docker',
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD],
        lifecycleState: LifecycleState.APPROVED,
        author: 'kombify Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombify/stackkits',
        tags: ['homelab', 'development', 'docker', 'devtools'],
        minCliVersion: '1.0.0',
        minNodes: 1,
        tagline: 'Built for developers who self-host',
      },
    }),
    prisma.stackKit.upsert({
      where: { name: 'modern-homelab' },
      update: {},
      create: {
        name: 'modern-homelab',
        displayName: 'Modern Homelab',
        description: 'Hybrid infrastructure pattern — bridges local and cloud environments via VPN overlay. Distributed services with public endpoints and private data.',
        version: '4.0.0',
        architecturePattern: ArchitecturePattern.MODERN,
        foundationModule: 'base',
        platformType: 'docker',
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD, NodeContext.PI],
        lifecycleState: LifecycleState.DRAFT,
        author: 'kombify Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombify/stackkits',
        tags: ['homelab', 'hybrid', 'docker', 'vpn', 'multi-node'],
        minCliVersion: '1.0.0',
        minNodes: 2,
        tagline: 'Bridge your home and the cloud',
      },
    }),
    prisma.stackKit.upsert({
      where: { name: 'ha-kit' },
      update: {},
      create: {
        name: 'ha-kit',
        displayName: 'High Availability Kit',
        description: 'HA cluster pattern with Docker Swarm — redundancy, failover, quorum-based consensus. No single point of failure.',
        version: '4.0.0',
        architecturePattern: ArchitecturePattern.HA,
        foundationModule: 'base',
        platformType: 'docker-swarm',
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD],
        lifecycleState: LifecycleState.DRAFT,
        author: 'kombify Team',
        license: 'MIT',
        repositoryUrl: 'https://github.com/kombify/stackkits',
        tags: ['homelab', 'ha', 'docker-swarm', 'multi-node', 'production'],
        minCliVersion: '1.0.0',
        minNodes: 3,
        tagline: 'Production-grade self-hosting',
      },
    }),
  ]);

  console.log(`Created ${stackkits.length} stackkits`);

  // ==========================================================================
  // STACKKIT-TOOL RELATIONSHIPS
  // ==========================================================================

  const BaseKitKit = stackkits.find(s => s.name === 'base-kit')!;
  const devHomelabKit = stackkits.find(s => s.name === 'dev-homelab')!;

  const toolMap = new Map(tools.map(t => [t.name, t]));

  // Base Kit tool associations
  const BaseKitTools = await Promise.all([
    // Required tools (all variants)
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('lldap')!.id, isRequired: true, isDefault: true, deployOrder: 1 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('step-ca')!.id, isRequired: true, isDefault: true, deployOrder: 2 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('traefik')!.id, isRequired: true, isDefault: true, deployOrder: 10 }),
    // Default variant: Dokploy + Uptime Kuma
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('dokploy')!.id, variantName: 'default', isDefault: true, deployOrder: 20 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('uptime-kuma')!.id, variantName: 'default', isDefault: true, deployOrder: 30 }),
    // Coolify variant
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('coolify')!.id, variantName: 'coolify', isDefault: true, deployOrder: 20 }),
    // Beszel variant
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('dokploy')!.id, variantName: 'beszel', isDefault: true, deployOrder: 20 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('beszel')!.id, variantName: 'beszel', isDefault: true, deployOrder: 30 }),
    // Minimal variant
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('dockge')!.id, variantName: 'minimal', isDefault: true, deployOrder: 20 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('portainer')!.id, variantName: 'minimal', isDefault: true, deployOrder: 21 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('netdata')!.id, variantName: 'minimal', isDefault: true, deployOrder: 30 }),
    // Secure variant adds TinyAuth
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('tinyauth')!.id, variantName: 'secure', isDefault: true, deployOrder: 15 }),
    // Optional tools (all variants)
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('dozzle')!.id, isDefault: false, deployOrder: 50 }),
    upsertStackKitTool({ stackkitId: BaseKitKit.id, toolId: toolMap.get('whoami')!.id, isDefault: false, deployOrder: 99 }),
  ]);

  console.log(`Created ${BaseKitTools.length} base-kit tool associations`);

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
        affectedStackKits: ['base-kit', 'dev-homelab'],
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

  // ==========================================================================
  // CONTEXT DEFAULTS (Architecture v4)
  // ==========================================================================

  const contexts = await Promise.all([
    prisma.contextDefaults.upsert({
      where: { context: NodeContext.LOCAL },
      update: {},
      create: {
        context: NodeContext.LOCAL,
        displayName: 'Local Hardware',
        description: 'Physical server with no cloud metadata — full control, local network, no egress costs',
        defaultPaas: 'dokploy',
        defaultTlsMode: 'self-signed',
        defaultComputeTier: 'standard',
        defaultMemoryLimitMB: 4096,
        defaultCpuShares: 1024,
        defaultStorageDriver: 'overlay2',
        defaultDnsStrategy: 'local-dns',
        defaultBackupTarget: 'local-nas',
        detectionCriteria: [
          'No cloud provider metadata endpoint responds',
          'Physical hardware detected (dmidecode)',
          'x86_64 or ARM architecture',
        ],
        hardwareProfile: {
          typicalRam: '8-64 GB',
          typicalCpu: '4-16 cores',
          typicalStorage: 'SSD/HDD, 256GB+',
          networkType: 'LAN, 1Gbps+',
        },
        cueDefaults: `if _context == "local" {
  paas: type: "dokploy"
  tls: mode: "self-signed"
  resources: { memoryLimitMB: 4096, cpuShares: 1024 }
  storage: driver: "overlay2"
}`,
      },
    }),
    prisma.contextDefaults.upsert({
      where: { context: NodeContext.CLOUD },
      update: {},
      create: {
        context: NodeContext.CLOUD,
        displayName: 'Cloud VPS',
        description: 'Cloud provider metadata detected — public IP, egress costs, provider-managed networking',
        defaultPaas: 'coolify',
        defaultTlsMode: 'letsencrypt',
        defaultComputeTier: 'standard',
        defaultMemoryLimitMB: 2048,
        defaultCpuShares: 1024,
        defaultStorageDriver: 'overlay2',
        defaultDnsStrategy: 'cloud-dns',
        defaultBackupTarget: 's3',
        detectionCriteria: [
          'Cloud provider metadata endpoint responds (169.254.169.254)',
          'AWS, Azure, Hetzner, DigitalOcean, or Linode detected',
          'Public IP assigned',
        ],
        hardwareProfile: {
          typicalRam: '2-16 GB',
          typicalCpu: '2-8 vCPUs',
          typicalStorage: 'SSD, 40-200GB',
          networkType: 'Public IP, egress metered',
        },
        cueDefaults: `if _context == "cloud" {
  paas: type: "coolify"
  tls: mode: "letsencrypt"
  resources: { memoryLimitMB: 2048, cpuShares: 1024 }
  storage: driver: "overlay2"
}`,
      },
    }),
    prisma.contextDefaults.upsert({
      where: { context: NodeContext.PI },
      update: {},
      create: {
        context: NodeContext.PI,
        displayName: 'Raspberry Pi',
        description: 'ARM architecture with low memory — resource-constrained, SD card storage, power-efficient',
        defaultPaas: 'dockge',
        defaultTlsMode: 'self-signed',
        defaultComputeTier: 'low',
        defaultMemoryLimitMB: 256,
        defaultCpuShares: 512,
        defaultStorageDriver: 'overlay2',
        defaultDnsStrategy: 'mdns',
        defaultBackupTarget: 'local-nas',
        detectionCriteria: [
          'ARM architecture detected',
          'Memory < 4GB',
          'Raspberry Pi model string in /proc/device-tree/model',
        ],
        hardwareProfile: {
          typicalRam: '1-8 GB',
          typicalCpu: '4 ARM cores',
          typicalStorage: 'SD card or USB SSD, 32-256GB',
          networkType: 'LAN, 100Mbps-1Gbps',
        },
        cueDefaults: `if _context == "pi" {
  paas: type: "dockge"
  tls: mode: "self-signed"
  resources: { memoryLimitMB: 256, cpuShares: 512 }
  storage: driver: "overlay2"
}`,
      },
    }),
  ]);

  console.log(`Created ${contexts.length} context defaults`);

  // ==========================================================================
  // ADD-ONS (Architecture v4)
  // ==========================================================================

  const addons = await Promise.all([
    prisma.addOn.upsert({
      where: { name: 'monitoring' },
      update: {},
      create: {
        name: 'monitoring',
        displayName: 'Monitoring Stack',
        description: 'Full observability with Prometheus, Grafana, and Alertmanager for metrics, dashboards, and alerting',
        category: 'observability',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.BASE, ArchitecturePattern.MODERN, ArchitecturePattern.HA],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD],
        minMemoryMB: 512,
        includedTools: ['prometheus', 'grafana', 'alertmanager'],
        autoActivate: false,
        tags: ['monitoring', 'metrics', 'alerting', 'dashboards'],
        author: 'kombify Team',
      },
    }),
    prisma.addOn.upsert({
      where: { name: 'backup' },
      update: {},
      create: {
        name: 'backup',
        displayName: 'Backup & Restore',
        description: 'Automated backups with Restic to S3, B2, or local NAS targets',
        category: 'data',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.BASE, ArchitecturePattern.MODERN, ArchitecturePattern.HA],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD, NodeContext.PI],
        minMemoryMB: 128,
        includedTools: ['restic'],
        autoActivate: false,
        tags: ['backup', 'restore', 'disaster-recovery', 's3'],
        author: 'kombify Team',
      },
    }),
    prisma.addOn.upsert({
      where: { name: 'vpn-overlay' },
      update: {},
      create: {
        name: 'vpn-overlay',
        displayName: 'VPN Mesh Overlay',
        description: 'Optional Headscale/Tailscale mesh VPN for connecting nodes across networks. Not required - identity stack (LLDAP+Step-CA+PocketID) is the recommended approach.',
        category: 'networking',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.MODERN, ArchitecturePattern.HA],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD],
        minMemoryMB: 64,
        includedTools: ['headscale'],
        autoActivate: false,
        autoActivateCondition: 'User explicitly enables VPN overlay addon',
        tags: ['vpn', 'mesh', 'headscale', 'tailscale', 'wireguard', 'optional'],
        author: 'kombify Team',
      },
    }),
    prisma.addOn.upsert({
      where: { name: 'gpu-workloads' },
      update: {},
      create: {
        name: 'gpu-workloads',
        displayName: 'GPU Workloads',
        description: 'NVIDIA/AMD GPU passthrough for AI, ML, and compute workloads',
        category: 'compute',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.BASE, ArchitecturePattern.MODERN],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD],
        minMemoryMB: 2048,
        requiresGpu: true,
        includedTools: ['nvidia-container-toolkit'],
        autoActivate: true,
        autoActivateCondition: 'Node reports GPU capability via agent hardware report',
        tags: ['gpu', 'nvidia', 'ai', 'ml', 'compute'],
        author: 'kombify Team',
      },
    }),
    prisma.addOn.upsert({
      where: { name: 'media' },
      update: {},
      create: {
        name: 'media',
        displayName: 'Media Server',
        description: 'Jellyfin media server with *arr stack for automated media management',
        category: 'applications',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.BASE, ArchitecturePattern.MODERN],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD, NodeContext.PI],
        minMemoryMB: 512,
        includedTools: ['jellyfin', 'sonarr', 'radarr', 'prowlarr'],
        autoActivate: false,
        tags: ['media', 'jellyfin', 'arr', 'streaming'],
        author: 'kombify Team',
      },
    }),
    prisma.addOn.upsert({
      where: { name: 'smart-home' },
      update: {},
      create: {
        name: 'smart-home',
        displayName: 'Smart Home',
        description: 'Home Assistant with MQTT broker and Zigbee2MQTT for IoT device management',
        category: 'iot',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.BASE],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.PI],
        minMemoryMB: 256,
        includedTools: ['home-assistant', 'mosquitto', 'zigbee2mqtt'],
        autoActivate: false,
        conflictsWith: [],
        tags: ['iot', 'smart-home', 'home-assistant', 'mqtt', 'zigbee'],
        author: 'kombify Team',
      },
    }),
    prisma.addOn.upsert({
      where: { name: 'ci-cd' },
      update: {},
      create: {
        name: 'ci-cd',
        displayName: 'CI/CD Pipeline',
        description: 'Gitea git hosting with Drone CI for self-hosted continuous integration',
        category: 'development',
        version: '1.0.0',
        lifecycleState: LifecycleState.DRAFT,
        compatibleKits: [ArchitecturePattern.BASE, ArchitecturePattern.MODERN, ArchitecturePattern.HA],
        compatibleContexts: [NodeContext.LOCAL, NodeContext.CLOUD],
        minMemoryMB: 512,
        includedTools: ['gitea', 'drone-ci'],
        autoActivate: false,
        tags: ['ci-cd', 'gitea', 'drone', 'git', 'automation'],
        author: 'kombify Team',
      },
    }),
  ]);

  console.log(`Created ${addons.length} add-ons`);

  // ==========================================================================
  // TOOL CATEGORIES
  // ==========================================================================

  const toolCategories = await Promise.all([
    prisma.toolCategory.upsert({
      where: { slug: 'identity' },
      update: {},
      create: {
        slug: 'identity',
        displayName: 'Identity & Directory',
        description: 'LDAP directories, PKI/CA, SSO connectors',
        layer: LayerType.FOUNDATION,
        standardTool: 'lldap',
        alternativeTools: ['openldap', 'freeipa'],
        discoveryKeywords: ['ldap', 'directory', 'identity provider', 'self-hosted'],
        firecrawlQueries: ['self-hosted LDAP server Docker', 'lightweight identity provider container'],
        evaluationCriteria: {
          mustHave: ['Docker image', 'LDAP protocol', 'Web UI'],
          niceToHave: ['ARM support', 'Low memory footprint', '< 100MB image'],
          dealBreakers: ['No Docker support', 'Requires Java', 'Abandoned project'],
        },
      },
    }),
    prisma.toolCategory.upsert({
      where: { slug: 'reverse-proxy' },
      update: {},
      create: {
        slug: 'reverse-proxy',
        displayName: 'Reverse Proxy & Ingress',
        description: 'Load balancers, TLS termination, ingress controllers',
        layer: LayerType.PLATFORM,
        standardTool: 'traefik',
        alternativeTools: ['caddy', 'nginx-proxy-manager', 'haproxy'],
        discoveryKeywords: ['reverse proxy', 'load balancer', 'ingress', 'Docker'],
        firecrawlQueries: ['self-hosted reverse proxy Docker automatic TLS', 'traefik alternative container'],
        evaluationCriteria: {
          mustHave: ['Docker label/API discovery', 'Automatic TLS', 'Multi-service routing'],
          niceToHave: ['Dashboard', 'Middleware support', 'gRPC support'],
          dealBreakers: ['Manual config only', 'No Docker support'],
        },
      },
    }),
    prisma.toolCategory.upsert({
      where: { slug: 'paas' },
      update: {},
      create: {
        slug: 'paas',
        displayName: 'Platform-as-a-Service',
        description: 'Self-hosted PaaS for deploying applications via git or Docker',
        layer: LayerType.PLATFORM,
        standardTool: 'dokploy',
        alternativeTools: ['coolify', 'caprover', 'portainer'],
        discoveryKeywords: ['self-hosted paas', 'heroku alternative', 'docker deployment platform'],
        firecrawlQueries: ['self-hosted PaaS Docker deployment', 'dokploy coolify alternative'],
        evaluationCriteria: {
          mustHave: ['Docker Compose support', 'Web UI', 'Domain management'],
          niceToHave: ['Git push deploy', 'Database management', 'Multi-node'],
          dealBreakers: ['No Docker support', 'Cloud-only'],
        },
      },
    }),
    prisma.toolCategory.upsert({
      where: { slug: 'monitoring' },
      update: {},
      create: {
        slug: 'monitoring',
        displayName: 'Monitoring & Observability',
        description: 'Uptime monitoring, metrics, dashboards, alerting',
        layer: LayerType.APPLICATION,
        standardTool: 'uptime-kuma',
        alternativeTools: ['beszel', 'netdata', 'prometheus', 'grafana'],
        discoveryKeywords: ['self-hosted monitoring', 'uptime', 'server metrics', 'dashboard'],
        firecrawlQueries: ['lightweight self-hosted monitoring Docker', 'uptime monitoring alternative'],
        evaluationCriteria: {
          mustHave: ['Docker image', 'Web dashboard', 'Alerting'],
          niceToHave: ['ARM support', 'Low memory', 'API', 'Integrations'],
          dealBreakers: ['Requires external service', 'No Docker'],
        },
      },
    }),
    prisma.toolCategory.upsert({
      where: { slug: 'platform-identity' },
      update: {},
      create: {
        slug: 'platform-identity',
        displayName: 'Platform Identity & Auth Proxy',
        description: 'Auth proxies, SSO middleware, OIDC providers for platform-level access control',
        layer: LayerType.PLATFORM,
        standardTool: 'tinyauth',
        alternativeTools: ['pocketid', 'authelia', 'authentik'],
        discoveryKeywords: ['auth proxy', 'SSO middleware', 'OIDC provider', 'self-hosted'],
        firecrawlQueries: ['lightweight auth proxy Docker traefik', 'self-hosted SSO OIDC provider'],
        evaluationCriteria: {
          mustHave: ['Traefik integration', 'Docker support', 'LDAP/OIDC'],
          niceToHave: ['Low memory', 'Simple setup', '2FA'],
          dealBreakers: ['No reverse proxy integration', 'Cloud-only'],
        },
      },
    }),
    prisma.toolCategory.upsert({
      where: { slug: 'management' },
      update: {},
      create: {
        slug: 'management',
        displayName: 'Container Management',
        description: 'Docker management UIs, log viewers, container orchestration tools',
        layer: LayerType.PLATFORM,
        standardTool: 'dozzle',
        alternativeTools: ['portainer', 'dockge', 'lazydocker'],
        discoveryKeywords: ['docker management ui', 'container logs', 'docker dashboard'],
        firecrawlQueries: ['self-hosted Docker management UI', 'container log viewer Docker'],
      },
    }),
  ]);

  console.log(`Created ${toolCategories.length} tool categories`);

  // ==========================================================================
  // N8N WORKFLOW REGISTRY
  // ==========================================================================

  const n8nWorkflows = await Promise.all([
    prisma.n8nWorkflow.upsert({
      where: { workflowId: 'tool-discovery-scan' },
      update: {},
      create: {
        workflowId: 'tool-discovery-scan',
        name: 'Tool Discovery Scan',
        description: 'Searches for new self-hosted tools via Firecrawl, enriches with AI, and proposes additions to the tool inventory',
        jobType: JobType.TOOL_DISCOVERY,
        isActive: false, // Not yet configured
        cronSchedule: '0 6 * * 1', // Weekly Monday 6am
      },
    }),
    prisma.n8nWorkflow.upsert({
      where: { workflowId: 'version-check' },
      update: {},
      create: {
        workflowId: 'version-check',
        name: 'Tool Version Checker',
        description: 'Checks all approved tools for new versions via GitHub releases and Docker Hub tags',
        jobType: JobType.VERSION_CHECK,
        isActive: false,
        cronSchedule: '0 8 * * *', // Daily 8am
      },
    }),
    prisma.n8nWorkflow.upsert({
      where: { workflowId: 'security-scan' },
      update: {},
      create: {
        workflowId: 'security-scan',
        name: 'Security Vulnerability Scanner',
        description: 'Scans tool Docker images for known CVEs and checks for security advisories',
        jobType: JobType.SECURITY_SCAN,
        isActive: false,
        cronSchedule: '0 4 * * 0', // Weekly Sunday 4am
      },
    }),
    prisma.n8nWorkflow.upsert({
      where: { workflowId: 'cue-generation' },
      update: {},
      create: {
        workflowId: 'cue-generation',
        name: 'CUE Schema Generator',
        description: 'Generates CUE validation files from database, runs cue vet, and commits if valid',
        jobType: JobType.CUE_GENERATION,
        isActive: false,
      },
    }),
    prisma.n8nWorkflow.upsert({
      where: { workflowId: 'compatibility-check' },
      update: {},
      create: {
        workflowId: 'compatibility-check',
        name: 'Tool Compatibility Checker',
        description: 'Validates tool combinations across StackKits — checks port conflicts, resource budgets, dependency chains',
        jobType: JobType.COMPATIBILITY_CHECK,
        isActive: false,
        cronSchedule: '0 2 * * 3', // Weekly Wednesday 2am
      },
    }),
  ]);

  console.log(`Created ${n8nWorkflows.length} n8n workflow entries`);

  // ==========================================================================
  // CRAWL SOURCES (for scheduled tool discovery)
  // ==========================================================================

  const crawlSources = await Promise.all([
    prisma.crawlSource.upsert({
      where: { name: 'paas-firecrawl' },
      update: {},
      create: {
        name: 'paas-firecrawl',
        sourceType: 'firecrawl',
        query: 'self-hosted PaaS platform Docker deploy',
        targetCategory: 'paas',
        scheduleType: 'interval',
        scheduleValue: '1d',
        minStars: 100,
        priority: 10,
        isActive: true,
      },
    }),
    prisma.crawlSource.upsert({
      where: { name: 'monitoring-firecrawl' },
      update: {},
      create: {
        name: 'monitoring-firecrawl',
        sourceType: 'firecrawl',
        query: 'self-hosted monitoring observability Prometheus Grafana alternative',
        targetCategory: 'monitoring',
        scheduleType: 'interval',
        scheduleValue: '1d',
        minStars: 50,
        priority: 8,
        isActive: true,
      },
    }),
    prisma.crawlSource.upsert({
      where: { name: 'reverse-proxy-firecrawl' },
      update: {},
      create: {
        name: 'reverse-proxy-firecrawl',
        sourceType: 'firecrawl',
        query: 'self-hosted reverse proxy load balancer Docker',
        targetCategory: 'reverse-proxy',
        scheduleType: 'interval',
        scheduleValue: '3d',
        minStars: 200,
        priority: 5,
        isActive: true,
      },
    }),
    prisma.crawlSource.upsert({
      where: { name: 'identity-firecrawl' },
      update: {},
      create: {
        name: 'identity-firecrawl',
        sourceType: 'firecrawl',
        query: 'self-hosted identity provider SSO OIDC authentication',
        targetCategory: 'identity',
        scheduleType: 'interval',
        scheduleValue: '7d',
        minStars: 100,
        priority: 3,
        isActive: true,
      },
    }),
    prisma.crawlSource.upsert({
      where: { name: 'awesome-selfhosted' },
      update: {},
      create: {
        name: 'awesome-selfhosted',
        sourceType: 'awesome-list',
        sourceUrl: 'https://github.com/awesome-selfhosted/awesome-selfhosted',
        query: 'awesome-selfhosted',
        scheduleType: 'interval',
        scheduleValue: '7d',
        priority: 1,
        isActive: false, // Enable when awesome-list parser is ready
      },
    }),
  ]);

  console.log(`Created ${crawlSources.length} crawl sources`);

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

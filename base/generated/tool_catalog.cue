// =============================================================================
// GENERATED FILE - DO NOT EDIT DIRECTLY
// =============================================================================
// This file is auto-generated from the kombify-admin database.
// To modify the tool catalog, update the database and re-run the generator.
//
// Generated: 2026-02-11T13:27:29.121Z
// Source: kombify-admin/prisma/seed.ts → Tool + ToolCategory tables
// =============================================================================

package base

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

// =============================================================================
// TOOL CATEGORIES
// =============================================================================

#ToolCategories: {
  "identity": {
    slug:         "identity"
    displayName:  "Identity & Directory"
    layer:        "1"
    standardTool: "lldap"
    alternatives: ["openldap", "freeipa"]
  }
  "management": {
    slug:         "management"
    displayName:  "Container Management"
    layer:        "2"
    standardTool: "dozzle"
    alternatives: ["portainer", "dockge", "lazydocker"]
  }
  "paas": {
    slug:         "paas"
    displayName:  "Platform-as-a-Service"
    layer:        "2"
    standardTool: "dokploy"
    alternatives: ["coolify", "caprover", "portainer"]
  }
  "platform-identity": {
    slug:         "platform-identity"
    displayName:  "Platform Identity & Auth Proxy"
    layer:        "2"
    standardTool: "tinyauth"
    alternatives: ["pocketid", "authelia", "authentik"]
  }
  "reverse-proxy": {
    slug:         "reverse-proxy"
    displayName:  "Reverse Proxy & Ingress"
    layer:        "2"
    standardTool: "traefik"
    alternatives: ["caddy", "nginx-proxy-manager", "haproxy"]
  }
  "monitoring": {
    slug:         "monitoring"
    displayName:  "Monitoring & Observability"
    layer:        "3"
    standardTool: "uptime-kuma"
    alternatives: ["beszel", "netdata", "prometheus", "grafana"]
  }
}

// =============================================================================
// APPROVED TOOLS
// =============================================================================

#ToolCatalog: {
  "lldap": {
    name:        "lldap"
    displayName: "LLDAP"
    description: "Lightweight LDAP server for user/group directory services"
    layer:       "1"
    category:    "identity"
    image:       "lldap/lldap"
    defaultTag:  "stable"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "step-ca": {
    name:        "step-ca"
    displayName: "Step-CA"
    description: "Private certificate authority for mTLS and internal PKI"
    layer:       "1"
    category:    "identity"
    image:       "smallstep/step-ca"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "dockge": {
    name:        "dockge"
    displayName: "Dockge"
    description: "Docker Compose stack manager with web UI"
    layer:       "2"
    category:    "management"
    image:       "louislam/dockge"
    defaultTag:  "1"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "dozzle": {
    name:        "dozzle"
    displayName: "Dozzle"
    description: "Real-time Docker log viewer"
    layer:       "2"
    category:    "management"
    image:       "amir20/dozzle"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "portainer": {
    name:        "portainer"
    displayName: "Portainer"
    description: "Container management UI for Docker and Kubernetes"
    layer:       "2"
    category:    "management"
    image:       "portainer/portainer-ce"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "coolify": {
    name:        "coolify"
    displayName: "Coolify"
    description: "Self-hosted Heroku/Netlify alternative with git deployments"
    layer:       "2"
    category:    "paas"
    image:       "ghcr.io/coollabsio/coolify"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "dokploy": {
    name:        "dokploy"
    displayName: "Dokploy"
    description: "Self-hosted PaaS for deploying applications with Docker"
    layer:       "2"
    category:    "paas"
    image:       "dokploy/dokploy"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "pocketid": {
    name:        "pocketid"
    displayName: "PocketID"
    description: "Lightweight OIDC provider with LDAP sync"
    layer:       "2"
    category:    "platform-identity"
    image:       "stonith404/pocket-id"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "tinyauth": {
    name:        "tinyauth"
    displayName: "TinyAuth"
    description: "Lightweight authentication proxy for Traefik"
    layer:       "2"
    category:    "platform-identity"
    image:       "ghcr.io/steveiliop56/tinyauth"
    defaultTag:  "v3"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "traefik": {
    name:        "traefik"
    displayName: "Traefik"
    description: "Cloud-native reverse proxy and load balancer"
    layer:       "2"
    category:    "reverse-proxy"
    image:       "traefik"
    defaultTag:  "v3.1"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "beszel": {
    name:        "beszel"
    displayName: "Beszel"
    description: "Lightweight server metrics and monitoring dashboard"
    layer:       "3"
    category:    "monitoring"
    image:       "henrygd/beszel"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "netdata": {
    name:        "netdata"
    displayName: "Netdata"
    description: "Real-time performance and health monitoring"
    layer:       "3"
    category:    "monitoring"
    image:       "netdata/netdata"
    defaultTag:  "stable"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "uptime-kuma": {
    name:        "uptime-kuma"
    displayName: "Uptime Kuma"
    description: "Self-hosted monitoring tool for endpoints and services"
    layer:       "3"
    category:    "monitoring"
    image:       "louislam/uptime-kuma"
    defaultTag:  "1"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
  "whoami": {
    name:        "whoami"
    displayName: "Whoami"
    description: "Simple HTTP request info service for testing"
    layer:       "3"
    category:    "utility"
    image:       "traefik/whoami"
    defaultTag:  "latest"
    supportsArm: false
    supportsX86: true
    minMemoryMB: 0
  }
}

# Deployment Contract - StackKits

> **Version:** 1.0  
> **Last Updated:** 2026-01-28  
> **Component:** kombify StackKits (Infrastructure Templates)

---

## 🎯 Component Overview

**StackKits** provides pre-built, validated CUE schemas and infrastructure templates for common homelab configurations.

| Property | Value |
|----------|-------|
| **Type** | CUE Schemas + Go Tooling + Documentation Site |
| **Production URL** | `https://stackkits.kombify.io` |
| **Azure Resource** | Container App: `ca-stackkits-web-prod` (website) |
| **Container Registry** | `acrkombifyprod.azurecr.io/stackkits-web` |

---

## � Domain Routing (Azure Front Door)

> **⚠️ IMPORTANT**: All kombify.io subdomains are routed through Azure Front Door.  
> See [AZURE_INFRASTRUCTURE.md](https://github.com/kombify/kombify-administration/blob/main/docs/AZURE_INFRASTRUCTURE.md) for the complete routing architecture.

| Property | Value |
|----------|-------|
| **Public URL** | `https://stackkits.kombify.io` |
| **AFD Profile** | `afd-kombify-prod` |
| **Origin Group** | `og-stackkits` |
| **Route Name** | `route-stackkits` |

**To update routing**, modify the AFD configuration in `rg-kombify-prod`, NOT DNS records.

---

## �🏗️ Architecture Position

```
┌─────────────────────────────────────────────────────────────┐
│                    kombify Platform                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────────────┐     ┌──────────────────┐             │
│   │  kombify        │     │  kombify Stack  │             │
│   │  (Portal)        │     │  (Core API)     │             │
│   └────────┬─────────┘     └────────┬─────────┘             │
│            │                        │                        │
│            │   Uses templates from  │                        │
│            └────────────┬───────────┘                        │
│                         │                                    │
│                         ▼                                    │
│            ┌──────────────────────┐                         │
│            │     StackKits        │◀── YOU ARE HERE         │
│            │  (CUE Templates)     │                         │
│            └──────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Package Structure

```
StackKits/
├── base/              # Core CUE schemas (types, validation)
│   ├── stackkit.cue
│   ├── network.cue
│   ├── security.cue
│   ├── observability.cue
│   └── ...
├── base-homelab/      # Single Environment Kit
├── dev-homelab/       # Developer Kit
├── ha-homelab/        # High-Availability Kit
├── modern-homelab/    # Multi-Node Kit (planned)
├── cmd/               # Go CLI (stackkit)
├── internal/          # Go internal packages
├── pkg/               # Go public libraries
├── tests/             # CUE + Go tests
├── docs/              # Documentation
└── website-v2/        # Documentation site (SvelteKit)
```

---

## 🔐 Azure Resources (Website Only)

### Resource Group
- **Name:** `rg-kombify-prod`

### Required Azure Resources

| Resource | Name | Purpose |
|----------|------|---------|
| Container App | `ca-stackkits-web-prod` | Documentation website |
| Container Registry | `acrkombifyprod` | Docker images |

---

## 🚀 Deployment Pipeline

### Trigger Conditions
- **Website:** Push to `main` with changes in `website-v2/`
- **Package:** Manual release process

### Pipeline Stages

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   CI        │───▶│   CUE       │───▶│   Website   │
│   (Tests)   │    │   Validate  │    │   Deploy    │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## 🧪 CI/CD Workflows

### `.github/workflows/ci.yml`
**Purpose:** Validate CUE schemas and Go code  
**Trigger:** All pushes and PRs

**Jobs:**
1. `lint` - Go vet, golangci-lint
2. `test` - Go tests with coverage
3. `cue-validate` - CUE schema validation
4. `build` - Go build verification

### CUE Validation
```bash
# Validate all schemas
cue vet ./...

# Validate specific stack
cue vet ./base-homelab/...
```

---

## 📋 Pre-Release Checklist

- [ ] All CUE schemas validate (`cue vet ./...`)
- [ ] Go tests pass (`go test ./...`)
- [ ] Documentation updated
- [ ] Version bumped in appropriate files
- [ ] CHANGELOG updated

---

## 🛠️ Local Development

### Prerequisites
- Go 1.22+
- CUE CLI (`go install cuelang.org/go/cmd/cue@latest`)
- Make

### Quick Start
```bash
# Validate schemas
make validate

# Run tests
make test

# Build CLI
make build
```

### Working with CUE
```bash
# Evaluate a schema
cue eval ./base-homelab/

# Export as YAML
cue export ./base-homelab/ --out yaml

# Validate user config
cue vet user-config.cue ./base-homelab/
```

---

## 📚 Related Documentation

- [CUE Language Guide](https://cuelang.org/docs/)
- [StackKits Docs](./docs/)
- [Azure Website Deployment](./docs/AZURE_WEBSITE_DEPLOYMENT.md)

---

## 🔗 Cross-Repository Dependencies

| Repo | Dependency Type | Notes |
|------|-----------------|-------|
| kombify Stack | Consumer | Stack loads StackKit definitions |
| docs | Documentation | Published to docs site |
| kombify Cloud | Display | Shows available templates |

---

## 📝 Schema Development Guidelines

### Adding a New Stack

1. Create directory: `my-stack/`
2. Add schema files: `service.cue`, `network.cue`, etc.
3. Import base schemas: `import "stackkits.io/base"`
4. Add validation tests
5. Update documentation

### Schema Conventions

```cue
package mystackkit

import "github.com/kombihq/stackkits/base"

// #MyService extends the base service
#MyService: base.#ServiceDefinition & {
    // Custom fields here
    customField: string
}
```

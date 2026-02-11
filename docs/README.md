# Project Documentation

This folder contains the **canonical** project docs for StackKits Architecture v4.

## Architecture & Strategy

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE_V4.md](ARCHITECTURE_V4.md) | **Canonical architecture** — StackKit patterns, Node-Context, Add-Ons, Progressive Capability Model |
| [ROADMAP.md](ROADMAP.md) | Milestones M0–M9 + backlog (single source of truth) |
| [EVALUATION_REPORT_2026-02-07.md](EVALUATION_REPORT_2026-02-07.md) | Comprehensive code & schema evaluation |
| [TARGET_STATE.md](TARGET_STATE.md) | Product vision and functional requirements |
| [CHANGELOG.md](CHANGELOG.md) | Release history (Keep a Changelog) |

## Reference Guides

| Document | Purpose |
|----------|---------|
| [CLI.md](CLI.md) | Command reference for the `stackkit` CLI |
| [creating-stackkits.md](creating-stackkits.md) | Authoring guide for StackKits (needs v4 update) |
| [stack-spec-reference.md](stack-spec-reference.md) | Stack spec YAML schema reference (needs v4 update) |
| [templates.md](templates.md) | OpenTofu template patterns (needs v4 update) |
| [NETWORKING_STANDARDS.md](NETWORKING_STANDARDS.md) | Networking conventions (local-first) |
| [SETTINGS-CLASSIFICATION.md](SETTINGS-CLASSIFICATION.md) | Settings taxonomy (Perma vs Flexible) |

## Operations

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deployment guide — CI/CD, Azure, local dev |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Development setup, prerequisites, project structure |
| [TESTING.md](TESTING.md) | Test types and CI requirements |
| [Cleanup-Plan.md](Cleanup-Plan.md) | Project cleanup protocol (PSCP) |
| [AZURE_WEBSITE_DEPLOYMENT.md](AZURE_WEBSITE_DEPLOYMENT.md) | Marketing site deployment |
| [ADR/](ADR/) | Architecture Decision Records (ADR-0001 – ADR-0003) |

## Business

| Document | Purpose |
|----------|---------|
| [business/](business/) | Business plan drafts (A–F) |

## Archived

Outdated documentation is in [`_archive/`](_archive/). See [_archive/README.md](_archive/README.md) for details.

## Conventions

- Keep this folder small: only actively maintained docs.
- Outdated docs go to `_archive/` with a note about what supersedes them.
- Architecture v4 is the **only** current architecture — do not reference v3 concepts (variants, K8s, node-count StackKits).


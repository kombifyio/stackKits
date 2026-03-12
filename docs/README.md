# Project Documentation

This folder contains the **canonical** project docs for StackKits Architecture v4.

## Architecture & Design (Current)

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE_V4.md](ARCHITECTURE_V4.md) | **Canonical architecture** — StackKit patterns, Node-Context, Add-Ons, Progressive Capability Model |
| [IDENTITY-STACKKITS.md](IDENTITY-STACKKITS.md) | Identity architecture within homelabs (TinyAuth, PocketID, LLDAP, Step-CA, zero-trust) |
| [IDENTITY-PLATFORM.md](IDENTITY-PLATFORM.md) | Platform/SaaS identity (kombifySphere, multi-tenancy, federation) |
| [NETWORK-SECURITY-STACKKITS_1.md](NETWORK-SECURITY-STACKKITS_1.md) | Network security, container hardening, defense-in-depth model |
| [SETTINGS-CLASSIFICATION.md](SETTINGS-CLASSIFICATION.md) | Settings taxonomy (Perma vs Flexible) |
| [ROADMAP.md](ROADMAP.md) | Milestones M0–M9 (single source of truth for planning) |
| [RELEASE_PLAN_2026-02-21.md](RELEASE_PLAN_2026-02-21.md) | Release plan |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

## Reference Guides

| Document | Purpose |
|----------|---------|
| [CLI.md](CLI.md) | Command reference for the `stackkit` CLI |
| [creating-stackkits.md](creating-stackkits.md) | Authoring guide for StackKits |
| [stack-spec-reference.md](stack-spec-reference.md) | Stack spec YAML schema reference |
| [license-compliance-saas.md](license-compliance-saas.md) | License compliance for all tools |

## Operations

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Deployment guide |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Development setup and project structure |
| [TESTING.md](TESTING.md) | Test types and CI requirements |
| [ADR/](ADR/) | Architecture Decision Records (ADR-0001 – ADR-0004) |

## Research (Reference)

| Document | Purpose |
|----------|---------|
| [ha-kit-research.md](ha-kit-research.md) | High Availability Kit research notes |
| [docker-swarm-ecosystem.md](docker-swarm-ecosystem.md) | Docker Swarm ecosystem analysis |
| [stackkits-comparison.md](stackkits-comparison.md) | StackKit pattern comparison |

## Conventions

- Keep this folder small: only actively maintained docs.
- Outdated docs are deleted, not archived. Git history preserves everything.
- Architecture v4 is the **only** current architecture — do not reference v3 concepts.

# ADR-0001: Documentation Standard

- **Status:** Accepted
- **Date:** 2026-01-22

## Context

The StackKits repository contained mixed documentation styles, outdated files, and a lack of clear separation between "current state" and "target vision." This led to confusion about what features were actually implemented versus planned.

## Decision

We will adopt a strict documentation framework to ensure clarity and maintainability.

1.  **Core Docs live in `docs/`:**
    - `docs/STATUS_QUO.md`: The honest, verifiable current state.
    - `docs/TARGET_STATE.md`: The agreed-upon product vision / target.
    - `docs/ARCHITECTURE.md`: High-level technical design.
    - `docs/ROADMAP.md`: Milestones + backlog (single source of truth).
    - `docs/CHANGELOG.md`: Version history.
    - `docs/CLI.md`: CLI reference.

2.  **No in-repo archive folder:**
    - Prefer git history (tags/branches) for retrieval.
    - If long-term storage is needed, use a separate external archive repo.

3.  **ADR Process:**
    - Architectural decisions will be recorded in `ADR/` using this template.
    - Format: `ADR-XXXX-title.md`.

## Consequences

- **Benefit:** instant clarity for new contributors on what is real vs. planned.
- **Benefit:** Cleaning up `docs/` makes the repo more professional.
- **Maintenance:** Requires discipline to update `STATUS_QUO.md` as features are completed.

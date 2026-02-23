# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

---

## Infrastructure: DNS & Azure Front Door

**CRITICAL: Read this before making ANY infrastructure or domain-related changes.**

- The domain `kombify.io` is registered at **Spaceship** (NOT Azure)
- A **wildcard CNAME** record `*.kombify.io` points to **Azure Front Door (AFD)**
- AFD manages ALL routing for every `*.kombify.io` subdomain
- New subdomains do NOT require DNS/CNAME changes -- the wildcard covers them automatically
- To add a new subdomain, configure a new **AFD routing rule** pointing to the appropriate Azure backend
- **NEVER ask the user to create CNAME records** -- the wildcard already handles this
- Azure Front Door resource: `afd-kombify-prod` in resource group `rg-kombify-prod`

This project is deployed to: **stackkits.kombify.io** (marketing website)

---

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds


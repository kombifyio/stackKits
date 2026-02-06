# StackKits Project Configuration

## About StackKits

StackKits is a modular homelab infrastructure management toolkit that uses CUE schemas for configuration validation and service orchestration.

### Project Goals
- Provide reusable, composable infrastructure components
- Enforce configuration validation through CUE schemas
- Enable declarative homelab management
- Support multiple deployment targets (Docker, Podman, Kubernetes)

### Current State
- **Branch**: dev0.1
- **Focus**: CUE schema improvements and validation framework
- **Recent Work**: Consolidating schema definitions, improving validation
- **Project Path**: `C:\Users\mako1\OneDrive\Dokumente\GitHub\StackKits`

### Key Principles
- Schema-first development
- Backwards compatibility in schema changes
- Documentation-driven design
- Architecture Decision Records (ADRs) for major changes
- Modular, composable architecture

---

## Technology Stack

### CUE Language
- **Version**: Latest stable
- **Purpose**: Schema definitions, configuration validation, code generation
- **Documentation**: https://cuelang.org/docs/
- **Key Features**: Type safety, constraint validation, code generation

### Containerization
- Docker and Podman support
- Container-first architecture
- Service isolation and orchestration
- Declarative container configurations

### Infrastructure as Code
- Declarative configuration management
- Git-based version control for all configs
- Reproducible deployments
- Schema-validated configurations

### Configuration Management
- CUE for schema definitions and validation
- YAML/JSON for actual configurations
- Git for versioning and collaboration

### Task Management
- **Beads**: Git-backed, AI-optimized task tracker with dependency graphs
- **Location**: `C:\Users\mako1\.claude\tools\beads`
- **Purpose**: Structured memory for coding agents, dependency-aware task tracking

### AI Enhancement Tools
- **Obra's Superpowers**: TDD, debugging, planning, autonomous execution workflows
- **VoltAgent Subagents**: Domain-specific infrastructure specialists (DevOps, Terraform, K8s, Security)
- **Anthropic Document Skills**: Production-grade document manipulation (PDF, DOCX, PPTX, XLSX)

---

## Directory Structure

```
StackKits/
├── schemas/              # CUE schema definitions (CORE)
│   ├── base/            # Base schema types and primitives
│   ├── services/        # Service-specific schemas
│   └── validation/      # Validation rules and constraints
│
├── stacks/              # Service stack configurations
│   ├── base-homelab/    # Core homelab services (required)
│   ├── monitoring/      # Monitoring and observability stack
│   ├── media/           # Media server stack
│   └── [other-stacks]/  # Additional service stacks
│
├── docs/                # Architecture and development guides
│   ├── ARCHITECTURE.md  # Overall system design
│   └── creating-stackkits.md  # Developer guide for new stacks
│
├── ADR/                 # Architecture Decision Records
│   └── [numbered-adrs]/ # Decision history with rationale
│
├── scripts/             # Utility scripts
│   ├── validate/        # Validation scripts
│   └── deploy/          # Deployment automation
│
└── tests/               # Test suites
    ├── schema-tests/    # CUE schema validation tests
    └── integration/     # Integration testing
```

### File Naming Conventions
- **CUE files**: `snake_case.cue`
- **Stack configs**: `stack-name/` directories
- **Documentation**: `UPPERCASE.md` for major docs, `lowercase-hyphenated.md` for guides
- **ADRs**: `NNN-short-title.md` (e.g., `001-use-cue-schemas.md`)

---

## Development Standards

### CUE Validation (CRITICAL)

**Rule**: ALL CUE changes MUST pass validation before commit.

```bash
# Run before EVERY commit - non-negotiable
cue vet ./schemas/...

# If validation fails, fix errors - NEVER commit invalid schemas
```

**Why This Matters**: Invalid schemas break the entire validation framework and can cause cascading failures across all stacks.

### Schema Backwards Compatibility

**Rule**: Schema changes MUST maintain compatibility with existing configurations.

#### Compatibility Guidelines

| Change Type | Safe? | Action Required |
|------------|-------|-----------------|
| Add optional field | ✅ Yes | Document the new field |
| Add field with default | ✅ Yes | Ensure default is sensible |
| Remove field | ❌ No | Requires major version bump |
| Change field type | ❌ No | Requires migration path |
| Add required field | ❌ No | Make optional or provide default |
| Rename field | ❌ No | Requires deprecation period |
| Tighten constraints | ⚠️ Maybe | Check existing configs first |
| Loosen constraints | ✅ Yes | Usually safe |

#### Example: Safe Schema Evolution

```cue
// ❌ WRONG - Breaks existing configs
#Service: {
    name: string
    new_required_field: string  // Breaking change!
}

// ✅ CORRECT - Backwards compatible
#Service: {
    name: string
    // Option 1: Make it optional
    new_optional_field?: string
    // Option 2: Provide a default
    new_field_with_default: string | *"default_value"
}
```

### Testing Requirements
- Schema changes require validation tests
- New stacks require integration tests
- Test against existing stack configurations
- Validate error messages are clear and actionable

### Documentation Standards
- **New schemas** → Add inline CUE comments explaining purpose and usage
- **Schema changes** → Update relevant docs/ files
- **Architectural changes** → Create ADR in /ADR/
- **New stacks** → Create README.md in stack directory with:
  - Purpose and services included
  - Configuration examples
  - Dependencies
  - Common operations

### ADR Creation Triggers

Create an Architecture Decision Record when:
- Choosing between multiple schema design patterns
- Adding major new functionality or capabilities
- Changing validation approaches or frameworks
- Selecting new technologies or major dependencies
- Making decisions that impact multiple stacks
- Changing deployment or orchestration strategies

**ADR Format**: Follow existing pattern in /ADR/ directory with:
- Context (what decision needs to be made)
- Decision (what was chosen)
- Consequences (positive and negative impacts)
- Alternatives considered

---

## Common Commands

### CUE Operations

```bash
# Validate all schemas (run before every commit)
cue vet ./schemas/...

# Validate specific schema
cue vet ./schemas/services/monitoring.cue

# Format CUE files
cue fmt ./schemas/...

# Export to YAML for inspection
cue export --out=yaml ./schemas/base/... > output.yaml

# Evaluate specific schema
cue eval ./schemas/services/monitoring.cue

# Check for errors with detailed output
cue vet -v ./schemas/...

# Validate with concrete values
cue vet ./schemas/services/monitoring.cue ./stacks/monitoring/config.yaml
```

### Testing Workflows

```bash
# Run schema validation tests
./scripts/test-schemas.sh

# Validate specific stack against schemas
./scripts/validate-stack.sh monitoring

# Run integration tests
./scripts/test-integration.sh

# Validate all stacks
for stack in stacks/*/; do
    cue vet ./schemas/... "$stack"/*.cue
done
```

### Stack Operations

```bash
# Deploy a stack (example)
./scripts/deploy-stack.sh base-homelab

# Validate stack configuration
cue vet ./schemas/... ./stacks/monitoring/

# Generate stack documentation
./scripts/generate-stack-docs.sh monitoring
```

### Git Workflow

```bash
# Before committing schema changes
cue vet ./schemas/...
cue fmt ./schemas/...
git diff  # Review changes

# Commit with descriptive message
git add schemas/services/new-service.cue
git commit -m "Add new service schema for X

- Define base service structure
- Add validation rules for Y
- Include examples in comments

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Architecture Patterns

### Schema Composition

StackKits uses CUE's embedding and unification for schema composition:

```cue
// Base service schema (in schemas/base/)
#Service: {
    name: string
    version: string
    enabled: bool | *true  // Default to enabled

    // Common service fields
    restart_policy?: string
    environment?: [string]: string
}

// Monitoring service extends base (in schemas/services/)
#MonitoringService: #Service & {
    metrics_port: int | *9090
    scrape_interval?: string | *"30s"

    // Additional monitoring-specific fields
    retention?: string | *"15d"
}

// Specific implementation in stack config
prometheus: #MonitoringService & {
    name: "prometheus"
    version: "v2.45.0"
    metrics_port: 9090
    retention: "30d"
}
```

### Configuration Inheritance

1. **Base schemas** define common structure
2. **Service schemas** extend base with service-specific fields
3. **Stack configs** provide concrete values
4. **Validation** occurs at build/deploy time

### Validation Strategy

1. Define strict schemas in `/schemas/`
2. Stack configurations reference and implement schemas
3. Validation happens automatically via `cue vet`
4. Clear, actionable error messages guide users
5. Type safety prevents configuration mistakes

### Error Handling Pattern

```cue
// Provide clear validation with helpful messages
#Port: int & >0 & <65536
#Port: {
    // If validation fails, error message helps user
    #_validate: #Port | error("Port must be between 1 and 65535")
}
```

---

## Workflow Examples

### Adding a New Service Stack

1. **Define Schema** (if new service type):
```bash
# Create service schema
nvim schemas/services/new-service.cue

# Define structure using CUE
#NewService: #Service & {
    // Service-specific fields
}
```

2. **Validate Schema**:
```bash
cue vet ./schemas/...
```

3. **Create Stack Directory**:
```bash
mkdir -p stacks/new-service
```

4. **Create Stack Configuration**:
```bash
# Create config that implements the schema
nvim stacks/new-service/config.cue
```

5. **Validate Stack**:
```bash
cue vet ./schemas/... ./stacks/new-service/
```

6. **Document**:
```bash
# Create stack README
nvim stacks/new-service/README.md
```

7. **Test & Commit**:
```bash
./scripts/test-integration.sh new-service
git add schemas/services/new-service.cue stacks/new-service/
git commit -m "Add new service stack"
```

### Modifying Existing Schemas

1. **Read Current Schema**:
```bash
# Understand existing structure
cat schemas/services/monitoring.cue
```

2. **Check Existing Usage**:
```bash
# Find all places using this schema
grep -r "MonitoringService" stacks/
```

3. **Plan Changes** (ensure backwards compatibility):
- Add optional fields or fields with defaults
- Never remove or rename fields
- Don't add required fields without defaults

4. **Implement Changes**:
```bash
nvim schemas/services/monitoring.cue
```

5. **Validate Against Existing Stacks**:
```bash
# Ensure existing stacks still validate
for stack in stacks/*/; do
    cue vet ./schemas/... "$stack" || echo "Failed: $stack"
done
```

6. **Update Documentation**:
```bash
# Update relevant docs
nvim docs/ARCHITECTURE.md
```

7. **Consider ADR** (if significant change):
```bash
# Document decision
nvim ADR/XXX-why-we-changed-monitoring-schema.md
```

### Creating Architecture Decision Records

1. **Identify Decision Point**:
- What choice needs to be made?
- Why is this significant?

2. **Create ADR**:
```bash
# Find next number
ls ADR/ | tail -1
# Create new ADR
nvim ADR/004-decision-title.md
```

3. **ADR Template**:
```markdown
# 4. [Decision Title]

Date: 2026-01-23
Status: Accepted

## Context
What is the issue we're facing?
What factors are driving this decision?

## Decision
What did we decide to do?
How will it be implemented?

## Consequences
### Positive
- What benefits does this bring?

### Negative
- What trade-offs are we making?

## Alternatives Considered
- Alternative 1: Why we didn't choose this
- Alternative 2: Why we didn't choose this
```

---

## Known Issues & Anti-Patterns

### Common CUE Validation Errors

#### Error: "field not allowed"
- **Cause**: Stack config has fields not defined in schema
- **Fix**: Either add field to schema (if valid) or remove from config
- **Example**:
```
// Error: field "invalid_field" not allowed
// Fix: Check schema definition, remove or add field
```

#### Error: "conflicting values"
- **Cause**: Multiple definitions with incompatible types
- **Fix**: Check type unification rules, ensure type compatibility
- **Example**:
```cue
// Conflict: string vs int
port: "8080"  // string
port: 8080    // int
// Fix: Use consistent types
```

#### Error: "incomplete value"
- **Cause**: Required field not provided
- **Fix**: Provide value or make field optional in schema
- **Example**:
```cue
// Error: field "name" is required but not provided
// Fix: Add name: "service-name" to config
```

### Schema Evolution Pitfalls

#### ❌ Anti-Pattern: Adding Required Fields Without Defaults
```cue
// DON'T DO THIS - breaks all existing configs
#Service: {
    name: string
    new_required_field: string  // Breaking change!
}
```

#### ✅ Correct Pattern: Make New Fields Optional or Defaulted
```cue
// DO THIS - backwards compatible
#Service: {
    name: string
    new_optional_field?: string
    // OR with a sensible default
    new_field_with_default: string | *"default_value"
}
```

#### ❌ Anti-Pattern: Changing Field Types
```cue
// DON'T DO THIS
#Service: {
    port: string  // Was string, changing to int breaks configs
    port: int     // Breaking change!
}
```

#### ✅ Correct Pattern: Add New Field, Deprecate Old
```cue
// DO THIS - gradual migration
#Service: {
    port_string?: string  // Deprecated, still supported
    port: int             // New field, preferred
}
```

### Configuration Gotchas

#### Issue: Circular Dependencies
- **Symptom**: `cue vet` hangs or reports cycle
- **Cause**: Schema A references B, B references A
- **Fix**: Refactor to remove cycle, use interfaces/definitions

#### Issue: Overly Strict Validation
- **Symptom**: Valid configs fail validation
- **Cause**: Schemas too restrictive
- **Fix**: Use disjunctions (`|`) to allow alternatives, provide escape hatches

#### Issue: Unclear Error Messages
- **Symptom**: Users don't understand validation failures
- **Cause**: No custom error messages in schemas
- **Fix**: Add explicit error messages using CUE's `error()` function

---

## Key Architecture References

### Essential Documentation
- **`/docs/ARCHITECTURE.md`**: Overall system design, component relationships
- **`/docs/creating-stackkits.md`**: Step-by-step guide for creating new stacks
- **`/ADR/`**: Complete history of architectural decisions with rationale

### External Resources
- **CUE Language**: https://cuelang.org/docs/
- **CUE Specification**: https://cuelang.org/docs/references/spec/
- **CUE Tutorials**: https://cuelang.org/docs/tutorials/

### Quick Reference Locations
- Schema definitions: `./schemas/`
- Service schemas: `./schemas/services/`
- Base types: `./schemas/base/`
- Stack configs: `./stacks/[stack-name]/`
- Validation scripts: `./scripts/validate/`
- Test suites: `./tests/`

---

## Project-Specific Workflows

### Daily Development Cycle
1. Pull latest changes: `git pull origin dev0.1`
2. Make schema or config changes
3. Validate continuously: `cue vet ./schemas/...`
4. Format code: `cue fmt ./schemas/...`
5. Test against stacks: `./scripts/validate-stack.sh [stack-name]`
6. Commit with validation passing
7. Push and create PR if ready

### Before Every Commit
```bash
# Required checks
cue vet ./schemas/...      # Must pass
cue fmt ./schemas/...      # Format code
git diff                    # Review changes

# Validate against existing stacks
for stack in stacks/*/; do
    cue vet ./schemas/... "$stack"
done
```

### Release Process
1. Ensure all schemas validate
2. Update version numbers if needed
3. Create/update ADRs for significant changes
4. Update CHANGELOG.md
5. Tag release in git
6. Generate documentation

---

## Self-Improvement Protocol

When working on StackKits, suggest updating this CLAUDE.MD when encountering:

### Document These Situations
- **New CUE Patterns**: Effective patterns for schema composition or validation
- **Validation Errors**: New error types and their solutions
- **Architecture Patterns**: Successful patterns for organizing schemas or stacks
- **Common Mistakes**: Errors that keep recurring
- **Workflow Improvements**: More efficient ways to accomplish tasks
- **Tool Usage**: Useful CUE commands or script combinations

### Update Process
1. **Identify** the learning (e.g., "Found a better way to validate ports")
2. **Draft** addition with specific section and exact wording
3. **Explain** why this improves future work on StackKits
4. **Ask** for user approval
5. **Update** this file if approved

### Integration Points
- CUE patterns documented here guide schema development
- Common errors help prevent repeated mistakes
- Workflow examples become templates for new work
- Architecture patterns inform design decisions

---

## Task Management with Beads

StackKits uses Beads for dependency-aware task tracking. Beads provides structured, git-backed memory for AI agents with explicit dependency management.

### Why Beads for StackKits

**Perfect fit for infrastructure work**:
- **Dependency Tracking**: Schema changes cascade to stacks - Beads tracks these relationships
- **Validation Ordering**: CUE validation order matters - dependencies ensure correct sequencing
- **Git-Native**: Tasks version with code, follow branches (dev0.1 → main)
- **Multi-Agent Safety**: Hash-based IDs prevent merge conflicts when multiple agents work in parallel
- **Context Preservation**: Closed tasks summarized to prevent context window bloat

### Beads Installation

**Location**: `C:\Users\mako1\.claude\tools\beads`

**Manual Setup** (Beads not yet on npm):
```bash
# Already cloned to ~/.claude/tools/beads
cd ~/.claude/tools/beads

# Build (if needed)
npm install

# Create symlink for global CLI access
npm link

# Verify installation
bd --version
```

**Initialize in StackKits**:
```bash
cd ~/OneDrive/Dokumente/GitHub/StackKits
bd init
```

### Before Starting Work

**Check for ready tasks** (no blocking dependencies):
```bash
bd ready
```

**View full task graph**:
```bash
bd list
bd list --tree  # Hierarchical view
bd list --status open  # Only open tasks
```

**View specific task**:
```bash
bd show bd-abc123
```

### Creating Tasks

**Create epic for major features**:
```bash
bd create "Schema validation improvements" --epic
```

**Create subtasks with parent relationship**:
```bash
# Create child task
bd create "Update base service schema" --parent bd-abc123

# Create sibling tasks
bd create "Migrate monitoring stack" --parent bd-abc123
bd create "Migrate media stack" --parent bd-abc123
```

**Add dependencies** (task X depends on task Y):
```bash
# monitoring-migration depends on schema-update completing first
bd dep add bd-monitoring bd-schema-update
```

**Example: Schema Change Workflow**:
```bash
# Create epic
bd create "Consolidate CUE base schemas" --epic
# Returns: Created bd-a1b2c3

# Create dependent tasks
bd create "Define new base.Service schema" --parent bd-a1b2c3
# Returns: Created bd-a1b2c3.1

bd create "Migrate base-homelab stack" --parent bd-a1b2c3
# Returns: Created bd-a1b2c3.2

bd create "Migrate monitoring stack" --parent bd-a1b2c3
# Returns: Created bd-a1b2c3.3

# Add dependency: monitoring depends on base-homelab
bd dep add bd-a1b2c3.3 bd-a1b2c3.2

# Check what's ready to work on
bd ready
# Shows: bd-a1b2c3.1 (no blockers)
#        bd-a1b2c3.2 (no blockers)
# Not shown: bd-a1b2c3.3 (blocked by bd-a1b2c3.2)
```

### During Work

**Assign task to self**:
```bash
bd assign bd-abc123 @me
```

**Update task status**:
```bash
bd status bd-abc123 in-progress
bd status bd-abc123 blocked
bd status bd-abc123 review
```

**Add comments and notes**:
```bash
bd comment bd-abc123 "See ADR/005-schema-validation.md for design decision"
bd comment bd-abc123 "Blocked on CUE bug: cuelang/cue#1234"
```

**Link to ADRs or commits**:
```bash
bd comment bd-abc123 "ADR: ADR/006-base-service-schema.md"
bd comment bd-abc123 "Implemented in commit: abc123def"
```

### Completing Tasks

**Close task when complete**:
```bash
bd close bd-abc123
```

**Verify dependent tasks unblocked**:
```bash
bd ready  # Should now show previously blocked tasks
```

**Task lifecycle**:
1. Created → `open` status
2. Work begins → `in-progress` status
3. Work complete → `closed` status
4. Closed tasks auto-summarized to preserve context

### Beads + Superpowers Integration

**Workflow Pattern**:
1. **Beads**: Defines *what* to do and *when* (dependency order)
2. **Superpowers**: Executes *how* (TDD, debugging, planning)
3. **Claude**: Follows Beads task order, uses Superpowers for execution

**Example Session**:
```bash
# Check ready tasks
bd ready
# Output: bd-a1b2c3.1 "Define new base.Service schema"

# Claude works on task using Superpowers TDD workflow:
# 1. Read existing schemas
# 2. Plan new schema structure
# 3. Write tests
# 4. Implement schema
# 5. Validate with `cue vet`

# Close when complete
bd close bd-a1b2c3.1

# Check next ready task
bd ready
# Output: bd-a1b2c3.2 "Migrate base-homelab stack"
```

### Common Beads Commands

| Command | Purpose |
|---------|---------|
| `bd init` | Initialize Beads in project |
| `bd create "Title"` | Create new task |
| `bd create "Title" --epic` | Create epic-level task |
| `bd create "Title" --parent bd-xxx` | Create subtask |
| `bd list` | List all tasks |
| `bd list --status open` | List only open tasks |
| `bd ready` | Show tasks with no blockers |
| `bd show bd-xxx` | Show task details |
| `bd dep add bd-A bd-B` | Add dependency (A depends on B) |
| `bd assign bd-xxx @me` | Assign to self |
| `bd comment bd-xxx "Note"` | Add comment |
| `bd close bd-xxx` | Close task |
| `bd status bd-xxx open` | Change status |

### Beads Best Practices for StackKits

**Schema Changes**:
- Create epic for schema work
- Subtasks for: design, implementation, migration, testing
- Add dependencies: migrations depend on schema implementation

**Stack Development**:
- Create task per stack
- Link to relevant schemas in comments
- Dependencies for shared infrastructure (base-homelab → other stacks)

**ADR Integration**:
- Create task for ADR creation
- Link ADR to implementation tasks
- Reference ADR number in task comments

**Branch Workflow**:
- Tasks follow git branches automatically
- Create tasks in dev0.1, they persist when merging to main
- Use task comments to track merge status

**Multi-Agent Work**:
- Hash-based IDs prevent conflicts
- Multiple agents can work on different ready tasks simultaneously
- Dependencies ensure safe parallel execution

### Troubleshooting Beads

**Beads command not found**:
```bash
# Ensure symlink created
cd ~/.claude/tools/beads
npm link

# Or use direct path
~/.claude/tools/beads/bd --version
```

**Tasks not showing**:
```bash
# Verify initialization
ls .beads/  # Should exist

# Re-initialize if needed
bd init
```

**Dependency conflicts**:
```bash
# View task dependencies
bd show bd-xxx

# Remove incorrect dependency
bd dep remove bd-A bd-B

# Add correct dependency
bd dep add bd-A bd-C
```

---

## Notes

This file is specifically for the StackKits project. For general Claude Code preferences, see the user-global CLAUDE.MD at `~/.claude/CLAUDE.md`.

**Project Hierarchy**:
1. This file (`.claude/CLAUDE.md`) - project-specific
2. User-global (`~/.claude/CLAUDE.md`) - general preferences
3. Local overrides (`.claude/CLAUDE.local.md`) - personal project tweaks (gitignored)

**Maintenance**:
- Update when new patterns emerge
- Add errors and solutions as discovered
- Keep architecture references current
- Remove outdated information
- Commit this file to git for team sharing

**Last Updated**: 2026-01-23

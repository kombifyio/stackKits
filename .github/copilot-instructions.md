# GitHub Copilot Instructions for StackKits

**Last Updated**: 2026-01-23

This file configures GitHub Copilot's behavior when working in the StackKits repository.

---

## Infrastructure: DNS & Azure Front Door

**CRITICAL: Read this before making ANY infrastructure or domain-related changes.**

- The domain `kombify.io` is registered at **Spaceship** (NOT Azure)
- A **wildcard CNAME** record `*.kombify.io` points to **Azure Front Door (AFD)**
- AFD manages ALL routing for every `*.kombify.io` subdomain
- New subdomains do NOT require DNS/CNAME changes -- the wildcard covers them automatically
- To add a new subdomain, configure a new **AFD routing rule** in Azure Portal
- **NEVER ask the user to create CNAME records** -- the wildcard already handles this
- Azure Front Door resource: `afd-kombify-prod` in resource group `rg-kombify-prod`
- There is NO standalone stackKits app -- `stackkits.kombify.io` is a marketing website only

---

## 🎯 Primary Workflow: Task-Driven Development with Beads

Before starting ANY work, GitHub Copilot should:

1. **Check for existing tasks**: Run `bd ready` to see tasks with no blockers
2. **Work on ready tasks first**: Prioritize existing tasks over creating new ones
3. **Update task status**: Mark tasks as in-progress, document work in comments
4. **Close completed tasks**: Use `bd close <task-id>` when done

---

## 🔧 Beads CLI Integration

### Beads Binary Location
```bash
# System-wide installation
C:/Users/mako1/go/bin/bd.exe

# Or use 'bd' if in PATH
bd --version
```

### Essential Commands

```bash
# Check what tasks are ready to work on (no dependencies blocking)
bd ready

# List all tasks
bd list

# Show task details
bd show <task-id>

# Create a new task
bd create "Task description"

# Create subtask
bd create "Subtask description" --parent <parent-task-id>

# Add dependency (task A depends on task B completing first)
bd dep add <task-A-id> <task-B-id>

# Assign task to yourself
bd assign <task-id> @me

# Update task status
bd status <task-id> in-progress
bd status <task-id> blocked
bd status <task-id> review

# Add comment
bd comment <task-id> "Your comment here"

# Close task when complete
bd close <task-id>
```

---

## 🤖 Autonomous Workflow for GitHub Copilot

### Before Starting Work

**Always run this first:**
```bash
bd ready
```

This shows tasks with no blocking dependencies. If there are ready tasks, work on those first before creating new tasks.

### When Starting a Task

```bash
# Assign to yourself
bd assign <task-id> @me

# Mark as in progress
bd status <task-id> in-progress

# Read task details
bd show <task-id>
```

### During Work

Document your progress:
```bash
# Add implementation notes
bd comment <task-id> "Implemented X using Y pattern"

# Link to commits
bd comment <task-id> "Fixed in commit abc123"

# Reference documentation
bd comment <task-id> "See ADR/005-architecture-decision.md"

# Report blockers
bd status <task-id> blocked
bd comment <task-id> "Blocked by: missing API endpoint"
```

### When Complete

```bash
# Close the task
bd close <task-id>

# Check if any tasks are now unblocked
bd ready
```

---

## 📋 Task Creation Guidelines

### When to Create Tasks

**DO create tasks for:**
- ✅ New features or enhancements
- ✅ Bug fixes that require investigation
- ✅ Refactoring work
- ✅ Documentation updates
- ✅ Performance improvements
- ✅ Security fixes

**DON'T create tasks for:**
- ❌ Trivial typo fixes
- ❌ Single-line changes
- ❌ Tasks that already exist (check `bd list` first)

### Task Hierarchy

Use parent-child relationships for complex work:

```bash
# Create epic
bd create "Refactor authentication system" --epic
# Returns: StackKits-abc123

# Create subtasks
bd create "Extract auth service" --parent StackKits-abc123
bd create "Add unit tests" --parent StackKits-abc123
bd create "Update documentation" --parent StackKits-abc123
```

### Dependencies

Use dependencies when task order matters:

```bash
# Example: Testing depends on implementation
bd create "Implement user login"
# Returns: StackKits-aaa111

bd create "Add login tests"
# Returns: StackKits-bbb222

# Add dependency: tests depend on implementation
bd dep add StackKits-bbb222 StackKits-aaa111
```

Now `bd ready` won't show the test task until implementation is closed.

---

## 🎨 StackKits-Specific Guidelines

### CUE Schema Development Workflow

```bash
# 1. Create schema modification task
bd create "Update base.Service schema to support new container runtime"
# Returns: StackKits-schema001

# 2. Create dependent validation task
bd create "Validate all stacks against updated schema"
# Returns: StackKits-schema002

# 3. Add dependency (validation depends on schema changes)
bd dep add StackKits-schema002 StackKits-schema001

# 4. Start work on schema
bd assign StackKits-schema001 @me
bd status StackKits-schema001 in-progress

# 5. Work on schema changes...

# 6. Run CUE validation
cue vet ./schemas/...

# 7. Document changes
bd comment StackKits-schema001 "Added runtime field to base.Service, validated with cue vet"

# 8. Close schema task
bd close StackKits-schema001

# 9. Now validation task becomes ready
bd ready
# Shows: StackKits-schema002
```

### Stack Development Workflow

```bash
# 1. Create stack epic
bd create "Add new monitoring stack" --epic
# Returns: StackKits-monitor

# 2. Break down into subtasks
bd create "Create monitoring service schema" --parent StackKits-monitor
bd create "Add Prometheus configuration" --parent StackKits-monitor
bd create "Add Grafana dashboards" --parent StackKits-monitor
bd create "Write stack documentation" --parent StackKits-monitor

# 3. Add dependencies (documentation depends on implementation)
bd dep add StackKits-monitor.4 StackKits-monitor.1
bd dep add StackKits-monitor.4 StackKits-monitor.2
bd dep add StackKits-monitor.4 StackKits-monitor.3

# 4. Start work on ready tasks
bd ready
# Shows: StackKits-monitor.1, StackKits-monitor.2, StackKits-monitor.3
```

### Bug Fix Workflow

```bash
# 1. Create bug task
bd create "Fix schema validation error in base-homelab stack"
# Returns: StackKits-bugfix001

# 2. Investigation
bd status StackKits-bugfix001 in-progress
bd comment StackKits-bugfix001 "Root cause: incorrect field type in service definition"

# 3. Implementation
bd comment StackKits-bugfix001 "Fixed in commit: abc123def"

# 4. Validation
bd comment StackKits-bugfix001 "Verified with: cue vet ./stacks/base-homelab/..."

# 5. Complete
bd close StackKits-bugfix001
```

---

## 🚨 Important Rules

### Task Lifecycle

1. **Created** → Task exists, status=open
2. **Assigned** → Assigned to agent/developer
3. **In Progress** → Active work happening
4. **Blocked** → Waiting on dependency or external factor
5. **Review** → Implementation complete, awaiting review
6. **Closed** → Task complete, automatically summarized

### Never Skip Dependencies

**If a task has blockers, don't work on it!**

```bash
bd ready
# Shows: task-B, task-C
# Does NOT show: task-A (blocked by task-B)

# ❌ DON'T: Work on task-A anyway
# ✅ DO: Work on task-B, then task-A becomes ready
```

### Keep Tasks Focused

**One task = One concern**

✅ Good:
- Task 1: "Implement user login endpoint"
- Task 2: "Add unit tests for login"
- Task 3: "Update API documentation"

❌ Bad:
- Task 1: "Implement login, add tests, update docs, and refactor auth system"

---

## 💬 Copilot Chat Commands

Use these in VS Code Copilot Chat:

### Check Ready Tasks
```
@workspace What Beads tasks are ready in StackKits?
```

### Create Task
```
@workspace Create a Beads task for implementing OAuth2 authentication
```

### Show Task Details
```
@workspace Show Beads task StackKits-abc123 details
```

### Close Task
```
@workspace Close Beads task StackKits-abc123
```

### Show Dependency Graph
```
@workspace Show the Beads dependency graph for current tasks
```

---

## 🔄 Standard StackKits Workflows

### Adding a New Service Stack

1. Create epic: `bd create "Add [service-name] stack" --epic`
2. Create subtasks:
   - "Create service schema"
   - "Add container configuration"
   - "Create compose/deployment files"
   - "Add tests"
   - "Write documentation"
3. Add dependencies (docs depend on implementation)
4. Work through tasks using `bd ready`

### Modifying CUE Schemas

1. Create task: `bd create "Update [schema-name] schema"`
2. Create validation task: `bd create "Validate stacks against updated schema"`
3. Add dependency: validation depends on schema changes
4. Work on schema, run `cue vet`
5. Document changes in task comments
6. Close schema task
7. Work on validation task

### Refactoring Work

1. Create refactoring epic: `bd create "Refactor [component]" --epic`
2. Break into subtasks (extract, update tests, update docs)
3. Add dependencies (tests depend on extraction, docs depend on tests)
4. Work through dependency chain using `bd ready`

---

## 📊 Task Documentation Best Practices

### Good Task Titles

✅ **Specific and actionable:**
- "Implement OAuth2 authentication with Google provider"
- "Fix memory leak in WebSocket connection handler"
- "Add validation for user email format"

❌ **Vague or unclear:**
- "Fix stuff"
- "Update code"
- "Make it better"

### Good Task Comments

✅ **Informative:**
```bash
bd comment task-id "Chose bcrypt over scrypt for password hashing (see ADR/007)"
bd comment task-id "Performance: reduced API latency from 200ms to 50ms"
bd comment task-id "Breaking change: removed deprecated /v1/users endpoint"
```

❌ **Uninformative:**
```bash
bd comment task-id "Done"
bd comment task-id "Fixed it"
```

---

## 🔍 Troubleshooting

### "bd: command not found"

**Solution:** Use full path
```bash
C:/Users/mako1/go/bin/bd.exe --version
```

### "No tasks found"

**Check initialization:**
```bash
ls .beads/
# Should show: beads.db, config.toml
```

### "Task still showing as ready but has dependency"

**Verify dependency:**
```bash
bd show <task-id>
# Check "Depends on:" section
```

---

## 📚 Additional Resources

- **Global Beads Documentation**: `~/.claude/AGENTS.md`
- **Beads Setup Guide**: `~/.claude/BEADS-SETUP-COMPLETE.md`
- **StackKits CLAUDE.md**: `.claude/CLAUDE.md` (project-specific context)
- **Beads GitHub**: https://github.com/steveyegge/beads
- **Beads UI**: Run `cd ~/.claude/tools/beads-ui && npm start`

---

## 🎯 TL;DR for GitHub Copilot

**Before any work:**
```bash
bd ready
```

**When starting task:**
```bash
bd assign <id> @me && bd status <id> in-progress
```

**When done:**
```bash
bd close <id>
```

**Remember:** Beads is your source of truth for what to work on. Check it first, update it during work, and close tasks when done.

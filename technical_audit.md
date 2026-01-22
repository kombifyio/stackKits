# Technical Audit

## Core Logic
- CUE language provides type-safe schema validation with constraint checking, default value injection, and cross-field dependency resolution across IntentSpec, RequirementsSpec, and UnifiedSpec schemas.
- Three-layer architecture separates core foundation (base/), platform orchestration (platforms/docker, platforms/kubernetes), and use-case StackKits (base-homelab, modern-homelab, ha-homelab) with shared templates and variant-specific overrides.
- Go-based CLI (cmd/stackkit) orchestrates validation pipeline, template rendering, and OpenTofu execution through internal packages (internal/cue, internal/tofu, internal/terramate, internal/template).
- OS variant system auto-detects and applies Ubuntu/Debian specific configurations with compute tier selection (high/standard/low) affecting resource limits and service selection (e.g., Netdata vs Glances).
- Template rendering engine processes CUE templates with .tf.tmpl extensions to generate OpenTofu HCL files with dynamic variable substitution and conditional resource inclusion.
- Change detection mechanism uses Git-based tracking to identify modified stacks and selectively apply updates only to affected infrastructure components.

## Infrastructure
- OpenTofu 1.6+ executes infrastructure provisioning using Docker provider (kreuzwerker/docker) for container resources, null provider for remote-exec bootstrapping, and local provider for file generation.
- Terramate 0.6+ orchestrates multi-stack deployments with stack dependency management (after directives), change detection (--changed flag), and parallel execution control via TERRAMATE_EXPERIMENTAL_PARALLEL environment variable.
- Advanced mode deployment leverages Terramate stack configurations (stack.tm.hcl) defining service dependencies, execution order (traefik → dockge → monitoring), and global variables for centralized version management.
- Docker 24.0+ serves as the container runtime for single-node (base-homelab) deployments, while multi-node deployments (modern-homelab, ha-homelab) use Docker Swarm clustering with overlay networks.
- Docker Swarm provides high-availability clustering with manager node quorum (3+ for ha-homelab), encrypted overlay networking, routing mesh for service discovery, and global service deployment mode.
- Bootstrap phase executes via null_resource remote-exec provisioners installing Docker, configuring system packages, hardening security (UFW firewall, SSH), and initializing Swarm clusters on target nodes.

## Infrastructure - Terramate Advanced Configuration
- Stack orchestration uses terramate.tm.hcl root configuration with Git integration for change detection (check_untracked, check_uncommitted, check_remote), experimental features (scripts), and automation environment variables.
- Stack-specific configurations (stacks/*/stack.tm.hcl) define service metadata (name, description, id), dependency chains via after directives, service-specific globals (ports, volumes, memory limits), and resource tagging.
- Global variables centralize version management (global.versions.traefik, global.versions.dockge) enabling single-point updates across all stacks and consistent image tag deployment.
- Drift detection executes tofu plan with -detailed-exitcode flag (exit 2 indicates drift) across all stacks, parsing plan output to identify resource changes (create/update/delete actions) and generating DriftResult JSON.
- Change-based execution (terramate run --changed) selectively processes only stacks affected by Git commits, reducing deployment time and blast radius for incremental updates.
- Reverse execution order (terramate run --reverse) ensures proper teardown sequence during destroy operations, processing dependent stacks before their dependencies.
- Parallel execution capability distributes stack operations across multiple workers with configurable parallelism levels, accelerating multi-stack deployments while respecting dependency ordering.
- Stack globals enable compute-tier-aware resource allocation (memory_limits.high/standard/low) allowing adaptive service sizing based on hardware capabilities without template duplication.

## Data/State
- OpenTofu maintains infrastructure state files (terraform.tfstate) tracking resource lifecycle, attribute values, dependency graphs, and provider metadata with locking mechanisms preventing concurrent modifications.
- State-based drift detection compares desired configuration (HCL) against actual infrastructure state, identifying configuration drift through tofu plan exit codes (0=no changes, 1=error, 2=changes detected).
- CUE validation layer merges user specifications (stack-spec.yaml) with StackKit schemas to produce validated configuration objects, applying defaults, enforcing constraints, and resolving variant-specific overrides.
- Template rendering engine generates HCL files (*.tf, *.tfvars) from CUE templates with dynamic value substitution, conditional blocks, and iteration over service definitions.
- Terramate stack state tracking maintains per-stack metadata enabling selective updates, change detection across commits, and dependency-aware orchestration with topological sorting.
- Day-2 operations leverage state for refresh operations (tofu refresh), output retrieval (tofu output -json), and rollback capabilities by applying previous state snapshots.
- Local backend stores state files in workspace directories enabling version control integration, while remote backends (S3, Consul) provide team collaboration and state locking for production environments.

## Security
- SSH key-based authentication for remote server access with configurable user credentials, key paths (id_ed25519/id_rsa), and connection parameters (host, port, user) preventing password-based attacks.
- Bootstrap phase executes security hardening scripts via null_resource remote-exec provisioners on target nodes including UFW firewall configuration, SSH daemon hardening, automatic security updates, and fail2ban intrusion prevention.
- CUE schema validation prevents injection attacks by enforcing strict type constraints, DNS-compatible naming patterns (^[a-z][a-z0-9-]+$), port range validation, and cross-field dependency checks before infrastructure provisioning.
- Secret management through environment variables with external generation (openssl rand -hex 32) for PostgreSQL passwords, NEXTAUTH secrets, and service credentials avoiding hardcoded secrets in configuration files.
- TLS certificate provisioning via Traefik ACME integration for public mode (Let's Encrypt) and self-signed certificates for local mode with automatic renewal and secure storage in Docker volumes.
- Network isolation through Docker networks segregating service traffic, bridge network configuration for local deployments, and encrypted overlay networks for Swarm multi-node communication.
- Resource access control using Docker security options (read-only root filesystems, capability dropping, user namespace remapping) and service-specific security contexts limiting attack surface.

## Interface
- Command-line interface provides validate, plan, and apply commands for standalone infrastructure deployment workflows with progress tracking, error reporting, and color-coded output via fatih/color library.
- CLI subcommands include init (workspace initialization), list (stack enumeration), changed (Git-based change detection), and drift (infrastructure drift reporting) supporting both simple and advanced deployment modes.
- REST API integration planned for KombiStack Web UI with wizard-driven kombination.yaml generation, Unifier pipeline processing, and real-time deployment status streaming via WebSocket connections.
- Docker provider API manages container lifecycle (create/start/stop/destroy), network configuration (bridge/overlay/host), volume mounting (bind/named volumes), port publishing, and health check definitions via docker_container resources.
- OpenTofu HCL templates expose provider-specific resources (docker_container, docker_network, docker_volume, null_resource) enabling declarative infrastructure specification with resource dependencies and lifecycle management.
- Terramate CLI integration provides stack operations (list, create, generate), orchestration commands (run, run --changed, run --reverse), and drift detection (run -- tofu plan -detailed-exitcode) with JSON output for programmatic consumption.
- Output retrieval mechanisms expose service URLs, credentials, cluster join tokens, and health status through tofu output with JSON formatting enabling downstream automation and integration with monitoring systems.
- Interactive terminal UI under consideration for future releases to provide deployment progress visualization, stack dependency graphs, drift reports, and real-time log streaming.

# Technical Audit

## Core Logic
- CUE language provides type-safe schema validation with constraint checking, default value injection, and cross-field dependency resolution.
- Three-layer architecture separates core foundation (base/), platform orchestration (platforms/docker, platforms/kubernetes), and use-case StackKits (base-homelab, modern-homelab, ha-homelab).
- Go-based CLI (cmd/stackkit) orchestrates validation pipeline, template rendering, and OpenTofu execution through internal packages.
- OS variant system auto-detects and applies Ubuntu/Debian specific configurations with compute tier selection (high/standard/low).

## Infrastructure
- OpenTofu 1.6+ executes infrastructure provisioning using Docker provider (kreuzwerker/docker), null provider for remote execution, and local provider for file generation.
- Terramate 0.6+ orchestrates multi-node deployments with stack management, drift detection, and rolling update capabilities in advanced mode.
- Docker 24.0+ serves as the container runtime for single-node (base-homelab) and multi-node (modern-homelab) deployments.
- Docker Swarm provides high-availability clustering with manager node quorum, overlay networking, and routing mesh for multi-node deployments.

## Data/State
- OpenTofu maintains infrastructure state files tracking resource lifecycle, dependencies, and configuration drift.
- CUE validation layer merges user specifications (stack-spec.yaml) with StackKit schemas to produce validated configuration objects.
- Template rendering engine generates HCL files (*.tf, *.tfvars) from CUE templates with dynamic value substitution.

## Security
- SSH key-based authentication for remote server access with configurable user credentials and key paths.
- Bootstrap phase executes security hardening scripts via null_resource remote-exec provisioners on target nodes.
- CUE schema validation prevents injection attacks by enforcing strict type constraints and DNS-compatible naming patterns.
- Secret management through environment variables with external generation (openssl rand) for PostgreSQL, NEXTAUTH, and service credentials.

## Interface
- Command-line interface provides validate, plan, and apply commands for standalone infrastructure deployment workflows.
- REST API integration planned for KombiStack Web UI with wizard-driven kombination.yaml generation and Unifier pipeline processing.
- Docker provider API manages container lifecycle, network configuration, volume mounting, and health check definitions.
- OpenTofu HCL templates expose provider-specific resources (docker_container, docker_network, null_resource) for declarative infrastructure specification.

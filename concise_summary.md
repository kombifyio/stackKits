# Concise Summary

StackKits delivers declarative infrastructure blueprints for self-hosted homelab deployments, combining CUE validation with OpenTofu provisioning for safe, reproducible infrastructure. It eliminates configuration errors before deployment through type-safe schemas and enables both standalone CLI usage and integration with the KombiStack ecosystem.

## Feature Highlights

- **Pre-Deployment Validation** - CUE schemas catch configuration errors, type mismatches, and constraint violations before infrastructure provisioning begins
- **Three-Layer Architecture** - Modular design separates core foundations, platform orchestration (Docker/Kubernetes), and use-case specific StackKits for maximum reusability
- **Multi-Deployment Modes** - Simple mode for single-server OpenTofu execution or advanced mode with Terramate orchestration for multi-node HA clusters
- **OS Variant System** - Automatic adaptation for Ubuntu, Debian, and compute tier variants without manual template modifications
- **IaC-First Design** - OpenTofu as the execution engine with Docker, Kubernetes, and null providers for containers, networks, and bootstrap automation

*Ready-to-use templates include single-server (base-homelab), multi-node Docker (modern-homelab), and high-availability Kubernetes (ha-homelab) configurations.*

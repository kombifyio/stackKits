# Dev Homelab Contract

Minimal StackKit for e2e testing of CLI and tooling integration. Internal only.

## Layers
Foundation is minimal.
Platform is docker.

## Purpose
Test CLI commands init, validate, plan, apply, destroy, status.
Validate integration with Kombify Administration.
Prove contract compliance before full StackKit implementation.
Iterate quickly with minimal surface area.

## Services
Whoami provides a simple HTTP endpoint for testing.
Docker network connects all services.

## No Variants
Single configuration only.
No variant selection logic.
No optional services.

## Success
Init creates valid stack-spec.yaml.
Validate passes CUE validation.
Plan generates valid OpenTofu plan.
Apply deploys without errors.
Whoami responds at localhost:9080.
Status shows healthy service.
Destroy removes all resources.

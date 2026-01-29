# StackKits Testing Standards

**Version:** 1.0.0  
**Last Updated:** 2026-01-29

This document defines comprehensive testing standards for all StackKits.

---

## 1. Testing Philosophy

### 1.1 Core Principles

| Principle | Description |
|-----------|-------------|
| **Shift Left** | Test early, test often. Catch issues before deployment. |
| **Layered Testing** | Each layer has appropriate tests for its scope. |
| **Reproducibility** | Tests must be deterministic and repeatable. |
| **Fast Feedback** | Unit tests in seconds, integration in minutes. |
| **Production Parity** | E2E tests mirror real deployment scenarios. |

### 1.2 Test Pyramid

```
                    ┌───────────────┐
                    │   E2E Tests   │  ← Slow, expensive, high confidence
                    │   (Few)       │
                    └───────┬───────┘
                            │
               ┌────────────┴────────────┐
               │   Integration Tests     │  ← Moderate speed, component interactions
               │   (Some)                │
               └────────────┬────────────┘
                            │
          ┌─────────────────┴─────────────────┐
          │        Unit Tests                  │  ← Fast, isolated, many
          │        (Many)                      │
          └───────────────────────────────────┘
```

---

## 2. Test Categories

### 2.1 Unit Tests

**Scope:** Individual functions, parsers, validators, CUE schemas

**Location:** `tests/unit/` and `*_test.go` files alongside source

**Tools:**
- Go: `go test`
- CUE: `cue vet`
- Shell: `bats` or `shellcheck`

**Requirements:**
- Execute in < 5 seconds total
- No external dependencies (Docker, network)
- No file system side effects
- Mock external services

**Example Structure:**
```
tests/unit/
├── config_test.go       # Config parsing tests
├── validation_test.go   # Input validation tests
├── template_test.go     # Template rendering tests
└── cue/
    ├── schema_test.cue  # CUE schema validation
    └── types_test.cue   # Type constraint tests
```

### 2.2 Integration Tests

**Scope:** Component interactions, template generation, CLI workflows

**Location:** `tests/integration/`

**Tools:**
- Go: `go test -tags=integration`
- Docker: Testcontainers or Docker CLI

**Requirements:**
- Execute in < 5 minutes total
- May require Docker
- Clean up all created resources
- Use dedicated test networks/volumes

**Example Structure:**
```
tests/integration/
├── cli_init_test.go      # CLI init command
├── cli_validate_test.go  # CLI validate command
├── cli_plan_test.go      # CLI plan generation
├── template_test.go      # Full template generation
└── docker_test.go        # Docker integration
```

### 2.3 End-to-End (E2E) Tests

**Scope:** Full deployment lifecycle on real or simulated infrastructure

**Location:** `tests/e2e/`

**Tools:**
- OpenTofu: `tofu plan`, `tofu apply`
- Docker: Real containers
- HTTP: Health check validation

**Requirements:**
- Execute in < 30 minutes total
- Full cleanup after test (destroy)
- Test all variants
- Validate all acceptance criteria

**Example Structure:**
```
tests/e2e/
├── base_homelab_test.go     # Full base-homelab deployment
├── dev_homelab_test.go      # Full dev-homelab deployment
├── fixtures/
│   ├── test_spec.yaml       # Test configuration
│   └── expected_output/     # Expected generated files
└── helpers/
    ├── docker.go            # Docker helpers
    └── http.go              # HTTP assertion helpers
```

### 2.4 Validation Tests

**Scope:** CUE schema conformance, YAML/JSON validity

**Location:** `tests/validation/` and `{stackkit}/tests/`

**Tools:**
- CUE: `cue vet`
- YAML: `yq` or Go YAML parser
- JSON: `jq` or Go JSON parser

**Example Structure:**
```
tests/validation/
├── run_validation.sh        # Validation runner script
├── validation_test.cue      # Global validation tests
└── fixtures/
    ├── valid/               # Known-good configs
    └── invalid/             # Known-bad configs (should fail)
```

---

## 3. Test Naming Conventions

### 3.1 Go Test Functions

```go
// Format: Test{Component}_{Scenario}_{ExpectedResult}
func TestConfigParse_ValidYAML_Success(t *testing.T) {}
func TestConfigParse_InvalidSyntax_ReturnsError(t *testing.T) {}
func TestValidation_MissingRequiredField_FailsWithCode(t *testing.T) {}
```

### 3.2 CUE Test Files

```cue
// Filename: {component}_test.cue

// Valid configurations
_validConfig: {
    name: "test-stack"
    version: "1.0.0"
    // ... all required fields
}

// Invalid configurations with expected errors
_invalidMissingName: {
    // name: missing
    version: "1.0.0"
}
```

### 3.3 Fixture Files

```
fixtures/
├── valid/
│   ├── minimal_config.yaml       # Bare minimum valid config
│   ├── full_config.yaml          # All fields populated
│   └── all_variants.yaml         # Every variant tested
└── invalid/
    ├── missing_required.yaml     # Missing required fields
    ├── invalid_types.yaml        # Wrong types
    └── constraint_violations.yaml # Constraint failures
```

---

## 4. StackKit-Specific Testing

### 4.1 dev-homelab (Testing StackKit)

**Purpose:** Validate CLI and tooling before full StackKit implementation

**Test Sequence:**
1. `stackkit init` → Creates valid stack-spec.yaml
2. `stackkit validate` → Passes CUE validation
3. `stackkit plan` → Generates valid OpenTofu plan
4. `stackkit apply` → Deploys without errors
5. HTTP GET whoami:9080 → Returns 200
6. `stackkit status` → Shows healthy
7. `stackkit destroy` → Removes all resources

**Acceptance Criteria:**
```yaml
acceptance:
  - init creates spec
  - validate passes
  - plan succeeds
  - apply deploys
  - whoami responds
  - status shows healthy
  - destroy cleans up
```

### 4.2 base-homelab

**Purpose:** Validate single-server homelab deployment

**Test Sequence:**
1. Deploy default variant
2. Verify all services start
3. Verify Traefik routes correctly
4. Verify PaaS (Dokploy) is accessible
5. Deploy sample app via PaaS
6. Verify monitoring (Uptime Kuma) sees services
7. Clean destroy

**Variants to Test:**
- `default` - Dokploy + Uptime Kuma
- `beszel` - Dokploy + Beszel
- `minimal` - No PaaS, just utilities

**Acceptance Criteria:**
```yaml
acceptance:
  - services start
  - UIs accessible
  - can deploy app
  - destroy cleans up
```

---

## 5. Continuous Integration

### 5.1 CI Pipeline Stages

```yaml
stages:
  - lint          # Fast checks (< 1 min)
  - unit          # Unit tests (< 2 min)
  - build         # Compile CLI (< 2 min)
  - integration   # Integration tests (< 10 min)
  - e2e           # E2E tests (manual trigger or release)
```

### 5.2 When Tests Run

| Trigger | Unit | Integration | E2E |
|---------|------|-------------|-----|
| Commit to branch | ✓ | ✓ | ✗ |
| Pull Request | ✓ | ✓ | Optional |
| Merge to main | ✓ | ✓ | ✓ |
| Release tag | ✓ | ✓ | ✓ (all variants) |

### 5.3 Required Passes

| Branch | Requirements |
|--------|--------------|
| `feature/*` | Unit tests pass |
| `main` | Unit + Integration pass |
| `release/*` | All tests pass |

---

## 6. Test Infrastructure

### 6.1 Local Development

```bash
# Run all unit tests
make test-unit

# Run integration tests (requires Docker)
make test-integration

# Run specific test
go test -v ./internal/config/... -run TestConfigParse

# Run CUE validation
cue vet ./...
```

### 6.2 CI Environment

- **Runner:** Ubuntu 24.04
- **Docker:** Available for integration/e2e
- **OpenTofu:** Pre-installed for IaC tests
- **Timeout:** 30 minutes max per job

---

## 7. Coverage Requirements

### 7.1 Minimum Coverage

| Component | Target |
|-----------|--------|
| internal/config | 80% |
| internal/validation | 90% |
| internal/template | 70% |
| CUE schemas | 100% (all fields exercised) |

### 7.2 Coverage Reports

```bash
# Generate coverage report
go test -coverprofile=coverage.out ./...

# View HTML report
go tool cover -html=coverage.out
```

---

## 8. Test Data Management

### 8.1 Fixtures Location

```
tests/
└── fixtures/
    ├── configs/          # Input configuration files
    ├── expected/         # Expected output files
    └── keys/             # Test SSH keys (never real!)
```

### 8.2 Test Secrets

**Never commit real secrets!**

```go
// Use test-specific values
const testSSHKey = "ssh-ed25519 AAAA... test-key-do-not-use"
const testDomain = "test.local"
const testHost = "127.0.0.1"
```

---

## 9. Debugging Failed Tests

### 9.1 Verbose Output

```bash
# Go tests with verbose
go test -v -run TestSpecificTest ./...

# Keep test artifacts
TEST_KEEP_ARTIFACTS=1 make test-e2e
```

### 9.2 CI Artifacts

Failed CI runs should upload:
- Generated Terraform files
- Docker logs
- Test output logs
- Coverage reports

---

## 10. Adding New Tests

### 10.1 Checklist

- [ ] Test file follows naming convention
- [ ] Test function name describes scenario
- [ ] Uses table-driven tests where appropriate
- [ ] Cleans up all resources on success AND failure
- [ ] Does not depend on test execution order
- [ ] Updates coverage if new code path

### 10.2 Template

```go
func TestComponent_Scenario_ExpectedResult(t *testing.T) {
    // Arrange
    input := setupTestData(t)
    
    // Act
    result, err := ComponentUnderTest(input)
    
    // Assert
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if result != expected {
        t.Errorf("got %v, want %v", result, expected)
    }
}
```

---

## Cross-References

- [DOCUMENTS.md](./DOCUMENTS.md) - Document standards
- [Layer 1: VALIDATION.md](./layer-1-foundation/base/VALIDATION.md) - Validation architecture
- [Layer 2: Docker VALIDATION.md](./layer-2-platform/docker/VALIDATION.md) - Docker validation
- [Layer 3: base-homelab VALIDATION.md](./layer-3-stackkits/base-homelab/VALIDATION.md) - StackKit validation

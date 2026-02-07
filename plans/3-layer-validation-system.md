# 3-Layer Architecture Validation System Implementation Plan

## Overview

This plan implements a robust 3-layer architecture validation system for StackKits that ensures every StackKit has all required layers with proper validation.

## Architecture

```mermaid
flowchart TB
    subgraph "Validation Pipeline"
        A[User Input] --> B[Layer Validator]
        B --> C[Validation Result]
    end

    subgraph "Layer 1: Foundation"
        L1A[System Config]
        L1B[Packages]
        L1C[SSH Hardening]
        L1D[Firewall]
    end

    subgraph "Layer 2: Platform"
        L2A[Platform Type<br/>docker|swarm|bare-metal]
        L2B[Container Runtime]
        L2C[Networking Base]
    end

    subgraph "Layer 3: Applications"
        L3A[PAAS Service<br/>Required]
        L3B[Additional Services]
    end

    B --> L1A
    B --> L1B
    B --> L1C
    B --> L1D
    B --> L2A
    B --> L2B
    B --> L2C
    B --> L3A
    B --> L3B
```

## Implementation Structure

### 1. CUE Schema Definitions

#### File: `base/layers.cue` (NEW)

```cue
// Package base - 3-Layer Architecture Validation Schemas
package base

// =============================================================================
// LAYER 1: FOUNDATION - REQUIRED
// =============================================================================

// #Layer1Foundation validates Layer 1 requirements
#Layer1Foundation: {
    // System configuration MUST be present
    system: #SystemConfig
    
    // Base packages MUST be defined
    packages: #BasePackages
    
    // Security settings MUST be configured
    security: {
        // SSH hardening is REQUIRED
        ssh: #SSHHardening
        
        // Firewall policy is REQUIRED  
        firewall: #FirewallPolicy
    }
    
    // Validation check
    _valid: true
}

// =============================================================================
// LAYER 2: PLATFORM - REQUIRED
// =============================================================================

// Platform types supported
#PlatformType: "docker" | "docker-swarm" | "bare-metal"

// #Layer2Platform validates Layer 2 requirements
#Layer2Platform: {
    // Platform type MUST be explicitly declared
    platform: #PlatformType
    
    // Container runtime configuration MUST be present
    container: #ContainerRuntime
    
    // Networking base MUST be configured
    network: {
        defaults: #NetworkDefaults
    }
    
    // Validation check
    _valid: true
}

// =============================================================================
// LAYER 3: APPLICATIONS - REQUIRED
// =============================================================================

// PAAS service types
#PAASServiceType: "dokploy" | "coolify" | "dokku" | "portainer" | "dockge"

// Service role classification
#ServiceRole: "paas" | "monitoring" | "management" | "proxy" | "utility" | "test"

// #Layer3Applications validates Layer 3 requirements
#Layer3Applications: {
    // Services map
    services: [string]: #ServiceDefinition
    
    // At least ONE PAAS/management service MUST be enabled
    _paasServices: [
        for name, svc in services
        if svc.type == "paas" || svc.type == "management" && svc.enabled != false {
            name
        }
    ]
    
    // Validation: Must have at least one PAAS service
    _hasPAASService: len(_paasServices) > 0
}

// =============================================================================
// COMPLETE STACKKIT VALIDATION
// =============================================================================

// #ValidatedStackKit combines all 3 layers
#ValidatedStackKit: {
    // Layer 1: Foundation (embedded)
    #Layer1Foundation
    
    // Layer 2: Platform (embedded)
    #Layer2Platform
    
    // Layer 3: Applications (embedded)
    #Layer3Applications
    
    // Metadata requirements
    metadata: #StackKitMetadata
    
    // Final validation - all layers must be valid
    _valid: {
        layer1: true
        layer2: true
        layer3: true
    }
}

// =============================================================================
// VALIDATION ERROR TYPES
// =============================================================================

// #LayerValidationError represents a layer validation failure
#LayerValidationError: {
    layer:     "1" | "2" | "3"
    code:      string
    message:   string
    field?:    string
    hint?:     string
}

// #LayerValidationResult contains validation results
#LayerValidationResult: {
    valid:    bool
    layer:    "1" | "2" | "3" | "all"
    errors: [...#LayerValidationError]
}
```

### 2. Go Validation Architecture

#### File: `internal/validation/layer_validator.go` (NEW)

```go
// Package validation provides 3-layer architecture validation for StackKits.
package validation

import (
    "fmt"
    "strings"

    "cuelang.org/go/cue"
    "cuelang.org/go/cue/cuecontext"
    "cuelang.org/go/cue/load"
    "github.com/kombihq/stackkits/pkg/models"
)

// Layer represents the validation layer (1, 2, or 3)
type Layer int

const (
    LayerFoundation   Layer = 1
    LayerPlatform     Layer = 2
    LayerApplications Layer = 3
)

// LayerError represents a layer validation error
type LayerError struct {
    Layer   Layer  `json:"layer"`
    Code    string `json:"code"`
    Message string `json:"message"`
    Field   string `json:"field,omitempty"`
    Hint    string `json:"hint,omitempty"`
}

func (e *LayerError) Error() string {
    return fmt.Sprintf("Layer %d [%s]: %s", e.Layer, e.Code, e.Message)
}

// LayerValidationResult contains validation results for a single layer
type LayerValidationResult struct {
    Layer    Layer         `json:"layer"`
    Valid    bool          `json:"valid"`
    Errors   []LayerError  `json:"errors,omitempty"`
    Warnings []string      `json:"warnings,omitempty"`
}

// StackKitValidationResult contains complete validation results
type StackKitValidationResult struct {
    Valid      bool                     `json:"valid"`
    StackKit   string                   `json:"stackkit"`
    Layer1     *LayerValidationResult   `json:"layer1"`
    Layer2     *LayerValidationResult   `json:"layer2"`
    Layer3     *LayerValidationResult   `json:"layer3"`
    AllErrors  []LayerError             `json:"allErrors,omitempty"`
}

// LayerValidator performs 3-layer architecture validation
type LayerValidator struct {
    ctx       *cue.Context
    baseDir   string
    schemaDir string
}

// NewLayerValidator creates a new layer validator
func NewLayerValidator(baseDir string) *LayerValidator {
    return &LayerValidator{
        ctx:       cuecontext.New(),
        baseDir:   baseDir,
        schemaDir: filepath.Join(baseDir, "base"),
    }
}

// ValidateStackKit performs complete 3-layer validation
func (v *LayerValidator) ValidateStackKit(stackkitDir string) (*StackKitValidationResult, error) {
    result := &StackKitValidationResult{
        StackKit: filepath.Base(stackkitDir),
        Valid:    true,
    }

    // Validate each layer
    result.Layer1 = v.validateLayer1(stackkitDir)
    result.Layer2 = v.validateLayer2(stackkitDir)
    result.Layer3 = v.validateLayer3(stackkitDir)

    // Combine all errors
    result.AllErrors = append(result.AllErrors, result.Layer1.Errors...)
    result.AllErrors = append(result.AllErrors, result.Layer2.Errors...)
    result.AllErrors = append(result.AllErrors, result.Layer3.Errors...)

    // Overall validity
    result.Valid = result.Layer1.Valid && result.Layer2.Valid && result.Layer3.Valid

    return result, nil
}

// validateLayer1 validates Layer 1 (Foundation) requirements
func (v *LayerValidator) validateLayer1(stackkitDir string) *LayerValidationResult {
    result := &LayerValidationResult{
        Layer: LayerFoundation,
        Valid: true,
    }

    // Load CUE files
    value, err := v.loadCUEValue(stackkitDir)
    if err != nil {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerFoundation,
            Code:    "L1_LOAD_ERROR",
            Message: fmt.Sprintf("Failed to load CUE: %v", err),
        })
        return result
    }

    // Check system configuration
    if system := value.LookupPath(cue.ParsePath("system")); !system.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerFoundation,
            Code:    "L1_MISSING_SYSTEM",
            Message: "Layer 1 foundation incomplete - missing system configuration",
            Field:   "system",
            Hint:    "Add system configuration block with timezone, locale, etc.",
        })
    }

    // Check packages
    if packages := value.LookupPath(cue.ParsePath("packages")); !packages.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerFoundation,
            Code:    "L1_MISSING_PACKAGES",
            Message: "Layer 1 foundation incomplete - missing base packages",
            Field:   "packages",
            Hint:    "Add packages block with core and extra packages",
        })
    }

    // Check SSH security
    if security := value.LookupPath(cue.ParsePath("security.ssh")); !security.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerFoundation,
            Code:    "L1_MISSING_SSH",
            Message: "Layer 1 foundation incomplete - missing SSH hardening configuration",
            Field:   "security.ssh",
            Hint:    "Add security.ssh block with port, permitRootLogin, passwordAuth settings",
        })
    }

    // Check firewall
    if firewall := value.LookupPath(cue.ParsePath("security.firewall")); !firewall.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerFoundation,
            Code:    "L1_MISSING_FIREWALL",
            Message: "Layer 1 foundation incomplete - missing firewall policy",
            Field:   "security.firewall",
            Hint:    "Add security.firewall block with enabled, backend, rules",
        })
    }

    return result
}

// validateLayer2 validates Layer 2 (Platform) requirements
func (v *LayerValidator) validateLayer2(stackkitDir string) *LayerValidationResult {
    result := &LayerValidationResult{
        Layer: LayerPlatform,
        Valid: true,
    }

    value, err := v.loadCUEValue(stackkitDir)
    if err != nil {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerPlatform,
            Code:    "L2_LOAD_ERROR",
            Message: fmt.Sprintf("Failed to load CUE: %v", err),
        })
        return result
    }

    // Check platform type is explicitly declared
    platform := value.LookupPath(cue.ParsePath("platform"))
    if !platform.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerPlatform,
            Code:    "L2_MISSING_PLATFORM",
            Message: "Layer 2 platform not declared - must specify docker/swarm/bare-metal",
            Field:   "platform",
            Hint:    "Add platform field with value: docker | docker-swarm | bare-metal",
        })
    } else {
        // Validate platform type value
        platformStr, err := platform.String()
        if err != nil {
            result.Valid = false
            result.Errors = append(result.Errors, LayerError{
                Layer:   LayerPlatform,
                Code:    "L2_INVALID_PLATFORM",
                Message: "Layer 2 platform has invalid type",
                Field:   "platform",
                Hint:    "Platform must be one of: docker, docker-swarm, bare-metal",
            })
        } else {
            validPlatforms := map[string]bool{
                "docker":        true,
                "docker-swarm":  true,
                "bare-metal":    true,
            }
            if !validPlatforms[platformStr] {
                result.Valid = false
                result.Errors = append(result.Errors, LayerError{
                    Layer:   LayerPlatform,
                    Code:    "L2_INVALID_PLATFORM_VALUE",
                    Message: fmt.Sprintf("Layer 2 platform '%s' is not valid", platformStr),
                    Field:   "platform",
                    Hint:    "Platform must be one of: docker, docker-swarm, bare-metal",
                })
            }
        }
    }

    // Check container runtime configuration
    if container := value.LookupPath(cue.ParsePath("container")); !container.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerPlatform,
            Code:    "L2_MISSING_CONTAINER",
            Message: "Layer 2 platform incomplete - missing container runtime configuration",
            Field:   "container",
            Hint:    "Add container block with runtime, version, storage settings",
        })
    }

    // Check network configuration
    if network := value.LookupPath(cue.ParsePath("network.defaults")); !network.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerPlatform,
            Code:    "L2_MISSING_NETWORK",
            Message: "Layer 2 platform incomplete - missing network base configuration",
            Field:   "network.defaults",
            Hint:    "Add network.defaults block with driver, subnet, gateway",
        })
    }

    return result
}

// validateLayer3 validates Layer 3 (Applications) requirements
func (v *LayerValidator) validateLayer3(stackkitDir string) *LayerValidationResult {
    result := &LayerValidationResult{
        Layer: LayerApplications,
        Valid: true,
    }

    value, err := v.loadCUEValue(stackkitDir)
    if err != nil {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerApplications,
            Code:    "L3_LOAD_ERROR",
            Message: fmt.Sprintf("Failed to load CUE: %v", err),
        })
        return result
    }

    // Check services exist
    services := value.LookupPath(cue.ParsePath("services"))
    if !services.Exists() {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerApplications,
            Code:    "L3_MISSING_SERVICES",
            Message: "Layer 3 applications missing - no services defined",
            Field:   "services",
            Hint:    "Add services block with at least one PAAS service",
        })
        return result
    }

    // Check for PAAS/management service
    hasPAAS := false
    paasServices := []string{"dokploy", "coolify", "dokku", "portainer", "dockge"}

    // Iterate through services to find PAAS type
    iter, err := services.Fields(cue.Concrete(false))
    if err == nil {
        for iter.Next() {
            svcName := iter.Selector().String()
            svcValue := iter.Value()

            // Check if service has type field
            typeField := svcValue.LookupPath(cue.ParsePath("type"))
            if typeField.Exists() {
                typeStr, _ := typeField.String()
                if typeStr == "paas" || typeStr == "management" {
                    hasPAAS = true
                    break
                }
            }

            // Check if service name matches known PAAS services
            for _, paas := range paasServices {
                if strings.Contains(strings.ToLower(svcName), paas) {
                    hasPAAS = true
                    break
                }
            }
            if hasPAAS {
                break
            }
        }
    }

    if !hasPAAS {
        result.Valid = false
        result.Errors = append(result.Errors, LayerError{
            Layer:   LayerApplications,
            Code:    "L3_MISSING_PAAS",
            Message: "Missing PAAS service in Layer 3 - add dokploy, coolify, or equivalent",
            Field:   "services",
            Hint:    "Add at least one of: dokploy, coolify, dokku, portainer, dockge with type: 'paas' or 'management'",
        })
    }

    return result
}

// loadCUEValue loads CUE files from the stackkit directory
func (v *LayerValidator) loadCUEValue(stackkitDir string) (cue.Value, error) {
    cfg := &load.Config{
        Dir: stackkitDir,
    }

    instances := load.Instances([]string{"."}, cfg)
    if len(instances) == 0 {
        return cue.Value{}, fmt.Errorf("no CUE files found")
    }

    inst := instances[0]
    if inst.Err != nil {
        return cue.Value{}, inst.Err
    }

    value := v.ctx.BuildInstance(inst)
    if err := value.Err(); err != nil {
        return cue.Value{}, err
    }

    return value, nil
}
```

### 3. Integration with CUE Validator

#### File: `internal/cue/validator.go` (MODIFY)

Add Layer Validation integration:

```go
// Add to imports
import "github.com/kombihq/stackkits/internal/validation"

// Add to Validator struct
type Validator struct {
    ctx       *cue.Context
    baseDir   string
    schemaDir string
    layerVal  *validation.LayerValidator  // ADD THIS
}

// Modify NewValidator
func NewValidator(baseDir string) *Validator {
    return &Validator{
        ctx:       cuecontext.New(),
        baseDir:   baseDir,
        schemaDir: filepath.Join(baseDir, "base"),
        layerVal:  validation.NewLayerValidator(baseDir),  // ADD THIS
    }
}

// Add new method for layer validation
func (v *Validator) ValidateStackKitLayers(stackkitDir string) (*validation.StackKitValidationResult, error) {
    return v.layerVal.ValidateStackKit(stackkitDir)
}
```

### 4. Update CLI Validate Command

#### File: `cmd/stackkit/commands/validate.go` (MODIFY)

Add `--layers` flag and layer validation output:

```go
// Add flag
var (
    validateAll    bool
    validateLayers bool  // ADD THIS
)

func init() {
    validateCmd.Flags().BoolVar(&validateAll, "all", false, "Validate all configuration files")
    validateCmd.Flags().BoolVar(&validateLayers, "layers", false, "Validate 3-layer architecture")  // ADD THIS
}

// Modify runValidate to include layer validation
func runValidate(cmd *cobra.Command, args []string) error {
    // ... existing validation code ...

    // Add layer validation if requested
    if validateLayers {
        fmt.Println()
        printInfo("Validating 3-layer architecture...")

        layerResult, err := validator.ValidateStackKitLayers(wd)
        if err != nil {
            printError("Layer validation error: %v", err)
            hasErrors = true
        } else {
            printLayerValidationResult(layerResult)
            if !layerResult.Valid {
                hasErrors = true
            }
        }
    }

    // ... rest of function ...
}

// Add helper function
func printLayerValidationResult(result *validation.StackKitValidationResult) {
    fmt.Println()
    fmt.Println("┌──────────────────────────────────────────────────────────────┐")
    fmt.Println("│              3-LAYER ARCHITECTURE VALIDATION                 │")
    fmt.Println("└──────────────────────────────────────────────────────────────┘")

    // Layer 1
    fmt.Println()
    fmt.Println("Layer 1 (Foundation):")
    if result.Layer1.Valid {
        printSuccess("  ✓ System configuration present")
        printSuccess("  ✓ Base packages defined")
        printSuccess("  ✓ SSH hardening configured")
        printSuccess("  ✓ Firewall policy present")
    } else {
        for _, err := range result.Layer1.Errors {
            printError("  ✗ %s", err.Message)
            if err.Hint != "" {
                fmt.Printf("    Hint: %s\n", err.Hint)
            }
        }
    }

    // Layer 2
    fmt.Println()
    fmt.Println("Layer 2 (Platform):")
    if result.Layer2.Valid {
        printSuccess("  ✓ Platform type declared")
        printSuccess("  ✓ Container runtime configured")
        printSuccess("  ✓ Network base configured")
    } else {
        for _, err := range result.Layer2.Errors {
            printError("  ✗ %s", err.Message)
            if err.Hint != "" {
                fmt.Printf("    Hint: %s\n", err.Hint)
            }
        }
    }

    // Layer 3
    fmt.Println()
    fmt.Println("Layer 3 (Applications):")
    if result.Layer3.Valid {
        printSuccess("  ✓ PAAS/management service present")
        printSuccess("  ✓ Services configured")
    } else {
        for _, err := range result.Layer3.Errors {
            printError("  ✗ %s", err.Message)
            if err.Hint != "" {
                fmt.Printf("    Hint: %s\n", err.Hint)
            }
        }
    }

    fmt.Println()
    if result.Valid {
        printSuccess("All 3 layers validated successfully!")
    } else {
        printError("Layer validation failed - see errors above")
    }
}
```

### 5. Update StackKits to Pass Validation

#### File: `dev-homelab/stackfile.cue` (MODIFY)

Ensure it has all 3 layers defined:

```cue
package devhomelab

import "github.com/kombihq/stackkits/base"

// Stack definition with all 3 layers
#Stack: base.#StackKit & {
    // LAYER 1: FOUNDATION (embedded from base)
    // - system, packages, security already included via base.#StackKit
    
    // LAYER 2: PLATFORM
    platform: "docker"  // EXPLICITLY DECLARED
    
    // LAYER 3: APPLICATIONS
    services: {
        // PAAS Service (Required)
        dokploy: #Services.dokploy & {
            enabled: true
        }
        
        // Additional services
        uptimeKuma: #Services.uptimeKuma & {
            enabled: true
        }
        
        whoami: #Services.whoami & {
            enabled: true
        }
    }
}

stack: #Stack
```

#### File: `dev-homelab/services.cue` (MODIFY)

Add explicit `type` field to services:

```cue
// Dokploy - PAAS/Management Tool
#DokployService: base.#Service & {
    name:        "dokploy"
    image:       "dokploy/dokploy:latest"
    description: "Open-source PAAS for deploying applications"
    role:        "paas"  // ADD THIS
    type:        "paas"  // ADD THIS - for Layer 3 validation
    // ... rest of service definition
}

// Uptime Kuma - Monitoring Service
#UptimeKumaService: base.#Service & {
    name:        "uptime-kuma"
    image:       "louislam/uptime-kuma:1"
    description: "Self-hosted monitoring tool"
    role:        "monitoring"
    type:        "monitoring"  // ADD THIS
    // ... rest of service definition
}
```

### 6. Test Coverage

#### File: `internal/validation/layer_validator_test.go` (NEW)

```go
package validation

import (
    "os"
    "path/filepath"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// TestLayerValidator_ValidateStackKit_Complete tests full validation
func TestLayerValidator_ValidateStackKit_Complete(t *testing.T) {
    // Create temporary test StackKit
    tmpDir := t.TempDir()
    stackkitDir := filepath.Join(tmpDir, "test-stackkit")
    require.NoError(t, os.MkdirAll(stackkitDir, 0755))

    // Write complete CUE file with all 3 layers
    cueContent := `
package test

// Layer 1: Foundation
system: {
    timezone: "UTC"
    locale:   "en_US.UTF-8"
}

packages: {
    core: ["curl", "wget", "git"]
    extra: ["htop"]
}

security: {
    ssh: {
        port: 22
        permitRootLogin: "no"
        passwordAuth: false
        pubkeyAuth: true
    }
    firewall: {
        enabled: true
        backend: "ufw"
        defaultInbound: "deny"
    }
}

// Layer 2: Platform
platform: "docker"

container: {
    runtime: "docker"
    version: "24.0"
}

network: {
    defaults: {
        driver: "bridge"
        subnet: "172.20.0.0/16"
    }
}

// Layer 3: Applications
services: {
    dokploy: {
        name: "dokploy"
        type: "paas"
        enabled: true
        image: "dokploy/dokploy:latest"
    }
}
`
    cuePath := filepath.Join(stackkitDir, "test.cue")
    require.NoError(t, os.WriteFile(cuePath, []byte(cueContent), 0644))

    validator := NewLayerValidator(tmpDir)
    result, err := validator.ValidateStackKit(stackkitDir)

    require.NoError(t, err)
    assert.True(t, result.Valid, "Expected valid StackKit")
    assert.True(t, result.Layer1.Valid, "Layer 1 should be valid")
    assert.True(t, result.Layer2.Valid, "Layer 2 should be valid")
    assert.True(t, result.Layer3.Valid, "Layer 3 should be valid")
}

// TestLayerValidator_ValidateStackKit_MissingLayer1 tests missing foundation
func TestLayerValidator_ValidateStackKit_MissingLayer1(t *testing.T) {
    tmpDir := t.TempDir()
    stackkitDir := filepath.Join(tmpDir, "test-stackkit")
    require.NoError(t, os.MkdirAll(stackkitDir, 0755))

    // Missing system configuration
    cueContent := `
package test

// Missing Layer 1 system config

// Layer 2: Platform
platform: "docker"

// Layer 3: Applications
services: {
    dokploy: {
        type: "paas"
        enabled: true
    }
}
`
    cuePath := filepath.Join(stackkitDir, "test.cue")
    require.NoError(t, os.WriteFile(cuePath, []byte(cueContent), 0644))

    validator := NewLayerValidator(tmpDir)
    result, err := validator.ValidateStackKit(stackkitDir)

    require.NoError(t, err)
    assert.False(t, result.Valid, "Expected invalid StackKit")
    assert.False(t, result.Layer1.Valid, "Layer 1 should be invalid")
    assert.NotEmpty(t, result.Layer1.Errors, "Layer 1 should have errors")
    
    // Check specific error
    found := false
    for _, e := range result.Layer1.Errors {
        if e.Code == "L1_MISSING_SYSTEM" {
            found = true
            break
        }
    }
    assert.True(t, found, "Should have L1_MISSING_SYSTEM error")
}

// TestLayerValidator_ValidateStackKit_MissingLayer2 tests missing platform
func TestLayerValidator_ValidateStackKit_MissingLayer2(t *testing.T) {
    tmpDir := t.TempDir()
    stackkitDir := filepath.Join(tmpDir, "test-stackkit")
    require.NoError(t, os.MkdirAll(stackkitDir, 0755))

    // Missing platform declaration
    cueContent := `
package test

// Layer 1: Foundation
system: {
    timezone: "UTC"
}

packages: {
    core: ["curl"]
}

security: {
    ssh: {
        port: 22
        permitRootLogin: "no"
    }
    firewall: {
        enabled: true
        backend: "ufw"
    }
}

// Missing Layer 2 platform declaration

// Layer 3: Applications
services: {
    dokploy: {
        type: "paas"
        enabled: true
    }
}
`
    cuePath := filepath.Join(stackkitDir, "test.cue")
    require.NoError(t, os.WriteFile(cuePath, []byte(cueContent), 0644))

    validator := NewLayerValidator(tmpDir)
    result, err := validator.ValidateStackKit(stackkitDir)

    require.NoError(t, err)
    assert.False(t, result.Valid, "Expected invalid StackKit")
    assert.False(t, result.Layer2.Valid, "Layer 2 should be invalid")
    
    found := false
    for _, e := range result.Layer2.Errors {
        if e.Code == "L2_MISSING_PLATFORM" {
            found = true
            break
        }
    }
    assert.True(t, found, "Should have L2_MISSING_PLATFORM error")
}

// TestLayerValidator_ValidateStackKit_MissingLayer3 tests missing PAAS
func TestLayerValidator_ValidateStackKit_MissingLayer3(t *testing.T) {
    tmpDir := t.TempDir()
    stackkitDir := filepath.Join(tmpDir, "test-stackkit")
    require.NoError(t, os.MkdirAll(stackkitDir, 0755))

    // Missing PAAS service
    cueContent := `
package test

// Layer 1: Foundation
system: {
    timezone: "UTC"
}

packages: {
    core: ["curl"]
}

security: {
    ssh: {
        port: 22
        permitRootLogin: "no"
    }
    firewall: {
        enabled: true
        backend: "ufw"
    }
}

// Layer 2: Platform
platform: "docker"

// Layer 3: Applications (no PAAS service)
services: {
    whoami: {
        type: "utility"
        enabled: true
    }
}
`
    cuePath := filepath.Join(stackkitDir, "test.cue")
    require.NoError(t, os.WriteFile(cuePath, []byte(cueContent), 0644))

    validator := NewLayerValidator(tmpDir)
    result, err := validator.ValidateStackKit(stackkitDir)

    require.NoError(t, err)
    assert.False(t, result.Valid, "Expected invalid StackKit")
    assert.False(t, result.Layer3.Valid, "Layer 3 should be invalid")
    
    found := false
    for _, e := range result.Layer3.Errors {
        if e.Code == "L3_MISSING_PAAS" {
            found = true
            break
        }
    }
    assert.True(t, found, "Should have L3_MISSING_PAAS error")
}

// TestLayerValidator_ValidateStackKit_InvalidPlatform tests invalid platform
func TestLayerValidator_ValidateStackKit_InvalidPlatform(t *testing.T) {
    tmpDir := t.TempDir()
    stackkitDir := filepath.Join(tmpDir, "test-stackkit")
    require.NoError(t, os.MkdirAll(stackkitDir, 0755))

    cueContent := `
package test

// Layer 1: Foundation
system: { timezone: "UTC" }
packages: { core: ["curl"] }
security: {
    ssh: { port: 22, permitRootLogin: "no" }
    firewall: { enabled: true, backend: "ufw" }
}

// Layer 2: Invalid platform
platform: "invalid-platform"

// Layer 3: Applications
services: {
    dokploy: { type: "paas", enabled: true }
}
`
    cuePath := filepath.Join(stackkitDir, "test.cue")
    require.NoError(t, os.WriteFile(cuePath, []byte(cueContent), 0644))

    validator := NewLayerValidator(tmpDir)
    result, err := validator.ValidateStackKit(stackkitDir)

    require.NoError(t, err)
    assert.False(t, result.Valid, "Expected invalid StackKit")
    
    found := false
    for _, e := range result.Layer2.Errors {
        if e.Code == "L2_INVALID_PLATFORM_VALUE" {
            found = true
            break
        }
    }
    assert.True(t, found, "Should have L2_INVALID_PLATFORM_VALUE error")
}
```

#### File: `tests/integration/layer_validation_test.go` (NEW)

```go
package integration

import (
    "path/filepath"
    "testing"

    "github.com/kombihq/stackkits/internal/validation"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// TestLayerValidation_ExistingStackKits validates existing StackKits
func TestLayerValidation_ExistingStackKits(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test in short mode")
    }

    projectRoot := getProjectRoot(t)

    testCases := []struct {
        name      string
        stackkit  string
        wantValid bool
    }{
        {
            name:      "dev-homelab",
            stackkit:  "dev-homelab",
            wantValid: true,
        },
        {
            name:      "base-homelab",
            stackkit:  "base-homelab",
            wantValid: true,
        },
        {
            name:      "ha-homelab",
            stackkit:  "ha-homelab",
            wantValid: true,
        },
        {
            name:      "modern-homelab",
            stackkit:  "modern-homelab",
            wantValid: true,
        },
    }

    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            stackkitDir := filepath.Join(projectRoot, tc.stackkit)
            
            validator := validation.NewLayerValidator(projectRoot)
            result, err := validator.ValidateStackKit(stackkitDir)

            require.NoError(t, err)
            
            if tc.wantValid {
                assert.True(t, result.Valid, 
                    "StackKit %s should pass layer validation. Errors: %v", 
                    tc.stackkit, result.AllErrors)
            } else {
                assert.False(t, result.Valid, 
                    "StackKit %s should fail layer validation", tc.stackkit)
            }
        })
    }
}
```

## Implementation Checklist

### Phase 1: Core Validation (Priority: High)
- [ ] Create `base/layers.cue` with layer schemas
- [ ] Create `internal/validation/layer_validator.go`
- [ ] Add LayerValidator to `internal/cue/validator.go`
- [ ] Update `cmd/stackkit/commands/validate.go` with layer flags

### Phase 2: StackKit Updates (Priority: High)
- [ ] Update `dev-homelab/stackfile.cue` with explicit platform
- [ ] Update `dev-homelab/services.cue` with service types
- [ ] Update `base-homelab` StackKit for validation
- [ ] Update `ha-homelab` StackKit for validation
- [ ] Update `modern-homelab` StackKit for validation

### Phase 3: Testing (Priority: Medium)
- [ ] Create `internal/validation/layer_validator_test.go`
- [ ] Create `tests/integration/layer_validation_test.go`
- [ ] Add test cases for all error scenarios
- [ ] Run tests to verify implementation

### Phase 4: Documentation (Priority: Low)
- [ ] Update CLI help text
- [ ] Add validation error code reference
- [ ] Document layer requirements in StackKit README

## Error Code Reference

| Code | Layer | Description |
|------|-------|-------------|
| L1_LOAD_ERROR | 1 | Failed to load CUE files |
| L1_MISSING_SYSTEM | 1 | Missing system configuration |
| L1_MISSING_PACKAGES | 1 | Missing base packages |
| L1_MISSING_SSH | 1 | Missing SSH hardening |
| L1_MISSING_FIREWALL | 1 | Missing firewall policy |
| L2_LOAD_ERROR | 2 | Failed to load CUE files |
| L2_MISSING_PLATFORM | 2 | Platform type not declared |
| L2_INVALID_PLATFORM | 2 | Platform has invalid type |
| L2_INVALID_PLATFORM_VALUE | 2 | Platform value not in allowed set |
| L2_MISSING_CONTAINER | 2 | Missing container runtime config |
| L2_MISSING_NETWORK | 2 | Missing network base config |
| L3_LOAD_ERROR | 3 | Failed to load CUE files |
| L3_MISSING_SERVICES | 3 | No services defined |
| L3_MISSING_PAAS | 3 | No PAAS/management service found |

## Usage Examples

```bash
# Validate a StackKit with layer validation
stackkit validate --layers ./dev-homelab

# Validate all CUE files including layer architecture
stackkit validate --all --layers

# Run tests
go test ./internal/validation/...
go test ./tests/integration/... -v
```

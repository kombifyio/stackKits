# Research: CUE-basierte Validierungs-Pipelines & IaC-Spec-Generierung

> **Status:** Research Complete  
> **Version:** 1.0  
> **Date:** 2026-01-10  
> **Purpose:** Best Practices für KombiStack Unifier Engine

---

## 📚 BEST PRACTICES

### 1. CUE Schema Design

#### 1.1 Definition-First Pattern
```cue
// Verwende #-Präfix für Schemata (Definitions)
// Diese sind geschlossene Strukturen - keine unbekannten Felder erlaubt
#IntentSpec: {
    goals!:    #Goals      // Required (!)
    network!:  #NetworkMode
    variant?:  string      // Optional (?)
}

#Goals: {
    storage?: bool
    media?:   bool
    ...       // Erlaubt Erweiterungen
}
```

**Empfehlung für KombiStack:**
- Alle Schemata mit `#` definieren (geschlossene Strukturen)
- Required-Felder mit `!` markieren
- Optional-Felder mit `?` markieren
- Explizit `...` für erweiterbare Strukturen

#### 1.2 Constraint-basierte Validierung
```cue
import "strings"

#Config: {
    // Typ + Range-Constraint
    port!: int & >=1024 & <65536
    
    // Enum-Constraint
    logLevel!: "debug" | "info" | "warn" | "error"
    
    // Regex-Constraint
    hostname!: =~"^[a-z][a-z0-9-]*$"
    
    // String-Constraint
    domain!: strings.HasSuffix(".local") | strings.HasSuffix(".io")
    
    // Relationale Constraints
    minReplicas?: int & <maxReplicas
    maxReplicas?: int & >minReplicas
}
```

#### 1.3 Schema-Versionierung
```cue
// Definiere explizite Versionen für Backwards-Compatibility
#V1IntentSpec: {
    goals!: {...}
}

#V2IntentSpec: #V1IntentSpec & {
    // Neue optionale Felder sind backwards-compatible
    advanced?: #AdvancedOptions
}

// BREAKING: Required-Felder oder Typ-Änderungen
#V3IntentSpec: {
    goals!: {...}
    network!: #NetworkMode  // War optional, jetzt required
}
```

---

### 2. Multi-Stage Validation Pipeline

#### 2.1 Pipeline-Struktur (inspiriert von Crossplane)

```
┌─────────────────────────────────────────────────────────────────┐
│                    VALIDATION PIPELINE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STAGE 1: SYNTAX VALIDATION                                      │
│  ─────────────────────────────                                   │
│  • CUE Parsing                                                   │
│  • Grundlegende Typ-Prüfung                                     │
│  • Schema-Konformität                                           │
│  Output: Parsed Intent                                          │
│                                                                  │
│  STAGE 2: SEMANTIC VALIDATION                                    │
│  ─────────────────────────────                                   │
│  • Business-Rule Validation                                      │
│  • Cross-Field Dependencies                                      │
│  • StackKit Compatibility Check                                 │
│  Output: Validated Intent                                       │
│                                                                  │
│  STAGE 3: REQUIREMENTS RESOLUTION                                │
│  ─────────────────────────────────                              │
│  • Hardware-Requirements ableiten                               │
│  • Service-Dependencies auflösen                                │
│  • Resource-Calculations                                        │
│  Output: Requirements Spec                                      │
│                                                                  │
│  STAGE 4: HARDWARE VALIDATION                                    │
│  ────────────────────────────                                   │
│  • Actual vs. Required Hardware                                 │
│  • Capacity Planning                                            │
│  • Compatibility Check                                          │
│  Output: Validated Requirements                                 │
│                                                                  │
│  STAGE 5: UNIFICATION                                           │
│  ────────────────────────                                       │
│  • Intent + Requirements + Hardware → Unified Spec              │
│  • Defaults anwenden                                            │
│  • Derived Values berechnen                                     │
│  Output: Unified Spec                                           │
│                                                                  │
│  STAGE 6: IAC GENERATION                                        │
│  ───────────────────────                                        │
│  • Template Rendering                                           │
│  • HCL Generation                                               │
│  • Final Validation                                             │
│  Output: OpenTofu Configuration                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### 2.2 Stage-Implementierung in CUE

```cue
package pipeline

// Stage 1: Syntax/Schema Validation
#Stage1Output: {
    valid:     bool
    intent:    #IntentSpec
    errors:    [...string]
}

// Stage 2: Semantic Validation  
#Stage2Output: #Stage1Output & {
    warnings:  [...string]
    stackKit:  #StackKitRef
}

// Stage 3: Requirements Resolution
#Stage3Output: {
    requirements: #RequirementsSpec
    services:     [...#ServiceSpec]
    dependencies: [...#DependencyGraph]
}

// Pipeline Context (wird durch alle Stages gereicht)
#PipelineContext: {
    stage:       int
    input:       _
    output:      _
    errors:      [...string]
    warnings:    [...string]
    metadata: {
        startTime:   string
        stackKitId:  string
        workerId?:   string
    }
}
```

---

### 3. Intent → Requirements → Unified Spec Pattern

#### 3.1 Separation of Concerns

**Crossplane-inspiriertes Pattern:**

```
User Intent (Was)      →  Requirements (Wie viel)  →  Unified Spec (Wie genau)
────────────────────      ──────────────────────      ──────────────────────────
"Ich will Media-Server"   "Braucht 4GB RAM,         "Container X mit Image Y,
                          8GB Storage,               Port 8080, Volume Z,
                          GPU optional"              Environment vars..."
```

#### 3.2 Intent Spec (User-Facing)
```cue
// Was der User WILL - keine technischen Details
#IntentSpec: {
    name!:    string & =~"^[a-z][a-z0-9-]*$"
    
    // High-Level Goals
    goals!: {
        storage?:    bool   // "Ich will Dateien speichern"
        media?:      bool   // "Ich will Medien streamen"  
        monitoring?: bool   // "Ich will System überwachen"
    }
    
    // Preferences (nicht Implementierung)
    preferences?: {
        security?:    "relaxed" | "standard" | "hardened"
        performance?: "minimal" | "balanced" | "maximum"
    }
    
    // Network Intent
    network!: {
        mode!:   "local" | "public"
        domain?: string  // Nur bei public
    }
}
```

#### 3.3 Requirements Spec (System-Generated)
```cue
// Technische Anforderungen, abgeleitet vom Intent
#RequirementsSpec: {
    // Hardware Requirements
    hardware!: {
        minCPU!:    int & >=1       // Cores
        minRAM!:    int & >=512     // MB
        minDisk!:   int & >=1024    // MB
        gpu?:       #GPURequirement
    }
    
    // Software Requirements
    software!: {
        docker!:     bool | *true
        dockerCompose?: bool
        kernel?:     string  // Min kernel version
    }
    
    // Network Requirements
    network!: {
        ports!:      [...int]
        protocols!:  [...("tcp" | "udp")]
        dns?:        bool
        publicIP?:   bool
    }
    
    // Derived from Intent + StackKit
    services!: [...#ServiceRequirement]
}

#ServiceRequirement: {
    name!:     string
    image!:    string
    ram!:      int
    cpu?:      float
    ports?:    [...int]
    volumes?:  [...string]
    depends?:  [...string]
}
```

#### 3.4 Unified Spec (Execution-Ready)
```cue
// Vollständig aufgelöste Konfiguration für IaC-Generation
#UnifiedSpec: {
    metadata!: {
        name!:        string
        stackKitId!:  string
        version!:     string
        generatedAt!: string
    }
    
    // Resolved Hardware Assignment
    worker!: {
        id!:       string
        hostname!: string
        ip!:       string
        // Actual hardware (from Agent)
        hardware!: #HardwareInfo
    }
    
    // Fully resolved service configurations
    services!: [...#ResolvedService]
    
    // Resolved network configuration
    network!: #ResolvedNetwork
    
    // Generated credentials
    credentials!: [...#Credential]
    
    // OpenTofu variables
    tfvars!: {...}
}
```

---

### 4. Spec-Persistierung & Audit-Trail

#### 4.1 Persistierungs-Strategie

**Empfehlungen basierend auf GitOps-Best-Practices:**

```
┌───────────────────────────────────────────────────────────────────┐
│                    SPEC PERSISTENCE STRATEGY                       │
├───────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. GIT-BACKED SPECS (Primary)                                    │
│     • kombination.yaml → Git Repository                           │
│     • Version-controlled                                          │
│     • Human-readable diffs                                        │
│     • Code-Review möglich                                         │
│                                                                    │
│  2. DATABASE SNAPSHOTS (Secondary)                                │
│     • Intermediate Specs in PocketBase                            │
│     • Quick lookups                                               │
│     • State Tracking                                              │
│                                                                    │
│  3. AUDIT TRAIL EVENTS                                            │
│     • Jeder Pipeline-Stage-Übergang                               │
│     • Validation Errors                                           │
│     • User Actions                                                │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘
```

#### 4.2 Audit-Trail Schema
```cue
#AuditEvent: {
    id!:        string
    timestamp!: string
    
    // Event Classification
    type!:      "validation" | "transformation" | "execution" | "error"
    stage!:     string  // Pipeline stage
    
    // Context
    stackId!:   string
    userId?:    string
    workerId?:  string
    
    // Payload
    action!:    string
    input?:     _       // Stage input (optional, kann groß sein)
    output?:    _       // Stage output
    errors?:    [...string]
    
    // Metadata
    duration?:  int     // ms
    version!:   string  // System version
}
```

#### 4.3 Persistierungs-Patterns

```cue
// Pattern: Immutable Specs mit Versions-Referenzen
#SpecVersion: {
    id!:        string  // UUID
    specType!:  "intent" | "requirements" | "unified"
    version!:   int     // Incrementing
    
    // Content Hash für Integrity
    contentHash!: string
    
    // Temporal Validity
    createdAt!:  string
    supersededBy?: string  // ID der neueren Version
    
    // Actual Content
    spec!: _
}

// Pattern: Spec-Chain (wie Git Commits)
#SpecChain: {
    head!:     string  // Current spec version ID
    history!:  [...#SpecVersion]
}
```

---

### 5. Hardware-Requirements Validation Patterns

#### 5.1 Requirement Expressions
```cue
#HardwareRequirement: {
    // Minimum Requirements
    minCPU!:    int & >=1
    minRAM!:    int & >=256      // MB
    minDisk!:   int & >=1024     // MB
    
    // Recommended (für Performance-Warnings)
    recCPU?:    int
    recRAM?:    int
    recDisk?:   int
    
    // Architecture Constraints
    arch?:      "amd64" | "arm64" | "arm/v7"
    
    // GPU Requirements
    gpu?: {
        required!: bool
        vram?:     int  // MB
        vendors?:  [...("nvidia" | "amd" | "intel")]
    }
}
```

#### 5.2 Validation Logic
```cue
#HardwareValidation: {
    required!:  #HardwareRequirement
    actual!:    #HardwareInfo
    
    // Computed Validation Results
    cpuOk:      actual.cores >= required.minCPU
    ramOk:      actual.ramMB >= required.minRAM
    diskOk:     actual.diskMB >= required.minDisk
    archOk:     required.arch == _|_ | required.arch == actual.arch
    
    // GPU Validation (wenn required)
    gpuOk:      !required.gpu.required | 
                (actual.gpu != _|_ & actual.gpu.vram >= required.gpu.vram)
    
    // Overall Result
    valid:      cpuOk & ramOk & diskOk & archOk & gpuOk
    
    // Detailed Errors
    errors: [
        if !cpuOk { "Insufficient CPU: need \(required.minCPU), have \(actual.cores)" },
        if !ramOk { "Insufficient RAM: need \(required.minRAM)MB, have \(actual.ramMB)MB" },
        if !diskOk { "Insufficient Disk: need \(required.minDisk)MB, have \(actual.diskMB)MB" },
        if !archOk { "Architecture mismatch: need \(required.arch), have \(actual.arch)" },
        if !gpuOk { "GPU requirement not met" },
    ]
    
    // Warnings (Recommended vs Actual)
    warnings: [
        if required.recRAM != _|_ & actual.ramMB < required.recRAM {
            "Below recommended RAM: \(required.recRAM)MB recommended, \(actual.ramMB)MB available"
        },
    ]
}
```

---

## 🏛️ PATTERN-BEISPIELE

### Pattern 1: Crossplane Composition Pipeline

**Konzept:** Sequentielle Function-Pipeline mit State-Passing

```yaml
# Crossplane-Style Pipeline in YAML (zur Illustration)
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
spec:
  mode: Pipeline
  pipeline:
    - step: validate-intent
      functionRef:
        name: function-cue
      input:
        kind: CUEInput
        script: |
          #request.observed.composite.resource
          // Validate against IntentSpec schema
          
    - step: resolve-requirements
      functionRef:
        name: function-cue
      input:
        kind: CUEInput
        script: |
          // Input: validated intent
          // Output: requirements spec
          
    - step: generate-resources
      functionRef:
        name: function-patch-and-transform
```

**KombiStack-Anwendung:**
```go
// Pipeline-Orchestrator in Go
type Pipeline struct {
    stages []Stage
}

type Stage interface {
    Name() string
    Execute(ctx *PipelineContext) error
}

func (p *Pipeline) Run(input IntentSpec) (*UnifiedSpec, error) {
    ctx := &PipelineContext{Input: input}
    
    for _, stage := range p.stages {
        if err := stage.Execute(ctx); err != nil {
            ctx.RecordError(stage.Name(), err)
            return nil, err
        }
        ctx.RecordTransition(stage.Name())
    }
    
    return ctx.UnifiedSpec, nil
}
```

---

### Pattern 2: Configuration-as-Data (Terraform-Style)

**Konzept:** Alles ist Daten, Logic lebt in Transformationen

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Intent Data    │────▶│  Transformation  │────▶│   Config Data    │
│   (YAML/CUE)     │     │  (CUE Scripts)   │     │   (HCL/JSON)     │
└──────────────────┘     └──────────────────┘     └──────────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
   Human-editable           Versioned              Machine-readable
   High-level               Tested                 Execution-ready
```

**KombiStack-Anwendung:**
```cue
// transformation.cue
package transform

import "encoding/json"

// Input: User Intent
_intent: #IntentSpec

// Transformation Logic
_services: [
    if _intent.goals.storage { #StorageService },
    if _intent.goals.media { #MediaService },
    if _intent.goals.monitoring { #MonitoringService },
]

// Output: Terraform-ready JSON
output: json.Marshal({
    resource: {
        docker_container: {
            for s in _services {
                "\(s.name)": s.config
            }
        }
    }
})
```

---

### Pattern 3: Spec-Driven Development

**Konzept:** Spec ist Single Source of Truth

```
┌─────────────────────────────────────────────────────────────┐
│                  SPEC-DRIVEN WORKFLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. SPEC DEFINITION                                          │
│     spec.md → plan.md → tasks.md                            │
│     (Human intent → Implementation plan → Atomic tasks)      │
│                                                              │
│  2. SPEC VALIDATION                                          │
│     CUE Schema validates spec completeness                   │
│     All required fields present                              │
│     Cross-references valid                                   │
│                                                              │
│  3. SPEC EXECUTION                                           │
│     Spec drives all downstream generation                    │
│     Changes to spec trigger regeneration                     │
│     Drift = Spec vs. Actual divergence                      │
│                                                              │
│  4. SPEC TRACKING                                            │
│     Spec versions tracked                                    │
│     Audit trail of changes                                   │
│     Rollback via spec version                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**KombiStack-Anwendung:**

Die kombination.yaml IST die Spec:
```yaml
# kombination.yaml - Single Source of Truth
apiVersion: kombistack.io/v1
kind: Kombination
metadata:
  name: my-homelab
spec:
  # Intent Layer
  goals:
    storage: true
    media: true
  
  # Preferences Layer  
  network:
    mode: public
    domain: home.example.com
    
  # StackKit Selection
  stackKit: base-homelab
  variant: default
```

---

## 💡 EMPFEHLUNGEN FÜR KOMBISTACK

### 1. Pipeline-Architektur

```
Empfohlene Pipeline-Struktur:
─────────────────────────────

Stage 1: ParseIntent
  Input:  kombination.yaml (raw)
  Output: IntentSpec (parsed, schema-validated)
  CUE:    intent.cue schema validation

Stage 2: SelectStackKit
  Input:  IntentSpec
  Output: StackKitRef + RequirementsSpec
  CUE:    stackkit.cue selection logic

Stage 3: ValidateHardware
  Input:  RequirementsSpec + WorkerInfo
  Output: HardwareValidationResult
  CUE:    hardware.cue validation

Stage 4: GenerateUnifiedSpec
  Input:  IntentSpec + RequirementsSpec + WorkerInfo
  Output: UnifiedSpec
  CUE:    unified.cue generation

Stage 5: GenerateIaC
  Input:  UnifiedSpec
  Output: OpenTofu HCL files
  Go:     Template rendering
```

### 2. CUE Schema Organisation

```
stackkits/
├── base/
│   └── schema/
│       ├── _types.cue        # Shared types
│       ├── intent.cue        # IntentSpec schema
│       ├── requirements.cue  # RequirementsSpec schema
│       ├── unified.cue       # UnifiedSpec schema
│       ├── worker.cue        # WorkerInfo schema
│       └── validation.cue    # Validation helpers
```

### 3. Spec-Persistierung

```go
// Empfohlene Persistierung
type SpecStore interface {
    // Immutable spec versions
    SaveSpec(spec interface{}, specType string) (SpecVersion, error)
    GetSpec(id string) (interface{}, error)
    
    // Version chain
    GetHistory(stackId string) ([]SpecVersion, error)
    GetLatest(stackId string, specType string) (interface{}, error)
    
    // Audit
    RecordEvent(event AuditEvent) error
    GetEvents(stackId string, filter EventFilter) ([]AuditEvent, error)
}
```

### 4. Error-Handling Pattern

```cue
// Strukturierte Fehler für bessere UX
#ValidationError: {
    code!:       string    // "INSUFFICIENT_RAM"
    message!:    string    // Human-readable
    field?:      string    // "hardware.minRAM"
    expected?:   _         // Was erwartet wurde
    actual?:     _         // Was vorhanden ist
    suggestion?: string    // Wie beheben
}

// Beispiel
errors: [
    {
        code:       "INSUFFICIENT_RAM"
        message:    "Not enough RAM for selected services"
        field:      "requirements.hardware.minRAM"
        expected:   4096
        actual:     2048
        suggestion: "Consider using 'minimal' variant or adding more RAM"
    }
]
```

---

## 📖 QUELLEN & REFERENZEN

### CUE Language
- **CUE Official Documentation**: https://cuelang.org/docs/
- **CUE Schema Definition Use Case**: https://cuelang.org/docs/concept/schema-definition-use-case
- **CUE Data Validation**: https://cuelang.org/docs/concept/data-validation-use-case
- **CUE Configuration**: https://cuelang.org/docs/concept/how-cue-enables-configuration

### Crossplane Patterns
- **Composition Functions**: https://docs.crossplane.io/latest/composition/compositions/
- **Function Pipeline Architecture**: https://github.com/crossplane/crossplane/blob/main/design/design-doc-composition-functions.md
- **Function-CUE**: https://github.com/crossplane-contrib/function-cue

### IaC Best Practices
- **Spec-Driven Development**: https://medium.com/@tonylixu/ai-native-dev-3-spec-driven-development
- **Infrastructure as Code Patterns**: https://spacelift.io/blog/infrastructure-as-code
- **GitOps Practices**: https://dev.to/_steve_fenton_/6-gitops-practices-that-actually-work

### Audit & Compliance
- **Audit Logging Best Practices**: https://www.sonarsource.com/resources/library/audit-logging/
- **Change Management**: https://www.bizbot.com/blog/change-approval-best-practices-data-management/

### Configuration Comparison
- **Declarative Infrastructure Beyond YAML**: https://sqlstad.nl/posts/2025/declarative-infrastructures-next-chapter/

---

## 📋 ZUSAMMENFASSUNG

| Aspekt | Empfehlung |
|--------|------------|
| **Pipeline-Struktur** | 6-Stage Pipeline mit klarer Separation |
| **Schema-Design** | Geschlossene Definitions mit `#`, Required `!`, Optional `?` |
| **Intent vs. Requirements** | Strikt trennen - Intent ist was, Requirements ist wie viel |
| **Persistierung** | Git-backed Specs + DB-Snapshots + Audit Events |
| **Hardware-Validation** | CUE-basierte Constraint-Prüfung mit strukturierten Fehlern |
| **Error-Handling** | Strukturierte Fehler mit Code, Message, Field, Suggestion |
| **Versionierung** | Semantic Versioning für Schemas, Content-Hash für Specs |

---

**Nächste Schritte:**
1. CUE Schema-Definitionen in `base/schema/` implementieren
2. Pipeline-Stages in Go implementieren
3. Audit-Trail in PocketBase integrieren
4. Hardware-Validation Tests schreiben

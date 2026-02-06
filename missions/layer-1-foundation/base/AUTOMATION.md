# Foundation Layer: Base Automation Architecture

**Scope:** This document defines the universal automation patterns, data models, lifecycle operations, and API structures used by ALL StackKits. Platform-specific automation (Docker, Kubernetes) extends these patterns in Layer 2.

---

## 1. Automation Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AUTOMATION LAYERS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                      Layer 1: FOUNDATION                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │ Data Model  │  │ Lifecycle   │  │ Code Gen    │  │ API Layer   │  │  │
│  │  │ (Prisma)    │  │ Operations  │  │ Templates   │  │ (REST/CLI)  │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                      Layer 2: PLATFORM                                │  │
│  │              (Docker / Kubernetes / Docker Swarm)                     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                                    ▼                                         │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                      Layer 3: STACKKITS                               │  │
│  │              (base-homelab / modern-homelab / ha-homelab)             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Model (Prisma Schema)

### 2.1 Complete Prisma Schema

```prisma
// StackKits Administration Database Schema
// Version: 1.0.0
// Database: PostgreSQL

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================================================
// ENUMS
// ============================================================================

enum StackStatus {
  DRAFT
  VALIDATING
  VALID
  INVALID
  DEPLOYING
  DEPLOYED
  FAILED
  STOPPED
  DEGRADED
  UPDATING
  DESTROYING
}

enum ServiceStatus {
  PENDING
  STARTING
  RUNNING
  HEALTHY
  UNHEALTHY
  STOPPED
  FAILED
  RESTARTING
}

enum OperationType {
  INIT
  VALIDATE
  PLAN
  APPLY
  DESTROY
  UPDATE
  ROLLBACK
  HEALTHCHECK
}

enum Severity {
  DEBUG
  INFO
  WARNING
  ERROR
  CRITICAL
}

enum ResourceTier {
  MICRO
  SMALL
  MEDIUM
  LARGE
  XLARGE
}

enum CriticalityLevel {
  CRITICAL
  IMPORTANT
  NORMAL
  OPTIONAL
}

enum BackupType {
  FULL
  INCREMENTAL
  DIFFERENTIAL
  SNAPSHOT
}

enum BackupStatus {
  PENDING
  RUNNING
  COMPLETED
  FAILED
  EXPIRED
}

// ============================================================================
// CORE ENTITIES
// ============================================================================

model Stack {
  id            String        @id @default(cuid())
  name          String        @unique
  description   String?
  version       String
  variant       String        @default("standard")
  status        StackStatus   @default(DRAFT)
  
  // Configuration
  configHash    String?       // SHA256 of current config
  configPath    String?       // Path to stackkit.yaml
  
  // Relations
  services      Service[]
  networks      Network[]
  volumes       Volume[]
  deployments   Deployment[]
  operations    Operation[]
  backups       Backup[]
  alerts        Alert[]
  
  // Timestamps
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt
  deployedAt    DateTime?
  
  // Metadata
  labels        Json?
  annotations   Json?
  
  @@index([status])
  @@index([createdAt])
}

model Service {
  id              String          @id @default(cuid())
  name            String
  description     String?
  
  // Container settings
  image           String
  imageTag        String          @default("latest")
  imageDigest     String?
  
  // Classification
  category        String          @default("application")
  criticality     CriticalityLevel @default(NORMAL)
  
  // Status
  status          ServiceStatus   @default(PENDING)
  healthStatus    String?
  lastHealthCheck DateTime?
  
  // Resources
  resourceTier    ResourceTier    @default(SMALL)
  memoryLimit     String?
  cpuLimit        Float?
  
  // Restart policy
  restartPolicy   String          @default("unless-stopped")
  restartCount    Int             @default(0)
  
  // Relations
  stack           Stack           @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId         String
  ports           Port[]
  envVars         EnvironmentVariable[]
  mounts          Mount[]
  healthChecks    HealthCheck[]
  logs            Log[]
  metrics         Metric[]
  dependencies    ServiceDependency[] @relation("dependent")
  dependents      ServiceDependency[] @relation("dependency")
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  startedAt       DateTime?
  
  // Metadata
  labels          Json?
  
  @@unique([stackId, name])
  @@index([status])
  @@index([criticality])
}

model ServiceDependency {
  id           String   @id @default(cuid())
  dependent    Service  @relation("dependent", fields: [dependentId], references: [id], onDelete: Cascade)
  dependentId  String
  dependency   Service  @relation("dependency", fields: [dependencyId], references: [id], onDelete: Cascade)
  dependencyId String
  required     Boolean  @default(true)
  condition    String   @default("service_healthy")
  
  @@unique([dependentId, dependencyId])
}

model Port {
  id          String   @id @default(cuid())
  hostPort    Int
  containerPort Int
  protocol    String   @default("tcp")
  published   Boolean  @default(true)
  
  service     Service  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  serviceId   String
  
  @@unique([serviceId, hostPort, protocol])
}

model EnvironmentVariable {
  id          String   @id @default(cuid())
  name        String
  value       String?
  secret      Boolean  @default(false)
  fromFile    String?
  
  service     Service  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  serviceId   String
  
  @@unique([serviceId, name])
}

model Mount {
  id            String   @id @default(cuid())
  source        String
  target        String
  type          String   @default("volume")
  readOnly      Boolean  @default(false)
  
  service       Service  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  serviceId     String
  volume        Volume?  @relation(fields: [volumeId], references: [id])
  volumeId      String?
  
  @@unique([serviceId, target])
}

// ============================================================================
// NETWORKING
// ============================================================================

model Network {
  id          String   @id @default(cuid())
  name        String
  driver      String   @default("bridge")
  internal    Boolean  @default(false)
  attachable  Boolean  @default(true)
  ipamDriver  String   @default("default")
  subnet      String?
  gateway     String?
  
  stack       Stack    @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId     String
  
  // Metadata
  labels      Json?
  
  @@unique([stackId, name])
}

// ============================================================================
// STORAGE
// ============================================================================

model Volume {
  id          String   @id @default(cuid())
  name        String
  driver      String   @default("local")
  driverOpts  Json?
  
  // Size tracking
  sizeBytes   BigInt?
  usedBytes   BigInt?
  
  stack       Stack    @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId     String
  mounts      Mount[]
  backups     Backup[]
  
  // Timestamps
  createdAt   DateTime @default(now())
  
  // Metadata
  labels      Json?
  
  @@unique([stackId, name])
}

// ============================================================================
// OPERATIONS & DEPLOYMENTS
// ============================================================================

model Deployment {
  id            String    @id @default(cuid())
  version       String
  configHash    String
  status        StackStatus
  
  // Execution details
  startedAt     DateTime  @default(now())
  completedAt   DateTime?
  duration      Int?      // in seconds
  
  // Results
  success       Boolean?
  errorMessage  String?
  errorDetails  Json?
  
  // Plan details
  planOutput    String?   // Tofu plan output
  changes       Json?     // Resources to create/update/delete
  
  // Rollback info
  previousId    String?
  previous      Deployment? @relation("rollback", fields: [previousId], references: [id])
  rollbacks     Deployment[] @relation("rollback")
  
  stack         Stack     @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId       String
  operations    Operation[]
  
  @@index([stackId, startedAt])
}

model Operation {
  id            String        @id @default(cuid())
  type          OperationType
  status        String        @default("pending")
  
  // Execution
  startedAt     DateTime      @default(now())
  completedAt   DateTime?
  duration      Int?
  
  // Results
  success       Boolean?
  output        String?
  errorMessage  String?
  
  // Relations
  stack         Stack         @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId       String
  deployment    Deployment?   @relation(fields: [deploymentId], references: [id])
  deploymentId  String?
  logs          Log[]
  
  @@index([stackId, startedAt])
  @@index([type])
}

// ============================================================================
// OBSERVABILITY
// ============================================================================

model HealthCheck {
  id          String   @id @default(cuid())
  type        String   @default("http")
  endpoint    String?
  command     String?
  interval    Int      @default(30)
  timeout     Int      @default(10)
  retries     Int      @default(3)
  
  // Latest result
  lastCheck   DateTime?
  lastStatus  String?
  lastOutput  String?
  
  service     Service  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  serviceId   String
}

model Log {
  id          String   @id @default(cuid())
  timestamp   DateTime @default(now())
  severity    Severity @default(INFO)
  message     String
  source      String?
  
  service     Service?  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  serviceId   String?
  operation   Operation? @relation(fields: [operationId], references: [id], onDelete: Cascade)
  operationId String?
  
  // Structured data
  metadata    Json?
  
  @@index([timestamp])
  @@index([severity])
  @@index([serviceId])
}

model Metric {
  id          String   @id @default(cuid())
  timestamp   DateTime @default(now())
  name        String
  value       Float
  unit        String?
  
  service     Service  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  serviceId   String
  
  // Labels for metric dimensions
  labels      Json?
  
  @@index([timestamp])
  @@index([serviceId, name])
}

model Alert {
  id            String   @id @default(cuid())
  name          String
  severity      Severity
  status        String   @default("active")
  message       String
  
  // Timing
  triggeredAt   DateTime @default(now())
  acknowledgedAt DateTime?
  resolvedAt    DateTime?
  
  stack         Stack    @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId       String
  
  // Context
  context       Json?
  
  @@index([status])
  @@index([severity])
  @@index([triggeredAt])
}

// ============================================================================
// BACKUP & RECOVERY
// ============================================================================

model Backup {
  id          String       @id @default(cuid())
  type        BackupType
  status      BackupStatus @default(PENDING)
  
  // Size and location
  sizeBytes   BigInt?
  path        String?
  checksum    String?
  
  // Timing
  startedAt   DateTime     @default(now())
  completedAt DateTime?
  expiresAt   DateTime?
  
  // Relations
  stack       Stack        @relation(fields: [stackId], references: [id], onDelete: Cascade)
  stackId     String
  volume      Volume?      @relation(fields: [volumeId], references: [id])
  volumeId    String?
  
  // Metadata
  metadata    Json?
  
  @@index([stackId, startedAt])
  @@index([status])
  @@index([expiresAt])
}

// ============================================================================
// CONFIGURATION & SECRETS
// ============================================================================

model Config {
  id          String   @id @default(cuid())
  key         String   @unique
  value       String
  encrypted   Boolean  @default(false)
  
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

model Secret {
  id          String   @id @default(cuid())
  name        String   @unique
  value       String   // Encrypted
  version     Int      @default(1)
  
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  expiresAt   DateTime?
  
  @@index([expiresAt])
}
```

### 2.2 Database Migrations

```bash
# Generate migration
npx prisma migrate dev --name init

# Apply migration
npx prisma migrate deploy

# Generate client
npx prisma generate
```

---

## 3. Lifecycle Operations

### 3.1 Operation Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                    LIFECYCLE STATE MACHINE                             │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────┐     ┌────────────┐     ┌─────────┐     ┌──────────┐    │
│  │  DRAFT   │────▶│ VALIDATING │────▶│  VALID  │────▶│ DEPLOYING│    │
│  └──────────┘     └────────────┘     └─────────┘     └──────────┘    │
│       │                 │                                    │        │
│       │                 ▼                                    ▼        │
│       │           ┌─────────┐                         ┌──────────┐   │
│       │           │ INVALID │                         │ DEPLOYED │   │
│       │           └─────────┘                         └──────────┘   │
│       │                                                   │   │       │
│       │                                    ┌──────────────┘   │       │
│       │                                    ▼                  ▼       │
│       │                             ┌──────────┐       ┌─────────┐   │
│       │                             │ UPDATING │       │ STOPPED │   │
│       │                             └──────────┘       └─────────┘   │
│       │                                    │                          │
│       ▼                                    ▼                          │
│  ┌──────────┐                       ┌──────────┐                     │
│  │ FAILED   │◀──────────────────────│ DEGRADED │                     │
│  └──────────┘                       └──────────┘                     │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
```

### 3.2 CLI Commands Mapping

| Command | Operation Type | Description |
|---------|---------------|-------------|
| `stackkit init` | INIT | Initialize new StackKit project |
| `stackkit validate` | VALIDATE | Run multi-stage validation |
| `stackkit prepare` | PLAN | Generate IaC code without applying |
| `stackkit plan` | PLAN | Show execution plan |
| `stackkit apply` | APPLY | Apply changes to infrastructure |
| `stackkit destroy` | DESTROY | Tear down all resources |
| `stackkit status` | HEALTHCHECK | Show current status |
| `stackkit rollback` | ROLLBACK | Revert to previous deployment |

### 3.3 Operation Implementation

```go
package lifecycle

import (
    "context"
    "time"
)

// OperationRunner executes lifecycle operations
type OperationRunner struct {
    db          *PrismaClient
    validator   *validation.Validator
    generator   *codegen.Generator
    executor    *platform.Executor
}

// RunOperation executes a single operation with full logging
func (r *OperationRunner) RunOperation(ctx context.Context, stackID string, opType OperationType) (*OperationResult, error) {
    // Create operation record
    op, err := r.db.Operation.Create(ctx, Operation{
        StackID:   stackID,
        Type:      opType,
        Status:    "running",
        StartedAt: time.Now(),
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create operation: %w", err)
    }
    
    // Execute based on type
    var result *OperationResult
    switch opType {
    case OpValidate:
        result, err = r.runValidate(ctx, stackID)
    case OpPlan:
        result, err = r.runPlan(ctx, stackID)
    case OpApply:
        result, err = r.runApply(ctx, stackID)
    case OpDestroy:
        result, err = r.runDestroy(ctx, stackID)
    case OpHealthCheck:
        result, err = r.runHealthCheck(ctx, stackID)
    default:
        return nil, fmt.Errorf("unknown operation type: %s", opType)
    }
    
    // Update operation record
    completedAt := time.Now()
    duration := int(completedAt.Sub(op.StartedAt).Seconds())
    
    _, err = r.db.Operation.Update(ctx, op.ID, Operation{
        Status:      result.Status,
        CompletedAt: &completedAt,
        Duration:    &duration,
        Success:     &result.Success,
        Output:      result.Output,
        ErrorMessage: result.Error,
    })
    
    return result, err
}

// OperationResult contains the result of an operation
type OperationResult struct {
    Success  bool
    Status   string
    Output   string
    Error    string
    Duration time.Duration
    Changes  *ChangeSet
}

// ChangeSet represents infrastructure changes
type ChangeSet struct {
    Create []Resource
    Update []Resource
    Delete []Resource
}
```

---

## 4. REST API Specification

### 4.1 API Endpoints

```yaml
openapi: 3.1.0
info:
  title: StackKits Administration API
  version: 1.0.0
  description: REST API for managing StackKit deployments

servers:
  - url: http://localhost:8080/api/v1
    description: Local development

paths:
  # Stacks
  /stacks:
    get:
      summary: List all stacks
      operationId: listStacks
      parameters:
        - name: status
          in: query
          schema:
            $ref: '#/components/schemas/StackStatus'
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
        - name: offset
          in: query
          schema:
            type: integer
            default: 0
      responses:
        '200':
          description: List of stacks
          content:
            application/json:
              schema:
                type: object
                properties:
                  items:
                    type: array
                    items:
                      $ref: '#/components/schemas/Stack'
                  total:
                    type: integer

    post:
      summary: Create a new stack
      operationId: createStack
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateStackRequest'
      responses:
        '201':
          description: Stack created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Stack'

  /stacks/{stackId}:
    get:
      summary: Get stack details
      operationId: getStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Stack details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StackDetail'

    delete:
      summary: Delete a stack
      operationId: deleteStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '204':
          description: Stack deleted

  # Operations
  /stacks/{stackId}/validate:
    post:
      summary: Validate stack configuration
      operationId: validateStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Validation result
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ValidationResult'

  /stacks/{stackId}/plan:
    post:
      summary: Generate execution plan
      operationId: planStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Execution plan
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PlanResult'

  /stacks/{stackId}/apply:
    post:
      summary: Apply stack changes
      operationId: applyStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                autoApprove:
                  type: boolean
                  default: false
      responses:
        '202':
          description: Apply started
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Operation'

  /stacks/{stackId}/destroy:
    post:
      summary: Destroy stack resources
      operationId: destroyStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '202':
          description: Destroy started
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Operation'

  # Services
  /stacks/{stackId}/services:
    get:
      summary: List services in a stack
      operationId: listServices
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: List of services
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Service'

  /stacks/{stackId}/services/{serviceName}/logs:
    get:
      summary: Get service logs
      operationId: getServiceLogs
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
        - name: serviceName
          in: path
          required: true
          schema:
            type: string
        - name: tail
          in: query
          schema:
            type: integer
            default: 100
        - name: since
          in: query
          schema:
            type: string
            format: date-time
      responses:
        '200':
          description: Service logs
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/LogEntry'

  # Deployments
  /stacks/{stackId}/deployments:
    get:
      summary: List deployments
      operationId: listDeployments
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: List of deployments
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Deployment'

  /stacks/{stackId}/rollback:
    post:
      summary: Rollback to previous deployment
      operationId: rollbackStack
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                deploymentId:
                  type: string
                  description: Target deployment ID (defaults to previous)
      responses:
        '202':
          description: Rollback started
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Operation'

  # Health
  /stacks/{stackId}/health:
    get:
      summary: Get stack health status
      operationId: getStackHealth
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Health status
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/HealthStatus'

  # Backups
  /stacks/{stackId}/backups:
    get:
      summary: List backups
      operationId: listBackups
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: List of backups
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Backup'

    post:
      summary: Create a backup
      operationId: createBackup
      parameters:
        - name: stackId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateBackupRequest'
      responses:
        '202':
          description: Backup started
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Backup'

components:
  schemas:
    StackStatus:
      type: string
      enum:
        - DRAFT
        - VALIDATING
        - VALID
        - INVALID
        - DEPLOYING
        - DEPLOYED
        - FAILED
        - STOPPED
        - DEGRADED
        - UPDATING
        - DESTROYING

    Stack:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        version:
          type: string
        variant:
          type: string
        status:
          $ref: '#/components/schemas/StackStatus'
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    Service:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        image:
          type: string
        status:
          type: string
        healthStatus:
          type: string
        resourceTier:
          type: string

    Operation:
      type: object
      properties:
        id:
          type: string
        type:
          type: string
        status:
          type: string
        startedAt:
          type: string
          format: date-time
        completedAt:
          type: string
          format: date-time

    ValidationResult:
      type: object
      properties:
        valid:
          type: boolean
        errors:
          type: array
          items:
            $ref: '#/components/schemas/ValidationError'
        warnings:
          type: array
          items:
            type: string

    ValidationError:
      type: object
      properties:
        code:
          type: string
        message:
          type: string
        field:
          type: string
        hint:
          type: string
```

---

## 5. Code Generation Templates

### 5.1 Template Engine

```go
package codegen

import (
    "text/template"
)

// Generator generates IaC code from StackKit configurations
type Generator struct {
    templates *template.Template
}

// NewGenerator creates a new code generator
func NewGenerator() (*Generator, error) {
    templates, err := template.ParseGlob("templates/*.tmpl")
    if err != nil {
        return nil, err
    }
    
    return &Generator{templates: templates}, nil
}

// GenerateStack generates all code for a stack
func (g *Generator) GenerateStack(ctx context.Context, stack *Stack) (*GeneratedFiles, error) {
    files := &GeneratedFiles{}
    
    // Generate main.tf
    mainTf, err := g.generateMain(stack)
    if err != nil {
        return nil, err
    }
    files.Add("main.tf", mainTf)
    
    // Generate variables.tf
    varsTf, err := g.generateVariables(stack)
    if err != nil {
        return nil, err
    }
    files.Add("variables.tf", varsTf)
    
    // Generate docker-compose.yml (for reference)
    compose, err := g.generateCompose(stack)
    if err != nil {
        return nil, err
    }
    files.Add("docker-compose.yml", compose)
    
    return files, nil
}
```

### 5.2 OpenTofu Main Template

```hcl
# templates/main.tf.tmpl

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# Networks
{{range .Networks}}
resource "docker_network" "{{.Name}}" {
  name     = "{{.Name}}"
  driver   = "{{.Driver}}"
  internal = {{.Internal}}
  
  ipam_config {
    subnet  = "{{.Subnet}}"
    gateway = "{{.Gateway}}"
  }
  
  labels {
    label = "managed-by"
    value = "stackkits"
  }
}
{{end}}

# Volumes
{{range .Volumes}}
resource "docker_volume" "{{.Name}}" {
  name = "{{.Name}}"
  
  labels {
    label = "managed-by"
    value = "stackkits"
  }
}
{{end}}

# Services
{{range .Services}}
resource "docker_container" "{{.Name}}" {
  name  = "{{.Name}}"
  image = docker_image.{{.Name}}.image_id
  
  restart = "{{.RestartPolicy}}"
  
  {{if .Ports}}
  {{range .Ports}}
  ports {
    internal = {{.ContainerPort}}
    external = {{.HostPort}}
    protocol = "{{.Protocol}}"
  }
  {{end}}
  {{end}}
  
  {{if .EnvVars}}
  env = [
    {{range .EnvVars}}
    "{{.Name}}={{.Value}}",
    {{end}}
  ]
  {{end}}
  
  {{if .Mounts}}
  {{range .Mounts}}
  mounts {
    source    = {{if eq .Type "volume"}}docker_volume.{{.Source}}.name{{else}}"{{.Source}}"{{end}}
    target    = "{{.Target}}"
    type      = "{{.Type}}"
    read_only = {{.ReadOnly}}
  }
  {{end}}
  {{end}}
  
  {{if .Networks}}
  networks_advanced {
    {{range .Networks}}
    name = docker_network.{{.}}.name
    {{end}}
  }
  {{end}}
  
  {{if .HealthCheck}}
  healthcheck {
    test     = {{.HealthCheck.Test | toJson}}
    interval = "{{.HealthCheck.Interval}}"
    timeout  = "{{.HealthCheck.Timeout}}"
    retries  = {{.HealthCheck.Retries}}
  }
  {{end}}
  
  {{if .ResourceConstraints}}
  memory = {{.ResourceConstraints.Memory}}
  cpu_set = "{{.ResourceConstraints.CPU}}"
  {{end}}
  
  labels {
    label = "managed-by"
    value = "stackkits"
  }
  labels {
    label = "stackkit.version"
    value = "{{$.Version}}"
  }
  
  {{if .DependsOn}}
  depends_on = [
    {{range .DependsOn}}
    docker_container.{{.}},
    {{end}}
  ]
  {{end}}
}

resource "docker_image" "{{.Name}}" {
  name         = "{{.Image}}:{{.ImageTag}}"
  keep_locally = true
}
{{end}}
```

---

## 6. Workflow Automation

### 6.1 GitHub Actions Workflow

```yaml
# .github/workflows/stackkit-deploy.yml
name: StackKit Deploy

on:
  push:
    branches: [main]
    paths:
      - 'stackkits/**'
      - 'stacks/**'

env:
  TOFU_VERSION: '1.6.0'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      
      - name: Install StackKit CLI
        run: go install ./cmd/stackkit
      
      - name: Validate all stacks
        run: stackkit validate ./stacks/*

  plan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: ${{ env.TOFU_VERSION }}
      
      - name: Generate plan
        run: |
          stackkit prepare
          tofu init
          tofu plan -out=plan.tfplan
      
      - name: Upload plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: plan.tfplan

  apply:
    needs: plan
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Download plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan
      
      - name: Apply changes
        run: |
          tofu init
          tofu apply plan.tfplan
```

---

## 7. Error Handling

### 7.1 Error Types

```go
package errors

import "fmt"

// ValidationError represents a validation failure
type ValidationError struct {
    Code    string
    Field   string
    Message string
    Hint    string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("[%s] %s: %s", e.Code, e.Field, e.Message)
}

// OperationError represents an operation failure
type OperationError struct {
    Operation string
    Phase     string
    Cause     error
    Rollback  bool
}

func (e *OperationError) Error() string {
    return fmt.Sprintf("operation %s failed in phase %s: %v", e.Operation, e.Phase, e.Cause)
}

// PlatformError represents a platform-specific error
type PlatformError struct {
    Platform string
    Resource string
    Action   string
    Cause    error
}

func (e *PlatformError) Error() string {
    return fmt.Sprintf("[%s] %s %s failed: %v", e.Platform, e.Action, e.Resource, e.Cause)
}
```

---

## References

- **Layer 2 Extension:** See platform-specific automation in [Docker Automation](../layer-2-platform/docker/AUTOMATION.md)
- **Layer 3 Usage:** See StackKit-specific automation documents
- **Prisma Documentation:** https://www.prisma.io/docs
- **OpenTofu Documentation:** https://opentofu.org/docs

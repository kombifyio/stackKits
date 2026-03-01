// Package cue provides CUE schema validation for StackKits.
package cue

import (
	"fmt"
	"os"
	"path/filepath"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/errors"
	"cuelang.org/go/cue/load"
	"github.com/kombihq/stackkits/pkg/models"
)

// Validator handles CUE schema validation
type Validator struct {
	ctx       *cue.Context
	baseDir   string
	schemaDir string
}

// NewValidator creates a new CUE validator
func NewValidator(baseDir string) *Validator {
	return &Validator{
		ctx:       cuecontext.New(),
		baseDir:   baseDir,
		schemaDir: filepath.Join(baseDir, "base"),
	}
}

// ValidateStackKit validates a StackKit against CUE schemas
func (v *Validator) ValidateStackKit(stackkitDir string) (*models.ValidationResult, error) {
	result := &models.ValidationResult{Valid: true}

	// Load CUE files from the stackkit directory
	cfg := &load.Config{
		Dir: stackkitDir,
	}

	instances := load.Instances([]string{"."}, cfg)
	if len(instances) == 0 {
		return nil, fmt.Errorf("no CUE files found in %s", stackkitDir)
	}

	inst := instances[0]
	if inst.Err != nil {
		result.Valid = false
		result.Errors = append(result.Errors, models.ValidationError{
			Path:    stackkitDir,
			Message: fmt.Sprintf("failed to load CUE instance: %v", inst.Err),
			Code:    "LOAD_ERROR",
		})
		return result, nil
	}

	// Build the value
	value := v.ctx.BuildInstance(inst)
	if err := value.Err(); err != nil {
		result.Valid = false
		for _, e := range errors.Errors(err) {
			result.Errors = append(result.Errors, models.ValidationError{
				Path:    fmt.Sprintf("%v", errors.Positions(e)),
				Message: e.Error(),
				Code:    "BUILD_ERROR",
			})
		}
		return result, nil
	}

	// Validate the value
	if err := value.Validate(cue.Concrete(true)); err != nil {
		result.Valid = false
		for _, e := range errors.Errors(err) {
			result.Errors = append(result.Errors, models.ValidationError{
				Path:    fmt.Sprintf("%v", errors.Positions(e)),
				Message: e.Error(),
				Code:    "VALIDATION_ERROR",
			})
		}
	}

	return result, nil
}

// ValidateSpec validates a stack-spec against CUE schema
func (v *Validator) ValidateSpec(spec *models.StackSpec) (*models.ValidationResult, error) {
	result := &models.ValidationResult{Valid: true}

	// Basic validation rules
	if spec.Name == "" {
		result.Valid = false
		result.Errors = append(result.Errors, models.ValidationError{
			Path:    "name",
			Message: "name is required",
			Code:    "REQUIRED_FIELD",
		})
	}

	if spec.StackKit == "" {
		result.Valid = false
		result.Errors = append(result.Errors, models.ValidationError{
			Path:    "stackkit",
			Message: "stackkit is required",
			Code:    "REQUIRED_FIELD",
		})
	}

	// Validate network mode
	validModes := map[string]bool{"local": true, "public": true, "hybrid": true}
	if spec.Network.Mode != "" && !validModes[spec.Network.Mode] {
		result.Valid = false
		result.Errors = append(result.Errors, models.ValidationError{
			Path:    "network.mode",
			Message: fmt.Sprintf("invalid network mode '%s', must be one of: local, public, hybrid", spec.Network.Mode),
			Code:    "INVALID_VALUE",
		})
	}

	// Validate context
	validContexts := map[string]bool{"local": true, "cloud": true, "pi": true}
	if spec.Context != "" && !validContexts[spec.Context] {
		result.Valid = false
		result.Errors = append(result.Errors, models.ValidationError{
			Path:    "context",
			Message: fmt.Sprintf("invalid context '%s', must be one of: local, cloud, pi", spec.Context),
			Code:    "INVALID_VALUE",
		})
	}

	// Validate compute tier
	validTiers := map[string]bool{"low": true, "standard": true, "high": true}
	if spec.Compute.Tier != "" && !validTiers[spec.Compute.Tier] {
		result.Valid = false
		result.Errors = append(result.Errors, models.ValidationError{
			Path:    "compute.tier",
			Message: fmt.Sprintf("invalid compute tier '%s', must be one of: low, standard, high", spec.Compute.Tier),
			Code:    "INVALID_VALUE",
		})
	}

	// Validate nodes if present
	for i, node := range spec.Nodes {
		if node.Name == "" {
			result.Valid = false
			result.Errors = append(result.Errors, models.ValidationError{
				Path:    fmt.Sprintf("nodes[%d].name", i),
				Message: "node name is required",
				Code:    "REQUIRED_FIELD",
			})
		}
		if node.IP == "" {
			result.Valid = false
			result.Errors = append(result.Errors, models.ValidationError{
				Path:    fmt.Sprintf("nodes[%d].ip", i),
				Message: "node IP is required",
				Code:    "REQUIRED_FIELD",
			})
		}
	}

	// Check for warnings
	if spec.Domain == "" && spec.Network.Mode == "public" {
		result.Warnings = append(result.Warnings, models.ValidationError{
			Path:    "domain",
			Message: "domain is recommended for public network mode",
			Code:    "RECOMMENDED_FIELD",
		})
	}

	if spec.Email == "" && spec.Network.Mode == "public" {
		result.Warnings = append(result.Warnings, models.ValidationError{
			Path:    "email",
			Message: "email is recommended for Let's Encrypt certificates",
			Code:    "RECOMMENDED_FIELD",
		})
	}

	return result, nil
}

// ValidateCUEFile validates a single CUE file
func (v *Validator) ValidateCUEFile(path string) (*models.ValidationResult, error) {
	result := &models.ValidationResult{Valid: true}

	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read CUE file: %w", err)
	}

	value := v.ctx.CompileBytes(data)
	if err := value.Err(); err != nil {
		result.Valid = false
		for _, e := range errors.Errors(err) {
			result.Errors = append(result.Errors, models.ValidationError{
				Path:    path,
				Message: e.Error(),
				Code:    "COMPILE_ERROR",
			})
		}
		return result, nil
	}

	if err := value.Validate(); err != nil {
		result.Valid = false
		for _, e := range errors.Errors(err) {
			result.Errors = append(result.Errors, models.ValidationError{
				Path:    path,
				Message: e.Error(),
				Code:    "VALIDATION_ERROR",
			})
		}
	}

	return result, nil
}

// GetSchemaDir returns the CUE schema directory
func (v *Validator) GetSchemaDir() string {
	return v.schemaDir
}

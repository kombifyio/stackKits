// Package cue provides CUE schema validation and Terraform bridge for StackKits.
package cue

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

// TerraformBridge generates terraform.tfvars.json from CUE specifications
type TerraformBridge struct {
	ctx         *cue.Context
	stackkitDir string
}

// TFVars represents the structure of terraform.tfvars.json
type TFVars struct {
	Domain               string `json:"domain,omitempty"`
	ACMEEmail            string `json:"acme_email,omitempty"`
	AccessMode           string `json:"access_mode"`
	EnableHTTPS          bool   `json:"enable_https"`
	EnableLetsEncrypt    bool   `json:"enable_letsencrypt"`
	Variant              string `json:"variant"`
	ComputeTier          string `json:"compute_tier"`
	BindAddress          string `json:"bind_address"`
	AdvertiseHost        string `json:"advertise_host,omitempty"`
	TraefikDashboardPort int    `json:"traefik_dashboard_port,omitempty"`
	DozzlePort           int    `json:"dozzle_port,omitempty"`
	DokployPort          int    `json:"dokploy_port,omitempty"`
	UptimeKumaPort       int    `json:"uptime_kuma_port,omitempty"`
	BeszelPort           int    `json:"beszel_port,omitempty"`
	DockgePort           int    `json:"dockge_port,omitempty"`
}

// NewTerraformBridge creates a new Terraform bridge for CUE-based generation
func NewTerraformBridge(stackkitDir string) *TerraformBridge {
	return &TerraformBridge{
		ctx:         cuecontext.New(),
		stackkitDir: stackkitDir,
	}
}

// GenerateTFVars reads CUE stackfile and generates terraform.tfvars.json
func (b *TerraformBridge) GenerateTFVars(outputDir string) error {
	// Load CUE instance
	cfg := &load.Config{
		Dir: b.stackkitDir,
	}

	instances := load.Instances([]string{"."}, cfg)
	if len(instances) == 0 {
		return fmt.Errorf("no CUE files found in %s", b.stackkitDir)
	}

	inst := instances[0]
	if inst.Err != nil {
		return fmt.Errorf("failed to load CUE instance: %w", inst.Err)
	}

	value := b.ctx.BuildInstance(inst)
	if err := value.Err(); err != nil {
		return fmt.Errorf("failed to build CUE value: %w", err)
	}

	// Extract configuration from CUE value
	tfvars, err := b.extractTFVars(value)
	if err != nil {
		return fmt.Errorf("failed to extract terraform vars: %w", err)
	}

	// Write terraform.tfvars.json
	return b.writeTFVars(tfvars, outputDir)
}

// extractTFVars extracts terraform variables from CUE value
func (b *TerraformBridge) extractTFVars(value cue.Value) (*TFVars, error) {
	tfvars := &TFVars{
		AccessMode:  "ports",
		Variant:     "default",
		ComputeTier: "standard",
		BindAddress: "0.0.0.0",
	}

	// Try to extract network configuration
	if network := value.LookupPath(cue.ParsePath("network")); network.Exists() {
		if domain := network.LookupPath(cue.ParsePath("domain")); domain.Exists() {
			if d, err := domain.String(); err == nil && d != "" {
				tfvars.Domain = d
				tfvars.AccessMode = "proxy"
				tfvars.EnableHTTPS = true
			}
		}
		if acmeEmail := network.LookupPath(cue.ParsePath("acmeEmail")); acmeEmail.Exists() {
			if e, err := acmeEmail.String(); err == nil {
				tfvars.ACMEEmail = e
				if tfvars.Domain != "" {
					tfvars.EnableLetsEncrypt = true
				}
			}
		}
	}

	// Try to extract variant
	if variant := value.LookupPath(cue.ParsePath("variant")); variant.Exists() {
		if v, err := variant.String(); err == nil {
			tfvars.Variant = v
		}
	}

	// Try to extract compute tier
	if computeTier := value.LookupPath(cue.ParsePath("computeTier")); computeTier.Exists() {
		if ct, err := computeTier.String(); err == nil {
			tfvars.ComputeTier = ct
		}
	}

	// Try to extract from a default stack definition
	if stack := value.LookupPath(cue.ParsePath("stack")); stack.Exists() {
		b.extractFromStack(stack, tfvars)
	}

	// Try to extract from test configurations
	if testStack := value.LookupPath(cue.ParsePath("testStack")); testStack.Exists() {
		b.extractFromStack(testStack, tfvars)
	}

	return tfvars, nil
}

// extractFromStack extracts configuration from a stack definition
func (b *TerraformBridge) extractFromStack(stack cue.Value, tfvars *TFVars) {
	if variant := stack.LookupPath(cue.ParsePath("variant")); variant.Exists() {
		if v, err := variant.String(); err == nil {
			tfvars.Variant = v
		}
	}

	if computeTier := stack.LookupPath(cue.ParsePath("computeTier")); computeTier.Exists() {
		if ct, err := computeTier.String(); err == nil {
			tfvars.ComputeTier = ct
		}
	}

	if network := stack.LookupPath(cue.ParsePath("network")); network.Exists() {
		if domain := network.LookupPath(cue.ParsePath("domain")); domain.Exists() {
			if d, err := domain.String(); err == nil && d != "" {
				tfvars.Domain = d
				tfvars.AccessMode = "proxy"
				tfvars.EnableHTTPS = true
			}
		}
		if acmeEmail := network.LookupPath(cue.ParsePath("acmeEmail")); acmeEmail.Exists() {
			if e, err := acmeEmail.String(); err == nil && e != "" {
				tfvars.ACMEEmail = e
				if tfvars.Domain != "" {
					tfvars.EnableLetsEncrypt = true
				}
			}
		}
	}
}

// writeTFVars writes terraform.tfvars.json to the output directory
func (b *TerraformBridge) writeTFVars(tfvars *TFVars, outputDir string) error {
	// Ensure output directory exists
	if err := os.MkdirAll(outputDir, 0750); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	outputPath := filepath.Join(outputDir, "terraform.tfvars.json")

	data, err := json.MarshalIndent(tfvars, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal tfvars: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0600); err != nil {
		return fmt.Errorf("failed to write terraform.tfvars.json: %w", err)
	}

	return nil
}

// ValidateBeforeGeneration validates CUE values before Terraform generation
func (b *TerraformBridge) ValidateBeforeGeneration() error {
	validator := NewValidator(b.stackkitDir)
	result, err := validator.ValidateStackKit(b.stackkitDir)
	if err != nil {
		return fmt.Errorf("validation error: %w", err)
	}

	if !result.Valid {
		errMsgs := ""
		for _, e := range result.Errors {
			errMsgs += fmt.Sprintf("\n  - %s: %s", e.Path, e.Message)
		}
		return fmt.Errorf("CUE validation failed:%s", errMsgs)
	}

	return nil
}

// GenerateWithValidation validates CUE and then generates tfvars
func (b *TerraformBridge) GenerateWithValidation(outputDir string) error {
	// Step 1: Validate CUE values
	if err := b.ValidateBeforeGeneration(); err != nil {
		return err
	}

	// Step 2: Generate terraform.tfvars.json
	return b.GenerateTFVars(outputDir)
}

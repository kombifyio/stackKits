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
	"github.com/kombihq/stackkits/pkg/models"
)

// TerraformBridge generates terraform.tfvars.json from CUE specifications
type TerraformBridge struct {
	ctx         *cue.Context
	stackkitDir string
}

// TFVars represents the complete structure of terraform.tfvars.json,
// matching all variables declared in base-kit/templates/simple/main.tf.
type TFVars struct {
	// Domain for Traefik routing (e.g. "stack.local")
	Domain string `json:"domain,omitempty"`

	// Docker network name
	NetworkName string `json:"network_name,omitempty"`

	// Docker network subnet (e.g. "172.20.0.0/16")
	NetworkSubnet string `json:"network_subnet,omitempty"`

	// Service enable flags
	EnableTraefik     bool `json:"enable_traefik"`
	EnableTinyauth    bool `json:"enable_tinyauth"`
	EnablePocketID    bool `json:"enable_pocketid"`
	EnableDokploy     bool `json:"enable_dokploy"`
	EnableDokployApps bool `json:"enable_dokploy_apps"`
	EnableDashboard   bool `json:"enable_dashboard"`

	// TinyAuth configuration
	TinyauthUsers  string `json:"tinyauth_users,omitempty"`
	TinyauthAppURL string `json:"tinyauth_app_url,omitempty"`

	// Branding
	BrandColor     string `json:"brand_color,omitempty"`
	DashboardTitle string `json:"dashboard_title,omitempty"`

	// Docker host (for remote daemon)
	DockerHost string `json:"docker_host,omitempty"`
}

// NewTerraformBridge creates a new Terraform bridge for CUE-based generation
func NewTerraformBridge(stackkitDir string) *TerraformBridge {
	return &TerraformBridge{
		ctx:         cuecontext.New(),
		stackkitDir: stackkitDir,
	}
}

// GenerateTFVarsFromSpec generates terraform.tfvars.json from a StackSpec.
// This is the canonical generation path used by the CLI.
func (b *TerraformBridge) GenerateTFVarsFromSpec(spec *models.StackSpec, outputDir string) error {
	tfvars := b.specToTFVars(spec)
	return b.writeTFVars(tfvars, outputDir)
}

// specToTFVars converts a StackSpec into TFVars aligned with main.tf variables.
func (b *TerraformBridge) specToTFVars(spec *models.StackSpec) *TFVars {
	tfvars := newDefaultTFVars()

	if spec.Domain != "" {
		tfvars.Domain = spec.Domain
	}

	if spec.Network.Subnet != "" {
		tfvars.NetworkSubnet = spec.Network.Subnet
	}

	// Per-service enable overrides from spec.Services
	if spec.Services != nil {
		b.applyServiceEnables(spec.Services, tfvars)
	}

	// Docker host from environment
	if dockerHost := os.Getenv("DOCKER_HOST"); dockerHost != "" {
		tfvars.DockerHost = dockerHost
	}

	return tfvars
}

// applyServiceEnables reads enabled/disabled flags from the spec's services map.
func (b *TerraformBridge) applyServiceEnables(services map[string]any, tfvars *TFVars) {
	enables := map[string]*bool{
		"traefik":   &tfvars.EnableTraefik,
		"tinyauth":  &tfvars.EnableTinyauth,
		"pocketid":  &tfvars.EnablePocketID,
		"dokploy":   &tfvars.EnableDokploy,
		"dashboard": &tfvars.EnableDashboard,
	}
	for svcName, ptr := range enables {
		if svcConfig, ok := services[svcName]; ok {
			if svcMap, ok := svcConfig.(map[string]any); ok {
				if enabled, ok := svcMap["enabled"]; ok {
					if v, ok := enabled.(bool); ok {
						*ptr = v
					}
				}
			}
		}
	}
}

// newDefaultTFVars returns TFVars with defaults matching main.tf variable defaults.
func newDefaultTFVars() *TFVars {
	return &TFVars{
		EnableTraefik:     true,
		EnableTinyauth:    true,
		EnablePocketID:    true,
		EnableDokploy:     true,
		EnableDokployApps: true,
		EnableDashboard:   false,
	}
}

// GenerateTFVars reads CUE stackfile and generates terraform.tfvars.json.
// This is the CUE-only path used when no StackSpec is available.
func (b *TerraformBridge) GenerateTFVars(outputDir string) error {
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

	tfvars, err := b.extractTFVars(value)
	if err != nil {
		return fmt.Errorf("failed to extract terraform vars: %w", err)
	}

	return b.writeTFVars(tfvars, outputDir)
}

// extractTFVars extracts terraform variables from CUE value.
func (b *TerraformBridge) extractTFVars(value cue.Value) (*TFVars, error) {
	tfvars := newDefaultTFVars()

	if network := value.LookupPath(cue.ParsePath("network")); network.Exists() {
		b.extractNetwork(network, tfvars)
	}

	if stack := value.LookupPath(cue.ParsePath("stack")); stack.Exists() {
		b.extractFromStack(stack, tfvars)
	}

	if testStack := value.LookupPath(cue.ParsePath("testStack")); testStack.Exists() {
		b.extractFromStack(testStack, tfvars)
	}

	return tfvars, nil
}

// extractNetwork extracts domain and subnet from a CUE network value.
func (b *TerraformBridge) extractNetwork(network cue.Value, tfvars *TFVars) {
	if domain := network.LookupPath(cue.ParsePath("domain")); domain.Exists() {
		if d, err := domain.String(); err == nil && d != "" {
			tfvars.Domain = d
		}
	}
	if subnet := network.LookupPath(cue.ParsePath("subnet")); subnet.Exists() {
		if s, err := subnet.String(); err == nil && s != "" {
			tfvars.NetworkSubnet = s
		}
	}
}

// extractFromStack extracts configuration from a stack definition.
func (b *TerraformBridge) extractFromStack(stack cue.Value, tfvars *TFVars) {
	if network := stack.LookupPath(cue.ParsePath("network")); network.Exists() {
		b.extractNetwork(network, tfvars)
	}
}

// writeTFVars writes terraform.tfvars.json to the output directory
func (b *TerraformBridge) writeTFVars(tfvars *TFVars, outputDir string) error {
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
	if err := b.ValidateBeforeGeneration(); err != nil {
		return err
	}
	return b.GenerateTFVars(outputDir)
}

// GenerateFromSpecWithValidation validates CUE schemas then generates tfvars from spec.
func (b *TerraformBridge) GenerateFromSpecWithValidation(spec *models.StackSpec, outputDir string) error {
	if err := b.ValidateBeforeGeneration(); err != nil {
		return err
	}
	return b.GenerateTFVarsFromSpec(spec, outputDir)
}

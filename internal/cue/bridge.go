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
// matching all variables defined in base-homelab/templates/simple/main.tf.
type TFVars struct {
	// Core settings
	Domain            string `json:"domain,omitempty"`
	ACMEEmail         string `json:"acme_email,omitempty"`
	AccessMode        string `json:"access_mode"`
	EnableHTTPS       bool   `json:"enable_https"`
	EnableLetsEncrypt bool   `json:"enable_letsencrypt"`
	Variant           string `json:"variant"`
	ComputeTier       string `json:"compute_tier"`

	// Network settings
	BindAddress   string `json:"bind_address"`
	AdvertiseHost string `json:"advertise_host,omitempty"`

	// Service ports (match main.tf variable defaults)
	TraefikDashboardPort int `json:"traefik_dashboard_port,omitempty"`
	DozzlePort           int `json:"dozzle_port,omitempty"`
	DokployPort          int `json:"dokploy_port,omitempty"`
	UptimeKumaPort       int `json:"uptime_kuma_port,omitempty"`
	BeszelPort           int `json:"beszel_port,omitempty"`
	DockgePort           int `json:"dockge_port,omitempty"`
	PortainerPort        int `json:"portainer_port,omitempty"`
	NetdataPort          int `json:"netdata_port,omitempty"`
	WhoamiPort           int `json:"whoami_port,omitempty"`

	// Minimal variant
	StacksDir string `json:"stacks_dir,omitempty"`

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
// This is the canonical generation path that merges user spec values with
// sensible defaults derived from the CUE schemas.
func (b *TerraformBridge) GenerateTFVarsFromSpec(spec *models.StackSpec, outputDir string) error {
	tfvars := b.specToTFVars(spec)

	return b.writeTFVars(tfvars, outputDir)
}

// specToTFVars converts a StackSpec into TFVars, applying derivation logic
// for access_mode, HTTPS, and Let's Encrypt based on domain/email presence.
func (b *TerraformBridge) specToTFVars(spec *models.StackSpec) *TFVars {
	tfvars := newDefaultTFVars()

	// Domain and ACME email
	if spec.Domain != "" {
		tfvars.Domain = spec.Domain
		tfvars.AccessMode = "proxy"
		tfvars.EnableHTTPS = true
	}
	if spec.Email != "" {
		tfvars.ACMEEmail = spec.Email
		if tfvars.Domain != "" {
			tfvars.EnableLetsEncrypt = true
		}
	}

	// Variant
	if spec.Variant != "" {
		tfvars.Variant = spec.Variant
	}

	// Compute tier
	if spec.Compute.Tier != "" && spec.Compute.Tier != "auto" {
		tfvars.ComputeTier = spec.Compute.Tier
	}

	// Context-driven defaults (applied BEFORE explicit overrides so user can override)
	b.applyContextDefaults(spec.Context, tfvars)

	// Node host as advertise_host (use first node's IP if available)
	if len(spec.Nodes) > 0 && spec.Nodes[0].IP != "" {
		tfvars.AdvertiseHost = spec.Nodes[0].IP
	}

	// Docker host from environment
	if dockerHost := os.Getenv("DOCKER_HOST"); dockerHost != "" {
		tfvars.DockerHost = dockerHost
	}

	// Service port overrides from spec.Services map
	if spec.Services != nil {
		b.extractServicePorts(spec.Services, tfvars)
	}

	return tfvars
}

// applyContextDefaults applies context-driven defaults to tfvars.
// These set sensible baseline values that can still be overridden by explicit spec fields.
// Context mapping mirrors the CUE #ContextDefaults in base/context.cue.
func (b *TerraformBridge) applyContextDefaults(context string, tfvars *TFVars) {
	switch context {
	case "cloud":
		// Cloud: public IP, Let's Encrypt available, proxy mode preferred
		if tfvars.AccessMode == "ports" && tfvars.Domain != "" {
			tfvars.AccessMode = "proxy"
			tfvars.EnableHTTPS = true
		}
	case "pi":
		// Pi: constrained resources, use low tier unless explicitly set
		if tfvars.ComputeTier == "standard" {
			tfvars.ComputeTier = "low"
		}
	case "local", "":
		// Local: defaults are already correct (ports mode, standard tier)
	}
}

// extractServicePorts reads port overrides from the spec's services map.
func (b *TerraformBridge) extractServicePorts(services map[string]any, tfvars *TFVars) {
	portExtractors := map[string]*int{
		"traefik":    &tfvars.TraefikDashboardPort,
		"dozzle":     &tfvars.DozzlePort,
		"dokploy":    &tfvars.DokployPort,
		"uptime-kuma": &tfvars.UptimeKumaPort,
		"beszel":     &tfvars.BeszelPort,
		"dockge":     &tfvars.DockgePort,
		"portainer":  &tfvars.PortainerPort,
		"netdata":    &tfvars.NetdataPort,
		"whoami":     &tfvars.WhoamiPort,
	}

	for svcName, portPtr := range portExtractors {
		if svcConfig, ok := services[svcName]; ok {
			if svcMap, ok := svcConfig.(map[string]any); ok {
				if port, ok := svcMap["port"]; ok {
					switch v := port.(type) {
					case int:
						*portPtr = v
					case float64:
						*portPtr = int(v)
					}
				}
			}
		}
	}
}

// newDefaultTFVars returns TFVars with sensible defaults matching main.tf variable defaults.
func newDefaultTFVars() *TFVars {
	return &TFVars{
		AccessMode:  "ports",
		Variant:     "default",
		ComputeTier: "standard",
		BindAddress: "0.0.0.0",
	}
}

// GenerateTFVars reads CUE stackfile and generates terraform.tfvars.json.
// This is the CUE-only path used by API handlers when no StackSpec is available.
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
	tfvars := newDefaultTFVars()

	// Try to extract network configuration
	if network := value.LookupPath(cue.ParsePath("network")); network.Exists() {
		b.extractNetwork(network, tfvars)
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

// extractNetwork extracts network-related fields from a CUE value.
func (b *TerraformBridge) extractNetwork(network cue.Value, tfvars *TFVars) {
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
		b.extractNetwork(network, tfvars)
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

// GenerateFromSpecWithValidation validates CUE schemas then generates tfvars from spec.
// This is the recommended path for CLI usage.
func (b *TerraformBridge) GenerateFromSpecWithValidation(spec *models.StackSpec, outputDir string) error {
	if err := b.ValidateBeforeGeneration(); err != nil {
		return err
	}

	return b.GenerateTFVarsFromSpec(spec, outputDir)
}

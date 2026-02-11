package api

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/kombihq/stackkits/api/openapi"
	"github.com/kombihq/stackkits/internal/config"
	cuepkg "github.com/kombihq/stackkits/internal/cue"
	"github.com/kombihq/stackkits/pkg/models"
)

// ── Health ────────────────────────────────────────────────────────

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeSuccess(w, r, http.StatusOK, map[string]interface{}{
		"status":  "healthy",
		"service": "stackkits",
		"version": s.config.Version,
	})
}

// ── Capabilities ──────────────────────────────────────────────────

func (s *Server) handleCapabilities(w http.ResponseWriter, r *http.Request) {
	writeSuccess(w, r, http.StatusOK, map[string]interface{}{
		"service":     "kombify-stackkits",
		"version":     s.config.Version,
		"description": "kombify StackKits — pre-packaged homelab infrastructure templates with CUE validation and OpenTofu generation",
		"openapi":     "/api/v1/openapi.yaml",
		"capabilities": []map[string]interface{}{
			// Catalog
			{"name": "stackkit.list", "description": "List all available StackKits", "method": "GET", "path": "/api/v1/stackkits"},
			{"name": "stackkit.get", "description": "Get StackKit details by name", "method": "GET", "path": "/api/v1/stackkits/{name}"},
			{"name": "stackkit.schema", "description": "Get raw CUE schema for a StackKit", "method": "GET", "path": "/api/v1/stackkits/{name}/schema"},
			{"name": "stackkit.defaults", "description": "Get default StackSpec values for a StackKit", "method": "GET", "path": "/api/v1/stackkits/{name}/defaults"},
			{"name": "stackkit.variants", "description": "List available variants for a StackKit", "method": "GET", "path": "/api/v1/stackkits/{name}/variants"},
			// Validation
			{"name": "validate.spec", "description": "Validate a stack-spec against its StackKit schema", "method": "POST", "path": "/api/v1/validate"},
			{"name": "validate.partial", "description": "Validate partial spec fields (wizard step)", "method": "POST", "path": "/api/v1/validate/partial"},
			// Generation
			{"name": "generate.tfvars", "description": "Generate terraform.tfvars from a validated spec", "method": "POST", "path": "/api/v1/generate/tfvars"},
			{"name": "generate.preview", "description": "Preview the generated infrastructure without writing files", "method": "POST", "path": "/api/v1/generate/preview"},
			// Discovery
			{"name": "health", "description": "Service health check", "method": "GET", "path": "/api/v1/health"},
			{"name": "capabilities", "description": "List all API capabilities", "method": "GET", "path": "/api/v1/capabilities"},
			{"name": "openapi", "description": "OpenAPI 3.1 specification", "method": "GET", "path": "/api/v1/openapi.yaml"},
		},
	})
}

// ── OpenAPI Spec ──────────────────────────────────────────────────

func (s *Server) handleOpenAPISpec(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/yaml; charset=utf-8")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	w.WriteHeader(http.StatusOK)
	w.Write(openapi.Spec)
}

// ── Catalog: List StackKits ───────────────────────────────────────

// stackKitDirs are the well-known directories where StackKits live.
var stackKitDirs = []string{
	"base-homelab",
	"dev-homelab",
	"modern-homelab",
	"ha-homelab",
}

type stackKitSummary struct {
	Name        string   `json:"name"`
	DisplayName string   `json:"displayName"`
	Description string   `json:"description"`
	Version     string   `json:"version"`
	Tags        []string `json:"tags,omitempty"`
}

func (s *Server) handleListStackKits(w http.ResponseWriter, r *http.Request) {
	loader := config.NewLoader(s.config.BaseDir)
	var kits []stackKitSummary

	// Scan well-known directories
	for _, name := range stackKitDirs {
		dir, err := loader.FindStackKitDir(name)
		if err != nil {
			continue
		}
		sk, err := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))
		if err != nil {
			continue
		}
		kits = append(kits, stackKitSummary{
			Name:        sk.Metadata.Name,
			DisplayName: sk.Metadata.DisplayName,
			Description: sk.Metadata.Description,
			Version:     sk.Metadata.Version,
			Tags:        sk.Metadata.Tags,
		})
	}

	// Also scan any directory containing stackkit.yaml
	entries, err := os.ReadDir(s.config.BaseDir)
	if err == nil {
		seen := make(map[string]bool, len(kits))
		for _, k := range kits {
			seen[k.Name] = true
		}
		for _, entry := range entries {
			if !entry.IsDir() {
				continue
			}
			yamlPath := filepath.Join(s.config.BaseDir, entry.Name(), "stackkit.yaml")
			if _, err := os.Stat(yamlPath); err != nil {
				continue
			}
			sk, err := loader.LoadStackKit(yamlPath)
			if err != nil || seen[sk.Metadata.Name] {
				continue
			}
			kits = append(kits, stackKitSummary{
				Name:        sk.Metadata.Name,
				DisplayName: sk.Metadata.DisplayName,
				Description: sk.Metadata.Description,
				Version:     sk.Metadata.Version,
				Tags:        sk.Metadata.Tags,
			})
		}
	}

	sort.Slice(kits, func(i, j int) bool { return kits[i].Name < kits[j].Name })
	writeSuccess(w, r, http.StatusOK, kits)
}

// ── Catalog: Get StackKit ─────────────────────────────────────────

func (s *Server) handleGetStackKit(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if name == "" {
		writeError(w, r, http.StatusBadRequest, "stackkit name is required")
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "stackkit not found: "+name)
		return
	}

	sk, err := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to load stackkit")
		return
	}

	writeSuccess(w, r, http.StatusOK, sk)
}

// ── Catalog: Get Schema ───────────────────────────────────────────

func (s *Server) handleGetStackKitSchema(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if name == "" {
		writeError(w, r, http.StatusBadRequest, "stackkit name is required")
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "stackkit not found: "+name)
		return
	}

	// Look for the main CUE schema file
	schemaPath := ""
	candidates := []string{"schema.cue", "stackkit.cue", name + ".cue"}
	for _, c := range candidates {
		p := filepath.Join(dir, c)
		if _, err := os.Stat(p); err == nil {
			schemaPath = p
			break
		}
	}

	if schemaPath == "" {
		// Fall back: find any .cue file
		entries, err := os.ReadDir(dir)
		if err == nil {
			for _, e := range entries {
				if !e.IsDir() && strings.HasSuffix(e.Name(), ".cue") {
					schemaPath = filepath.Join(dir, e.Name())
					break
				}
			}
		}
	}

	if schemaPath == "" {
		writeError(w, r, http.StatusNotFound, "no CUE schema found for stackkit: "+name)
		return
	}

	data, err := os.ReadFile(schemaPath)
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to read schema")
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

// ── Catalog: Defaults ─────────────────────────────────────────────

func (s *Server) handleGetStackKitDefaults(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if name == "" {
		writeError(w, r, http.StatusBadRequest, "stackkit name is required")
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "stackkit not found: "+name)
		return
	}

	sk, err := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to load stackkit")
		return
	}

	// Build a default spec from the StackKit's own defaults
	defaultSpec := models.StackSpec{
		Name:     "",
		StackKit: sk.Metadata.Name,
		Variant:  sk.DefaultVariant,
		Mode:     "simple",
		Network:  models.NetworkSpec{Mode: "local", Subnet: "172.20.0.0/16"},
		Compute:  models.ComputeSpec{Tier: "standard"},
		SSH:      models.SSHSpec{Port: 22, User: "root"},
	}

	if defaultSpec.Variant == "" && len(sk.Variants) > 0 {
		// Pick the variant marked as default, or the first one
		for k, v := range sk.Variants {
			if v.Default {
				defaultSpec.Variant = k
				break
			}
		}
		if defaultSpec.Variant == "" {
			for k := range sk.Variants {
				defaultSpec.Variant = k
				break
			}
		}
	}

	writeSuccess(w, r, http.StatusOK, defaultSpec)
}

// ── Catalog: Variants ─────────────────────────────────────────────

func (s *Server) handleGetStackKitVariants(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if name == "" {
		writeError(w, r, http.StatusBadRequest, "stackkit name is required")
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "stackkit not found: "+name)
		return
	}

	sk, err := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to load stackkit")
		return
	}

	type variantInfo struct {
		Name        string   `json:"name"`
		DisplayName string   `json:"displayName"`
		Description string   `json:"description"`
		Services    []string `json:"services"`
		Default     bool     `json:"default,omitempty"`
	}

	variants := make([]variantInfo, 0, len(sk.Variants))
	for k, v := range sk.Variants {
		variants = append(variants, variantInfo{
			Name:        k,
			DisplayName: v.DisplayName,
			Description: v.Description,
			Services:    v.Services,
			Default:     v.Default,
		})
	}
	sort.Slice(variants, func(i, j int) bool { return variants[i].Name < variants[j].Name })

	writeSuccess(w, r, http.StatusOK, variants)
}

// ── Validation ────────────────────────────────────────────────────

func (s *Server) handleValidateSpec(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "failed to read request body")
		return
	}
	defer r.Body.Close()

	var spec models.StackSpec
	if err := json.Unmarshal(body, &spec); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if spec.StackKit == "" {
		writeError(w, r, http.StatusBadRequest, "stackkit field is required")
		return
	}

	validator := cuepkg.NewValidator(s.config.BaseDir)
	result, err := validator.ValidateSpec(&spec)
	if err != nil {
		writeError(w, r, http.StatusUnprocessableEntity, "validation error: "+err.Error())
		return
	}

	writeSuccess(w, r, http.StatusOK, result)
}

func (s *Server) handleValidatePartial(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "failed to read request body")
		return
	}
	defer r.Body.Close()

	// Partial validation accepts a JSON object with a subset of spec fields
	// and validates only those fields without requiring a full spec
	var partial map[string]interface{}
	if err := json.Unmarshal(body, &partial); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	var errors []models.ValidationError
	var warnings []models.ValidationError

	// Validate known fields
	if name, ok := partial["stackkit"].(string); ok && name != "" {
		loader := config.NewLoader(s.config.BaseDir)
		if _, err := loader.FindStackKitDir(name); err != nil {
			errors = append(errors, models.ValidationError{
				Path:    "stackkit",
				Message: "stackkit not found: " + name,
				Code:    "STACKKIT_NOT_FOUND",
			})
		}
	}

	if variant, ok := partial["variant"].(string); ok && variant != "" {
		if kitName, ok := partial["stackkit"].(string); ok && kitName != "" {
			loader := config.NewLoader(s.config.BaseDir)
			dir, err := loader.FindStackKitDir(kitName)
			if err == nil {
				sk, err := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))
				if err == nil {
					if _, exists := sk.Variants[variant]; !exists {
						available := make([]string, 0, len(sk.Variants))
						for k := range sk.Variants {
							available = append(available, k)
						}
						errors = append(errors, models.ValidationError{
							Path:    "variant",
							Message: "unknown variant '" + variant + "', available: " + strings.Join(available, ", "),
							Code:    "UNKNOWN_VARIANT",
						})
					}
				}
			}
		}
	}

	if mode, ok := partial["mode"].(string); ok && mode != "" {
		validModes := map[string]bool{"simple": true, "advanced": true}
		if !validModes[mode] {
			errors = append(errors, models.ValidationError{
				Path:    "mode",
				Message: "invalid mode '" + mode + "', expected 'simple' or 'advanced'",
				Code:    "INVALID_MODE",
			})
		}
	}

	if network, ok := partial["network"].(map[string]interface{}); ok {
		if netMode, ok := network["mode"].(string); ok {
			validNetModes := map[string]bool{"local": true, "public": true, "hybrid": true}
			if !validNetModes[netMode] {
				warnings = append(warnings, models.ValidationError{
					Path:    "network.mode",
					Message: "unusual network mode '" + netMode + "', expected local/public/hybrid",
					Code:    "UNUSUAL_NET_MODE",
				})
			}
		}
	}

	result := models.ValidationResult{
		Valid:    len(errors) == 0,
		Errors:   errors,
		Warnings: warnings,
	}

	writeSuccess(w, r, http.StatusOK, result)
}

// ── Generation ────────────────────────────────────────────────────

type generateRequest struct {
	Spec models.StackSpec `json:"spec"`
}

func (s *Server) handleGenerateTFVars(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "failed to read request body")
		return
	}
	defer r.Body.Close()

	var req generateRequest
	if err := json.Unmarshal(body, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if req.Spec.StackKit == "" {
		writeError(w, r, http.StatusBadRequest, "spec.stackkit field is required")
		return
	}

	// Find the stackkit directory
	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(req.Spec.StackKit)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "stackkit not found: "+req.Spec.StackKit)
		return
	}

	// Always generate into a temp directory — never accept a client-supplied path.
	tempDir, err := os.MkdirTemp("", "stackkit-tfvars-*")
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to create temp directory")
		return
	}
	defer os.RemoveAll(tempDir)

	// Use the TerraformBridge to generate tfvars
	bridge := cuepkg.NewTerraformBridge(dir)
	if err := bridge.GenerateWithValidation(tempDir); err != nil {
		writeError(w, r, http.StatusUnprocessableEntity, "generation failed: "+err.Error())
		return
	}

	// Read back the generated file to return it
	tfvarsPath := filepath.Join(tempDir, "terraform.tfvars.json")
	data, err := os.ReadFile(tfvarsPath)
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "generated but failed to read tfvars")
		return
	}

	var tfvars interface{}
	json.Unmarshal(data, &tfvars)

	writeSuccess(w, r, http.StatusOK, map[string]interface{}{
		"tfvars": tfvars,
		"file":   "terraform.tfvars.json",
	})
}

func (s *Server) handleGeneratePreview(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "failed to read request body")
		return
	}
	defer r.Body.Close()

	var req generateRequest
	if err := json.Unmarshal(body, &req); err != nil {
		writeError(w, r, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	if req.Spec.StackKit == "" {
		writeError(w, r, http.StatusBadRequest, "spec.stackkit field is required")
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(req.Spec.StackKit)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "stackkit not found: "+req.Spec.StackKit)
		return
	}

	// Use temp directory for preview
	tempDir, err := os.MkdirTemp("", "stackkit-preview-*")
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to create temp directory")
		return
	}
	defer os.RemoveAll(tempDir)

	bridge := cuepkg.NewTerraformBridge(dir)
	if err := bridge.ValidateBeforeGeneration(); err != nil {
		writeError(w, r, http.StatusUnprocessableEntity, "pre-generation validation failed: "+err.Error())
		return
	}

	if err := bridge.GenerateTFVars(tempDir); err != nil {
		writeError(w, r, http.StatusUnprocessableEntity, "preview generation failed: "+err.Error())
		return
	}

	// Read the preview
	tfvarsPath := filepath.Join(tempDir, "terraform.tfvars.json")
	data, err := os.ReadFile(tfvarsPath)
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "preview generated but read failed")
		return
	}

	var tfvars interface{}
	json.Unmarshal(data, &tfvars)

	// Get stackkit info for context
	sk, _ := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))

	preview := map[string]interface{}{
		"tfvars":  tfvars,
		"preview": true,
	}
	if sk != nil {
		preview["stackkit"] = stackKitSummary{
			Name:        sk.Metadata.Name,
			DisplayName: sk.Metadata.DisplayName,
			Version:     sk.Metadata.Version,
		}
	}

	writeSuccess(w, r, http.StatusOK, preview)
}

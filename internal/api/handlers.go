package api

import (
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/kombihq/stackkits/api/openapi"
	"github.com/kombihq/stackkits/internal/config"
	cuepkg "github.com/kombihq/stackkits/internal/cue"
	skerrors "github.com/kombihq/stackkits/internal/errors"
	"github.com/kombihq/stackkits/pkg/models"
)

// ── Health ────────────────────────────────────────────────────────

// stackKitNamePattern matches the OpenAPI StackKitName pattern: ^[a-z0-9][a-z0-9-]*[a-z0-9]$
var stackKitNamePattern = regexp.MustCompile(`^[a-z0-9][a-z0-9-]*[a-z0-9]$`)

// validateStackKitName checks a name against the OpenAPI StackKitName pattern.
// Returns a structured error if the name is invalid.
func validateStackKitName(name string) *skerrors.StackKitError {
	if name == "" {
		return skerrors.NewValidationError("name_required", "stackkit name is required",
			skerrors.WithSuggestion("Provide a StackKit name in the URL path"),
			skerrors.WithSuggestion("List available StackKits: GET /api/v1/stackkits"),
		)
	}
	if !stackKitNamePattern.MatchString(name) {
		return skerrors.NewValidationError("invalid_name_format",
			"invalid stackkit name: '"+name+"' — must match pattern ^[a-z0-9][a-z0-9-]*[a-z0-9]$",
			skerrors.WithField("name", name),
			skerrors.WithField("pattern", "^[a-z0-9][a-z0-9-]*[a-z0-9]$"),
			skerrors.WithSuggestion("Use lowercase letters, digits, and hyphens only (e.g., base-kit)"),
			skerrors.WithSuggestion("Name must start and end with a letter or digit"),
		)
	}
	return nil
}

// stackKitNotFoundError creates a structured error for missing StackKits.
func stackKitNotFoundError(name string) *skerrors.StackKitError {
	return skerrors.NewValidationError("stackkit_not_found",
		"stackkit not found: "+name,
		skerrors.WithField("name", name),
		skerrors.WithSuggestion("List available StackKits: GET /api/v1/stackkits"),
		skerrors.WithSuggestion("Check the name for typos — names are case-sensitive"),
	)
}

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
	_, _ = w.Write(openapi.Spec)
}

// ── Catalog: List StackKits ───────────────────────────────────────

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
	seen := make(map[string]bool)

	// Auto-discover: scan all directories containing stackkit.yaml
	entries, err := os.ReadDir(s.config.BaseDir)
	if err == nil {
		for _, entry := range entries {
			if !entry.IsDir() {
				continue
			}
			yamlPath := filepath.Join(s.config.BaseDir, entry.Name(), "stackkit.yaml")
			if _, statErr := os.Stat(yamlPath); statErr != nil {
				continue
			}
			sk, err := loader.LoadStackKit(yamlPath)
			if err != nil || seen[sk.Metadata.Name] {
				continue
			}
			seen[sk.Metadata.Name] = true
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

	// Pagination: ?limit=N&offset=M
	total := len(kits)
	limit := total // default: return all
	offset := 0

	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = v
		}
	}
	if o := r.URL.Query().Get("offset"); o != "" {
		if v, err := strconv.Atoi(o); err == nil && v >= 0 {
			offset = v
		}
	}

	// Apply pagination
	if offset > total {
		offset = total
	}
	end := offset + limit
	if end > total {
		end = total
	}
	paged := kits[offset:end]

	writeSuccess(w, r, http.StatusOK, map[string]interface{}{
		"items":  paged,
		"total":  total,
		"limit":  limit,
		"offset": offset,
	})
}

// ── Catalog: Get StackKit ─────────────────────────────────────────

func (s *Server) handleGetStackKit(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if err := validateStackKitName(name); err != nil {
		writeStructuredError(w, r, http.StatusBadRequest, err)
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeStructuredError(w, r, http.StatusNotFound, stackKitNotFoundError(name))
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
	if err := validateStackKitName(name); err != nil {
		writeStructuredError(w, r, http.StatusBadRequest, err)
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeStructuredError(w, r, http.StatusNotFound, stackKitNotFoundError(name))
		return
	}

	// Look for the main CUE schema file
	schemaPath := ""
	candidates := []string{"schema.cue", "stackkit.cue", name + ".cue"}
	for _, c := range candidates {
		p := filepath.Join(dir, c)
		if _, statErr := os.Stat(p); statErr == nil {
			schemaPath = p
			break
		}
	}

	if schemaPath == "" {
		// Fall back: find any .cue file
		entries, readErr := os.ReadDir(dir)
		if readErr == nil {
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
	_, _ = w.Write(data)
}

// ── Catalog: Defaults ─────────────────────────────────────────────

func (s *Server) handleGetStackKitDefaults(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if err := validateStackKitName(name); err != nil {
		writeStructuredError(w, r, http.StatusBadRequest, err)
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeStructuredError(w, r, http.StatusNotFound, stackKitNotFoundError(name))
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
		// Pick the variant marked as default, or the first alphabetically
		for k, v := range sk.Variants {
			if v.Default {
				defaultSpec.Variant = k
				break
			}
		}
		if defaultSpec.Variant == "" {
			// Sort variant names for deterministic selection
			variantNames := make([]string, 0, len(sk.Variants))
			for k := range sk.Variants {
				variantNames = append(variantNames, k)
			}
			sort.Strings(variantNames)
			defaultSpec.Variant = variantNames[0]
		}
	}

	writeSuccess(w, r, http.StatusOK, defaultSpec)
}

// ── Catalog: Variants ─────────────────────────────────────────────

func (s *Server) handleGetStackKitVariants(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	if err := validateStackKitName(name); err != nil {
		writeStructuredError(w, r, http.StatusBadRequest, err)
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(name)
	if err != nil {
		writeStructuredError(w, r, http.StatusNotFound, stackKitNotFoundError(name))
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
	if unmarshalErr := json.Unmarshal(body, &spec); unmarshalErr != nil {
		slog.Warn("JSON parse error in validate request", "error", unmarshalErr)
		writeError(w, r, http.StatusBadRequest, "invalid JSON format")
		return
	}

	if spec.StackKit == "" {
		writeError(w, r, http.StatusBadRequest, "stackkit field is required")
		return
	}

	validator := cuepkg.NewValidator(s.config.BaseDir)
	result, err := validator.ValidateSpec(&spec)
	if err != nil {
		writeStructuredError(w, r, http.StatusUnprocessableEntity, skerrors.NewValidationError(
			"spec_validation_failed", "validation error: "+err.Error(),
			skerrors.WithCause(err),
			skerrors.WithSuggestion("Check your spec against the schema: GET /api/v1/stackkits/"+spec.StackKit+"/schema"),
			skerrors.WithSuggestion("Use partial validation to debug field-by-field: POST /api/v1/validate/partial"),
		))
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
		slog.Warn("JSON parse error in partial validate request", "error", err)
		writeError(w, r, http.StatusBadRequest, "invalid JSON format")
		return
	}

	var errors []models.ValidationError
	var warnings []models.ValidationError

	errors = append(errors, validatePartialStackKit(partial, s.config.BaseDir)...)
	errors = append(errors, validatePartialVariant(partial, s.config.BaseDir)...)
	errors = append(errors, validatePartialMode(partial)...)

	netErrors, netWarnings := validatePartialNetwork(partial)
	errors = append(errors, netErrors...)
	warnings = append(warnings, netWarnings...)

	errors = append(errors, validatePartialName(partial)...)
	errors = append(errors, validatePartialEmail(partial)...)
	errors = append(errors, validatePartialDomain(partial)...)
	errors = append(errors, validatePartialCompute(partial)...)
	errors = append(errors, validatePartialSSH(partial)...)
	errors = append(errors, validatePartialNodes(partial)...)

	result := models.ValidationResult{
		Valid:    len(errors) == 0,
		Errors:   errors,
		Warnings: warnings,
	}

	writeSuccess(w, r, http.StatusOK, result)
}

func validatePartialStackKit(partial map[string]interface{}, baseDir string) []models.ValidationError {
	name, ok := partial["stackkit"].(string)
	if !ok || name == "" {
		return nil
	}
	loader := config.NewLoader(baseDir)
	if _, err := loader.FindStackKitDir(name); err != nil {
		return []models.ValidationError{{
			Path:    "stackkit",
			Message: "stackkit not found: " + name,
			Code:    "STACKKIT_NOT_FOUND",
		}}
	}
	return nil
}

func validatePartialVariant(partial map[string]interface{}, baseDir string) []models.ValidationError {
	variant, ok := partial["variant"].(string)
	if !ok || variant == "" {
		return nil
	}
	kitName, ok := partial["stackkit"].(string)
	if !ok || kitName == "" {
		return nil
	}
	loader := config.NewLoader(baseDir)
	dir, err := loader.FindStackKitDir(kitName)
	if err != nil {
		return nil
	}
	sk, err := loader.LoadStackKit(filepath.Join(dir, "stackkit.yaml"))
	if err != nil {
		return nil
	}
	if _, exists := sk.Variants[variant]; !exists {
		available := make([]string, 0, len(sk.Variants))
		for k := range sk.Variants {
			available = append(available, k)
		}
		return []models.ValidationError{{
			Path:    "variant",
			Message: "unknown variant '" + variant + "', available: " + strings.Join(available, ", "),
			Code:    "UNKNOWN_VARIANT",
		}}
	}
	return nil
}

func validatePartialMode(partial map[string]interface{}) []models.ValidationError {
	mode, ok := partial["mode"].(string)
	if !ok || mode == "" {
		return nil
	}
	validModes := map[string]bool{"simple": true, "advanced": true}
	if !validModes[mode] {
		return []models.ValidationError{{
			Path:    "mode",
			Message: "invalid mode '" + mode + "', expected 'simple' or 'advanced'",
			Code:    "INVALID_MODE",
		}}
	}
	return nil
}

func validatePartialNetwork(partial map[string]interface{}) (errors, warnings []models.ValidationError) {
	network, ok := partial["network"].(map[string]interface{})
	if !ok {
		return nil, nil
	}
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
	if subnet, ok := network["subnet"].(string); ok && subnet != "" {
		// Basic CIDR format check
		if !strings.Contains(subnet, "/") {
			errors = append(errors, models.ValidationError{
				Path:    "network.subnet",
				Message: "subnet must be in CIDR notation (e.g., 172.20.0.0/16)",
				Code:    "INVALID_SUBNET",
			})
		}
	}
	return errors, warnings
}

func validatePartialName(partial map[string]interface{}) []models.ValidationError {
	name, ok := partial["name"].(string)
	if !ok || name == "" {
		return nil
	}
	if !stackKitNamePattern.MatchString(name) {
		return []models.ValidationError{{
			Path:    "name",
			Message: "invalid name '" + name + "' — must match ^[a-z0-9][a-z0-9-]*[a-z0-9]$",
			Code:    "INVALID_NAME",
		}}
	}
	return nil
}

func validatePartialEmail(partial map[string]interface{}) []models.ValidationError {
	email, ok := partial["email"].(string)
	if !ok || email == "" {
		return nil
	}
	if !strings.Contains(email, "@") || !strings.Contains(email, ".") {
		return []models.ValidationError{{
			Path:    "email",
			Message: "invalid email format: '" + email + "'",
			Code:    "INVALID_EMAIL",
		}}
	}
	return nil
}

func validatePartialDomain(partial map[string]interface{}) []models.ValidationError {
	domain, ok := partial["domain"].(string)
	if !ok || domain == "" {
		return nil
	}
	if strings.ContainsAny(domain, " \t") || !strings.Contains(domain, ".") {
		return []models.ValidationError{{
			Path:    "domain",
			Message: "invalid domain format: '" + domain + "'",
			Code:    "INVALID_DOMAIN",
		}}
	}
	return nil
}

func validatePartialCompute(partial map[string]interface{}) []models.ValidationError {
	compute, ok := partial["compute"].(map[string]interface{})
	if !ok {
		return nil
	}
	if tier, ok := compute["tier"].(string); ok {
		validTiers := map[string]bool{"low": true, "standard": true, "high": true}
		if !validTiers[tier] {
			return []models.ValidationError{{
				Path:    "compute.tier",
				Message: "invalid compute tier '" + tier + "', expected low/standard/high",
				Code:    "INVALID_COMPUTE_TIER",
			}}
		}
	}
	return nil
}

func validatePartialSSH(partial map[string]interface{}) []models.ValidationError {
	ssh, ok := partial["ssh"].(map[string]interface{})
	if !ok {
		return nil
	}
	var errs []models.ValidationError
	if port, ok := ssh["port"].(float64); ok {
		if port < 1 || port > 65535 {
			errs = append(errs, models.ValidationError{
				Path:    "ssh.port",
				Message: "SSH port must be between 1 and 65535",
				Code:    "INVALID_SSH_PORT",
			})
		}
	}
	if user, ok := ssh["user"].(string); ok && user != "" {
		if strings.ContainsAny(user, " \t/\\") {
			errs = append(errs, models.ValidationError{
				Path:    "ssh.user",
				Message: "SSH user contains invalid characters",
				Code:    "INVALID_SSH_USER",
			})
		}
	}
	return errs
}

func validatePartialNodes(partial map[string]interface{}) []models.ValidationError {
	nodes, ok := partial["nodes"].([]interface{})
	if !ok {
		return nil
	}
	var errs []models.ValidationError
	validRoles := map[string]bool{"control-plane": true, "worker": true, "standalone": true}
	namesSeen := make(map[string]bool)
	for i, n := range nodes {
		node, ok := n.(map[string]interface{})
		if !ok {
			continue
		}
		prefix := "nodes[" + strings.Repeat("", 0) + fmt.Sprintf("%d", i) + "]"
		if nodeName, ok := node["name"].(string); ok {
			if namesSeen[nodeName] {
				errs = append(errs, models.ValidationError{
					Path:    prefix + ".name",
					Message: "duplicate node name: '" + nodeName + "'",
					Code:    "DUPLICATE_NODE_NAME",
				})
			}
			namesSeen[nodeName] = true
		}
		if role, ok := node["role"].(string); ok {
			if !validRoles[role] {
				errs = append(errs, models.ValidationError{
					Path:    prefix + ".role",
					Message: "invalid node role '" + role + "', expected control-plane/worker/standalone",
					Code:    "INVALID_NODE_ROLE",
				})
			}
		}
	}
	return errs
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
	if unmarshalErr := json.Unmarshal(body, &req); unmarshalErr != nil {
		slog.Warn("JSON parse error in generate request", "error", unmarshalErr)
		writeError(w, r, http.StatusBadRequest, "invalid JSON format")
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
		writeStructuredError(w, r, http.StatusNotFound, stackKitNotFoundError(req.Spec.StackKit))
		return
	}

	// Always generate into a temp directory — never accept a client-supplied path.
	tempDir, err := os.MkdirTemp("", "stackkit-tfvars-*")
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to create temp directory")
		return
	}
	defer func() { _ = os.RemoveAll(tempDir) }()

	// Use the TerraformBridge to generate tfvars
	bridge := cuepkg.NewTerraformBridge(dir)
	if genErr := bridge.GenerateWithValidation(tempDir); genErr != nil {
		writeStructuredError(w, r, http.StatusUnprocessableEntity, skerrors.NewDeploymentError(
			"generation_failed", "generation failed: "+genErr.Error(),
			skerrors.WithCause(genErr),
			skerrors.WithSuggestion("Validate your spec first: POST /api/v1/validate"),
			skerrors.WithSuggestion("Check CUE schema compliance: GET /api/v1/stackkits/"+req.Spec.StackKit+"/schema"),
		))
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
	if err := json.Unmarshal(data, &tfvars); err != nil {
		slog.Error("failed to parse generated tfvars", "error", err)
		writeError(w, r, http.StatusInternalServerError, "generated tfvars file is invalid")
		return
	}

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
	if unmarshalErr := json.Unmarshal(body, &req); unmarshalErr != nil {
		slog.Warn("JSON parse error in preview request", "error", unmarshalErr)
		writeError(w, r, http.StatusBadRequest, "invalid JSON format")
		return
	}

	if req.Spec.StackKit == "" {
		writeError(w, r, http.StatusBadRequest, "spec.stackkit field is required")
		return
	}

	loader := config.NewLoader(s.config.BaseDir)
	dir, err := loader.FindStackKitDir(req.Spec.StackKit)
	if err != nil {
		writeStructuredError(w, r, http.StatusNotFound, stackKitNotFoundError(req.Spec.StackKit))
		return
	}

	// Use temp directory for preview
	tempDir, err := os.MkdirTemp("", "stackkit-preview-*")
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "failed to create temp directory")
		return
	}
	defer func() { _ = os.RemoveAll(tempDir) }()

	bridge := cuepkg.NewTerraformBridge(dir)
	if valErr := bridge.ValidateBeforeGeneration(); valErr != nil {
		writeStructuredError(w, r, http.StatusUnprocessableEntity, skerrors.NewValidationError(
			"pre_generation_validation_failed", "pre-generation validation failed: "+valErr.Error(),
			skerrors.WithCause(valErr),
			skerrors.WithSuggestion("Run full validation first: POST /api/v1/validate"),
		))
		return
	}

	if genErr := bridge.GenerateTFVars(tempDir); genErr != nil {
		writeStructuredError(w, r, http.StatusUnprocessableEntity, skerrors.NewDeploymentError(
			"preview_generation_failed", "preview generation failed: "+genErr.Error(),
			skerrors.WithCause(genErr),
			skerrors.WithSuggestion("Validate your spec first: POST /api/v1/validate"),
		))
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
	if err := json.Unmarshal(data, &tfvars); err != nil {
		slog.Error("failed to parse generated preview tfvars", "error", err)
		writeError(w, r, http.StatusInternalServerError, "generated preview is invalid")
		return
	}

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

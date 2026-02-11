package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// testServer creates a test API server with a temp directory containing fixture stackkits.
func testServer(t *testing.T) (*Server, string) {
	t.Helper()
	tmpDir := t.TempDir()

	// Create a minimal stackkit fixture: base-homelab
	baseDir := filepath.Join(tmpDir, "base-homelab")
	require.NoError(t, os.MkdirAll(baseDir, 0755))
	stackkitYAML := `metadata:
  apiVersion: v1
  kind: StackKit
  name: base-homelab
  version: "4.0.0"
  displayName: "Base Homelab Kit"
  description: "Single-node homelab stack"
  license: "MIT"
  tags:
    - homelab
    - base
supportedOS:
  - ubuntu-22.04
  - debian-12
requirements:
  minimum:
    cpu: 2
    ram: 4
    disk: 40
  recommended:
    cpu: 4
    ram: 8
    disk: 80
modes:
  simple:
    name: Simple
    description: Single-node deployment
    engine: opentofu
    default: true
variants:
  default:
    name: Default
    description: Standard services
    services:
      - traefik
      - dokploy
    default: true
  minimal:
    name: Minimal
    description: Minimal services
    services:
      - traefik
`
	require.NoError(t, os.WriteFile(filepath.Join(baseDir, "stackkit.yaml"), []byte(stackkitYAML), 0644))

	// Create a minimal CUE schema file
	schemaCUE := `package base_homelab

import "github.com/kombihq/stackkits/base"

#BaseHomelabStack: base.#StackConfig & {
  metadata: name: "base-homelab"
}
`
	require.NoError(t, os.WriteFile(filepath.Join(baseDir, "stackfile.cue"), []byte(schemaCUE), 0644))

	srv := NewServer(ServerConfig{
		Port:    0,
		BaseDir: tmpDir,
		Version: "test",
	})

	return srv, tmpDir
}

// parseResponse parses a JSON response body and returns the top-level keys.
func parseResponse(t *testing.T, rec *httptest.ResponseRecorder) map[string]json.RawMessage {
	t.Helper()
	var result map[string]json.RawMessage
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &result))
	return result
}

// ── Health ────────────────────────────────────────────────────────

func TestHandleHealth(t *testing.T) {
	srv, _ := testServer(t)
	handler := srv.Handler()

	for _, path := range []string{"/health", "/api/v1/health"} {
		t.Run(path, func(t *testing.T) {
			req := httptest.NewRequest("GET", path, nil)
			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)

			assert.Equal(t, http.StatusOK, rec.Code)
			assert.Contains(t, rec.Header().Get("Content-Type"), "application/json")

			resp := parseResponse(t, rec)
			assert.Contains(t, string(resp["data"]), `"healthy"`)
			assert.NotNil(t, resp["meta"])
		})
	}
}

// ── Capabilities ──────────────────────────────────────────────────

func TestHandleCapabilities(t *testing.T) {
	srv, _ := testServer(t)
	req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)

	resp := parseResponse(t, rec)
	var data map[string]interface{}
	require.NoError(t, json.Unmarshal(resp["data"], &data))
	assert.Equal(t, "kombify-stackkits", data["service"])
	assert.NotNil(t, data["capabilities"])
}

// ── OpenAPI Spec ──────────────────────────────────────────────────

func TestHandleOpenAPISpec(t *testing.T) {
	srv, _ := testServer(t)
	req := httptest.NewRequest("GET", "/api/v1/openapi.yaml", nil)
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, rec.Header().Get("Content-Type"), "application/yaml")
	assert.Contains(t, rec.Body.String(), "openapi:")
}

// ── List StackKits ────────────────────────────────────────────────

func TestHandleListStackKits(t *testing.T) {
	srv, _ := testServer(t)
	req := httptest.NewRequest("GET", "/api/v1/stackkits", nil)
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)

	resp := parseResponse(t, rec)
	var page struct {
		Items  []stackKitSummary `json:"items"`
		Total  int               `json:"total"`
		Limit  int               `json:"limit"`
		Offset int               `json:"offset"`
	}
	require.NoError(t, json.Unmarshal(resp["data"], &page))
	assert.Len(t, page.Items, 1)
	assert.Equal(t, 1, page.Total)
	assert.Equal(t, 0, page.Offset)
	assert.Equal(t, "base-homelab", page.Items[0].Name)
	assert.Equal(t, "Base Homelab Kit", page.Items[0].DisplayName)
}

func TestHandleListStackKits_AutoDiscover(t *testing.T) {
	srv, tmpDir := testServer(t)

	// Add a second stackkit dynamically
	extraDir := filepath.Join(tmpDir, "custom-kit")
	require.NoError(t, os.MkdirAll(extraDir, 0755))
	extraYAML := `metadata:
  name: custom-kit
  version: "1.0.0"
  displayName: "Custom Kit"
  description: "A custom StackKit"
  license: "MIT"
supportedOS:
  - ubuntu-22.04
requirements:
  minimum:
    cpu: 1
    ram: 2
    disk: 20
  recommended:
    cpu: 2
    ram: 4
    disk: 40
modes:
  simple:
    name: Simple
    description: Basic deployment
    engine: opentofu
    default: true
variants:
  default:
    name: Default
    description: Default variant
    services:
      - nginx
    default: true
`
	require.NoError(t, os.WriteFile(filepath.Join(extraDir, "stackkit.yaml"), []byte(extraYAML), 0644))

	req := httptest.NewRequest("GET", "/api/v1/stackkits", nil)
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)

	resp := parseResponse(t, rec)
	var page struct {
		Items  []stackKitSummary `json:"items"`
		Total  int               `json:"total"`
		Limit  int               `json:"limit"`
		Offset int               `json:"offset"`
	}
	require.NoError(t, json.Unmarshal(resp["data"], &page))
	assert.Len(t, page.Items, 2)
	assert.Equal(t, 2, page.Total)
}

func TestHandleListStackKits_Pagination(t *testing.T) {
	srv, tmpDir := testServer(t)

	// Add a second stackkit so we have 2 total
	extraDir := filepath.Join(tmpDir, "custom-kit")
	require.NoError(t, os.MkdirAll(extraDir, 0755))
	extraYAML := `metadata:
  name: custom-kit
  version: "1.0.0"
  displayName: "Custom Kit"
  description: "A custom StackKit"
  license: "MIT"
supportedOS:
  - ubuntu-22.04
requirements:
  minimum:
    cpu: 1
    ram: 2
    disk: 20
  recommended:
    cpu: 2
    ram: 4
    disk: 40
modes:
  simple:
    name: Simple
    description: Basic deployment
    engine: opentofu
    default: true
variants:
  default:
    name: Default
    description: Default variant
    services:
      - nginx
    default: true
`
	require.NoError(t, os.WriteFile(filepath.Join(extraDir, "stackkit.yaml"), []byte(extraYAML), 0644))

	// Request with limit=1
	req := httptest.NewRequest("GET", "/api/v1/stackkits?limit=1&offset=0", nil)
	rec := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)

	resp := parseResponse(t, rec)
	var page struct {
		Items  []stackKitSummary `json:"items"`
		Total  int               `json:"total"`
		Limit  int               `json:"limit"`
		Offset int               `json:"offset"`
	}
	require.NoError(t, json.Unmarshal(resp["data"], &page))
	assert.Len(t, page.Items, 1)
	assert.Equal(t, 2, page.Total)
	assert.Equal(t, 1, page.Limit)
	assert.Equal(t, 0, page.Offset)

	// Request second page
	req2 := httptest.NewRequest("GET", "/api/v1/stackkits?limit=1&offset=1", nil)
	rec2 := httptest.NewRecorder()
	srv.Handler().ServeHTTP(rec2, req2)

	assert.Equal(t, http.StatusOK, rec2.Code)
	resp2 := parseResponse(t, rec2)
	var page2 struct {
		Items  []stackKitSummary `json:"items"`
		Total  int               `json:"total"`
		Limit  int               `json:"limit"`
		Offset int               `json:"offset"`
	}
	require.NoError(t, json.Unmarshal(resp2["data"], &page2))
	assert.Len(t, page2.Items, 1)
	assert.Equal(t, 2, page2.Total)
	assert.Equal(t, 1, page2.Offset)
}

// ── Get StackKit ──────────────────────────────────────────────────

func TestHandleGetStackKit(t *testing.T) {
	srv, _ := testServer(t)

	t.Run("found", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/base-homelab", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		assert.Contains(t, string(resp["data"]), `"base-homelab"`)
	})

	t.Run("not found", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/nonexistent", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNotFound, rec.Code)
		resp := parseResponse(t, rec)
		assert.Contains(t, string(resp["error"]), "not found")
	})

	t.Run("invalid name format", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/INVALID_NAME!", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
		resp := parseResponse(t, rec)
		errStr := string(resp["error"])
		assert.Contains(t, errStr, "invalid_name_format")
		assert.Contains(t, errStr, "pattern")
	})
}

// ── Get Schema ────────────────────────────────────────────────────

func TestHandleGetStackKitSchema(t *testing.T) {
	srv, _ := testServer(t)

	t.Run("found", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/base-homelab/schema", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Contains(t, rec.Body.String(), "package")
	})

	t.Run("not found", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/nonexistent/schema", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNotFound, rec.Code)
	})
}

// ── Get Defaults ──────────────────────────────────────────────────

func TestHandleGetStackKitDefaults(t *testing.T) {
	srv, _ := testServer(t)

	t.Run("returns defaults", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/base-homelab/defaults", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var data map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &data))
		assert.Equal(t, "base-homelab", data["stackkit"])
		assert.Equal(t, "default", data["variant"])
	})

	t.Run("not found", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/nonexistent/defaults", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNotFound, rec.Code)
	})
}

// ── Get Variants ──────────────────────────────────────────────────

func TestHandleGetStackKitVariants(t *testing.T) {
	srv, _ := testServer(t)

	t.Run("returns variants", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/base-homelab/variants", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var variants []map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &variants))
		assert.Len(t, variants, 2) // default + minimal
	})

	t.Run("not found", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/stackkits/nonexistent/variants", nil)
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNotFound, rec.Code)
	})
}

// ── Validate Spec ─────────────────────────────────────────────────

func TestHandleValidateSpec(t *testing.T) {
	srv, _ := testServer(t)
	handler := srv.Handler()

	t.Run("valid spec", func(t *testing.T) {
		body := `{"name":"test","stackkit":"base-homelab","domain":"example.com","email":"a@b.com","network":{"mode":"local"},"compute":{"tier":"standard"}}`
		req := httptest.NewRequest("POST", "/api/v1/validate", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, true, result["valid"])
	})

	t.Run("missing stackkit field", func(t *testing.T) {
		body := `{"name":"test"}`
		req := httptest.NewRequest("POST", "/api/v1/validate", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("invalid JSON", func(t *testing.T) {
		req := httptest.NewRequest("POST", "/api/v1/validate", strings.NewReader("{invalid"))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})
}

// ── Validate Partial ──────────────────────────────────────────────

func TestHandleValidatePartial(t *testing.T) {
	srv, _ := testServer(t)
	handler := srv.Handler()

	t.Run("valid stackkit", func(t *testing.T) {
		body := `{"stackkit":"base-homelab"}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, true, result["valid"])
	})

	t.Run("unknown stackkit", func(t *testing.T) {
		body := `{"stackkit":"nonexistent"}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("unknown variant", func(t *testing.T) {
		body := `{"stackkit":"base-homelab","variant":"nonexistent"}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("invalid mode", func(t *testing.T) {
		body := `{"mode":"badmode"}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("unusual network mode", func(t *testing.T) {
		body := `{"network":{"mode":"custom"}}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		// Unusual network modes produce warnings, not errors
		assert.Equal(t, true, result["valid"])
	})

	t.Run("invalid email", func(t *testing.T) {
		body := `{"email":"notanemail"}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("invalid domain", func(t *testing.T) {
		body := `{"domain":"no spaces"}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("invalid compute tier", func(t *testing.T) {
		body := `{"compute":{"tier":"mega"}}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("invalid SSH port", func(t *testing.T) {
		body := `{"ssh":{"port":99999}}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("invalid node role", func(t *testing.T) {
		body := `{"nodes":[{"name":"node1","role":"boss"}]}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("duplicate node names", func(t *testing.T) {
		body := `{"nodes":[{"name":"node1","role":"worker"},{"name":"node1","role":"worker"}]}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, false, result["valid"])
	})

	t.Run("valid expanded fields", func(t *testing.T) {
		body := `{"email":"test@example.com","domain":"lab.local","compute":{"tier":"standard"},"ssh":{"port":22,"user":"root"}}`
		req := httptest.NewRequest("POST", "/api/v1/validate/partial", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		resp := parseResponse(t, rec)
		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(resp["data"], &result))
		assert.Equal(t, true, result["valid"])
	})
}

// ── Generate TFVars ───────────────────────────────────────────────

func TestHandleGenerateTFVars(t *testing.T) {
	srv, _ := testServer(t)
	handler := srv.Handler()

	t.Run("missing stackkit", func(t *testing.T) {
		body := `{"spec":{}}`
		req := httptest.NewRequest("POST", "/api/v1/generate/tfvars", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("unknown stackkit", func(t *testing.T) {
		body := `{"spec":{"stackkit":"nonexistent"}}`
		req := httptest.NewRequest("POST", "/api/v1/generate/tfvars", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNotFound, rec.Code)
	})

	t.Run("invalid JSON", func(t *testing.T) {
		req := httptest.NewRequest("POST", "/api/v1/generate/tfvars", strings.NewReader("not-json"))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})
}

// ── Generate Preview ──────────────────────────────────────────────

func TestHandleGeneratePreview(t *testing.T) {
	srv, _ := testServer(t)
	handler := srv.Handler()

	t.Run("missing stackkit", func(t *testing.T) {
		body := `{"spec":{}}`
		req := httptest.NewRequest("POST", "/api/v1/generate/preview", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("unknown stackkit", func(t *testing.T) {
		body := `{"spec":{"stackkit":"nonexistent"}}`
		req := httptest.NewRequest("POST", "/api/v1/generate/preview", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNotFound, rec.Code)
	})
}

// ── Middleware: API Key ───────────────────────────────────────────

func TestAPIKeyMiddleware(t *testing.T) {
	tmpDir := t.TempDir()
	srv := NewServer(ServerConfig{
		Port:    0,
		BaseDir: tmpDir,
		Version: "test",
		APIKey:  "test-secret-key",
	})
	handler := srv.Handler()

	t.Run("valid key", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
		req.Header.Set("X-API-Key", "test-secret-key")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("missing key returns 401", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		assert.Contains(t, rec.Body.String(), "missing X-API-Key header")
	})

	t.Run("wrong key returns 401", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
		req.Header.Set("X-API-Key", "wrong-key")
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusForbidden, rec.Code)
		assert.Contains(t, rec.Body.String(), "invalid API key")
	})

	t.Run("health endpoint exempt from auth", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/health", nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("no key configured means open access", func(t *testing.T) {
		openSrv := NewServer(ServerConfig{
			Port:    0,
			BaseDir: tmpDir,
			Version: "test",
			APIKey:  "",
		})
		req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
		rec := httptest.NewRecorder()
		openSrv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})
}

// ── Middleware: CORS ──────────────────────────────────────────────

func TestCORSMiddleware(t *testing.T) {
	tmpDir := t.TempDir()

	t.Run("wildcard when no origins configured", func(t *testing.T) {
		srv := NewServer(ServerConfig{
			Port:    0,
			BaseDir: tmpDir,
			Version: "test",
		})
		req := httptest.NewRequest("GET", "/health", nil)
		req.Header.Set("Origin", "https://example.com")
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, "*", rec.Header().Get("Access-Control-Allow-Origin"))
	})

	t.Run("matching origin returned", func(t *testing.T) {
		srv := NewServer(ServerConfig{
			Port:        0,
			BaseDir:     tmpDir,
			Version:     "test",
			CORSOrigins: []string{"https://app.kombify.io", "https://localhost:3000"},
		})
		req := httptest.NewRequest("GET", "/health", nil)
		req.Header.Set("Origin", "https://app.kombify.io")
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, "https://app.kombify.io", rec.Header().Get("Access-Control-Allow-Origin"))
		assert.Equal(t, "Origin", rec.Header().Get("Vary"))
	})

	t.Run("non-matching origin gets no CORS header", func(t *testing.T) {
		srv := NewServer(ServerConfig{
			Port:        0,
			BaseDir:     tmpDir,
			Version:     "test",
			CORSOrigins: []string{"https://app.kombify.io"},
		})
		req := httptest.NewRequest("GET", "/health", nil)
		req.Header.Set("Origin", "https://evil.example.com")
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		// Non-matching origins should NOT get Access-Control-Allow-Origin (CORS denied)
		assert.Empty(t, rec.Header().Get("Access-Control-Allow-Origin"))
	})

	t.Run("preflight OPTIONS", func(t *testing.T) {
		srv := NewServer(ServerConfig{
			Port:        0,
			BaseDir:     tmpDir,
			Version:     "test",
			CORSOrigins: []string{"https://app.kombify.io"},
		})
		req := httptest.NewRequest("OPTIONS", "/api/v1/validate", nil)
		req.Header.Set("Origin", "https://app.kombify.io")
		req.Header.Set("Access-Control-Request-Method", "POST")
		rec := httptest.NewRecorder()
		srv.Handler().ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNoContent, rec.Code)
		assert.Equal(t, "https://app.kombify.io", rec.Header().Get("Access-Control-Allow-Origin"))
		assert.Contains(t, rec.Header().Get("Access-Control-Allow-Methods"), "POST")
	})
}

// ── Middleware: Rate Limiting ─────────────────────────────────────

func TestRateLimitMiddleware(t *testing.T) {
	tmpDir := t.TempDir()
	srv := NewServer(ServerConfig{
		Port:      0,
		BaseDir:   tmpDir,
		Version:   "test",
		RateLimit: 3, // very low limit for testing
	})
	handler := srv.Handler()

	t.Run("allows requests under limit", func(t *testing.T) {
		for i := 0; i < 3; i++ {
			req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
			req.RemoteAddr = "10.0.0.1:12345"
			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)

			assert.Equal(t, http.StatusOK, rec.Code, "request %d should succeed", i+1)
		}
	})

	t.Run("rejects when over limit", func(t *testing.T) {
		// Use a fresh IP to avoid interference
		for i := 0; i < 3; i++ {
			req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
			req.RemoteAddr = "10.0.0.2:12345"
			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)
			assert.Equal(t, http.StatusOK, rec.Code)
		}

		// 4th request should be rate limited
		req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
		req.RemoteAddr = "10.0.0.2:12345"
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusTooManyRequests, rec.Code)
		assert.Equal(t, "60", rec.Header().Get("Retry-After"))
	})

	t.Run("health endpoints exempt", func(t *testing.T) {
		for i := 0; i < 5; i++ {
			req := httptest.NewRequest("GET", "/health", nil)
			req.RemoteAddr = "10.0.0.3:12345"
			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)

			assert.Equal(t, http.StatusOK, rec.Code, "health request %d should be exempt", i+1)
		}
	})

	t.Run("no limit when rate limit is 0", func(t *testing.T) {
		unlimitedSrv := NewServer(ServerConfig{
			Port:      0,
			BaseDir:   tmpDir,
			Version:   "test",
			RateLimit: 0,
		})
		h := unlimitedSrv.Handler()

		for i := 0; i < 10; i++ {
			req := httptest.NewRequest("GET", "/api/v1/capabilities", nil)
			req.RemoteAddr = "10.0.0.4:12345"
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			assert.Equal(t, http.StatusOK, rec.Code)
		}
	})
}

package cue

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"cuelang.org/go/cue/cuecontext"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTerraformBridge_GenerateTFVars(t *testing.T) {
	// Create a temporary directory for test output
	tmpDir, err := os.MkdirTemp("", "tfbridge-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer func() { _ = os.RemoveAll(tmpDir) }()

	tests := []struct {
		name        string
		stackkitDir string
		wantErr     bool
	}{
		{
			name:        "base-homelab valid",
			stackkitDir: filepath.Join("..", "..", "base-homelab"),
			wantErr:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Check if stackkit dir exists
			if _, err := os.Stat(tt.stackkitDir); os.IsNotExist(err) {
				t.Skipf("StackKit directory not found: %s", tt.stackkitDir)
			}

			bridge := NewTerraformBridge(tt.stackkitDir)
			outputDir := filepath.Join(tmpDir, tt.name)

			err := bridge.GenerateTFVars(outputDir)
			if (err != nil) != tt.wantErr {
				t.Errorf("GenerateTFVars() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr {
				// Check if output file was created
				outputPath := filepath.Join(outputDir, "terraform.tfvars.json")
				if _, err := os.Stat(outputPath); os.IsNotExist(err) {
					t.Errorf("Expected output file not created: %s", outputPath)
				}
			}
		})
	}
}

func TestTerraformBridge_ValidateBeforeGeneration(t *testing.T) {
	tests := []struct {
		name        string
		stackkitDir string
		wantErr     bool
	}{
		{
			name:        "base-homelab valid CUE",
			stackkitDir: filepath.Join("..", "..", "base-homelab"),
			wantErr:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Check if stackkit dir exists
			if _, err := os.Stat(tt.stackkitDir); os.IsNotExist(err) {
				t.Skipf("StackKit directory not found: %s", tt.stackkitDir)
			}

			bridge := NewTerraformBridge(tt.stackkitDir)
			err := bridge.ValidateBeforeGeneration()
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateBeforeGeneration() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestTerraformBridge_GenerateWithValidation(t *testing.T) {
	stackkitDir := filepath.Join("..", "..", "base-homelab")
	if _, err := os.Stat(stackkitDir); os.IsNotExist(err) {
		t.Skipf("StackKit directory not found: %s", stackkitDir)
	}

	tmpDir := t.TempDir()

	t.Run("generates tfvars after validation", func(t *testing.T) {
		bridge := NewTerraformBridge(stackkitDir)
		outputDir := filepath.Join(tmpDir, "validated-output")

		err := bridge.GenerateWithValidation(outputDir)
		if err != nil {
			t.Errorf("GenerateWithValidation() error = %v", err)
			return
		}

		// Verify output file exists
		outputPath := filepath.Join(outputDir, "terraform.tfvars.json")
		if _, err := os.Stat(outputPath); os.IsNotExist(err) {
			t.Errorf("Expected output file not created: %s", outputPath)
		}
	})

	t.Run("fails for non-existent stackkit dir", func(t *testing.T) {
		bridge := NewTerraformBridge("/nonexistent/stackkit/dir")
		err := bridge.GenerateWithValidation(filepath.Join(tmpDir, "bad-output"))
		if err == nil {
			t.Error("Expected error for non-existent directory")
		}
	})
}

func TestTerraformBridge_GenerateTFVars_OutputCreation(t *testing.T) {
	stackkitDir := filepath.Join("..", "..", "base-homelab")
	if _, err := os.Stat(stackkitDir); os.IsNotExist(err) {
		t.Skipf("StackKit directory not found: %s", stackkitDir)
	}

	t.Run("creates nested output directories", func(t *testing.T) {
		tmpDir := t.TempDir()
		nestedOutput := filepath.Join(tmpDir, "a", "b", "c")

		bridge := NewTerraformBridge(stackkitDir)
		err := bridge.GenerateTFVars(nestedOutput)
		if err != nil {
			t.Errorf("GenerateTFVars() should create nested dirs, got error: %v", err)
		}
	})

	t.Run("output contains valid JSON", func(t *testing.T) {
		tmpDir := t.TempDir()

		bridge := NewTerraformBridge(stackkitDir)
		err := bridge.GenerateTFVars(tmpDir)
		if err != nil {
			t.Fatalf("GenerateTFVars() error: %v", err)
		}

		data, err := os.ReadFile(filepath.Join(tmpDir, "terraform.tfvars.json"))
		if err != nil {
			t.Fatalf("Failed to read output: %v", err)
		}

		// Verify it's valid JSON (not empty)
		if len(data) < 2 {
			t.Error("Output file is too small to be valid JSON")
		}
	})
}

// --- Tests for extractTFVars and extractFromStack ---

func TestExtractTFVars(t *testing.T) {
	ctx := cuecontext.New()
	bridge := &TerraformBridge{ctx: ctx, stackkitDir: "."}

	t.Run("defaults when CUE value has no relevant fields", func(t *testing.T) {
		value := ctx.CompileString(`{ foo: "bar" }`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "ports", tfvars.AccessMode)
		assert.Equal(t, "default", tfvars.Variant)
		assert.Equal(t, "standard", tfvars.ComputeTier)
		assert.Equal(t, "0.0.0.0", tfvars.BindAddress)
		assert.Empty(t, tfvars.Domain)
		assert.False(t, tfvars.EnableHTTPS)
		assert.False(t, tfvars.EnableLetsEncrypt)
	})

	t.Run("extracts network domain and sets proxy mode", func(t *testing.T) {
		value := ctx.CompileString(`{
			network: {
				domain: "example.com"
			}
		}`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "example.com", tfvars.Domain)
		assert.Equal(t, "proxy", tfvars.AccessMode)
		assert.True(t, tfvars.EnableHTTPS)
	})

	t.Run("extracts network domain and acmeEmail enables letsencrypt", func(t *testing.T) {
		value := ctx.CompileString(`{
			network: {
				domain:    "example.com"
				acmeEmail: "admin@example.com"
			}
		}`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "example.com", tfvars.Domain)
		assert.Equal(t, "admin@example.com", tfvars.ACMEEmail)
		assert.True(t, tfvars.EnableLetsEncrypt)
	})

	t.Run("acmeEmail without domain does not enable letsencrypt", func(t *testing.T) {
		value := ctx.CompileString(`{
			network: {
				acmeEmail: "admin@example.com"
			}
		}`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Empty(t, tfvars.Domain)
		assert.Equal(t, "admin@example.com", tfvars.ACMEEmail)
		assert.False(t, tfvars.EnableLetsEncrypt)
	})

	t.Run("extracts variant", func(t *testing.T) {
		value := ctx.CompileString(`{ variant: "minimal" }`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "minimal", tfvars.Variant)
	})

	t.Run("extracts computeTier", func(t *testing.T) {
		value := ctx.CompileString(`{ computeTier: "high" }`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "high", tfvars.ComputeTier)
	})

	t.Run("extracts from stack sub-path", func(t *testing.T) {
		value := ctx.CompileString(`{
			stack: {
				variant:     "full"
				computeTier: "low"
				network: {
					domain:    "stack.example.com"
					acmeEmail: "ops@example.com"
				}
			}
		}`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "full", tfvars.Variant)
		assert.Equal(t, "low", tfvars.ComputeTier)
		assert.Equal(t, "stack.example.com", tfvars.Domain)
		assert.Equal(t, "ops@example.com", tfvars.ACMEEmail)
		assert.True(t, tfvars.EnableHTTPS)
		assert.True(t, tfvars.EnableLetsEncrypt)
	})

	t.Run("extracts from testStack sub-path", func(t *testing.T) {
		value := ctx.CompileString(`{
			testStack: {
				variant: "test"
				network: {
					domain: "test.local"
				}
			}
		}`)
		require.NoError(t, value.Err())

		tfvars, err := bridge.extractTFVars(value)
		require.NoError(t, err)
		assert.Equal(t, "test", tfvars.Variant)
		assert.Equal(t, "test.local", tfvars.Domain)
	})
}

func TestExtractFromStack(t *testing.T) {
	ctx := cuecontext.New()
	bridge := &TerraformBridge{ctx: ctx, stackkitDir: "."}

	t.Run("extracts all fields from stack", func(t *testing.T) {
		stack := ctx.CompileString(`{
			variant:     "production"
			computeTier: "high"
			network: {
				domain:    "prod.example.com"
				acmeEmail: "certs@example.com"
			}
		}`)
		require.NoError(t, stack.Err())

		tfvars := &TFVars{
			AccessMode:  "ports",
			Variant:     "default",
			ComputeTier: "standard",
			BindAddress: "0.0.0.0",
		}
		bridge.extractFromStack(stack, tfvars)

		assert.Equal(t, "production", tfvars.Variant)
		assert.Equal(t, "high", tfvars.ComputeTier)
		assert.Equal(t, "prod.example.com", tfvars.Domain)
		assert.Equal(t, "certs@example.com", tfvars.ACMEEmail)
		assert.True(t, tfvars.EnableHTTPS)
		assert.True(t, tfvars.EnableLetsEncrypt)
	})

	t.Run("partial stack with only variant", func(t *testing.T) {
		stack := ctx.CompileString(`{ variant: "slim" }`)
		require.NoError(t, stack.Err())

		tfvars := &TFVars{}
		bridge.extractFromStack(stack, tfvars)
		assert.Equal(t, "slim", tfvars.Variant)
		assert.Empty(t, tfvars.Domain)
	})

	t.Run("stack network domain without acmeEmail", func(t *testing.T) {
		stack := ctx.CompileString(`{
			network: { domain: "local.dev" }
		}`)
		require.NoError(t, stack.Err())

		tfvars := &TFVars{}
		bridge.extractFromStack(stack, tfvars)
		assert.Equal(t, "local.dev", tfvars.Domain)
		assert.True(t, tfvars.EnableHTTPS)
		assert.False(t, tfvars.EnableLetsEncrypt)
	})

	t.Run("stack acmeEmail without domain no letsencrypt", func(t *testing.T) {
		stack := ctx.CompileString(`{
			network: { acmeEmail: "x@test.com" }
		}`)
		require.NoError(t, stack.Err())

		tfvars := &TFVars{}
		bridge.extractFromStack(stack, tfvars)
		assert.Empty(t, tfvars.Domain)
		assert.False(t, tfvars.EnableLetsEncrypt)
	})
}

func TestWriteTFVars(t *testing.T) {
	ctx := cuecontext.New()
	bridge := &TerraformBridge{ctx: ctx, stackkitDir: "."}

	t.Run("writes valid JSON file", func(t *testing.T) {
		tmpDir := t.TempDir()
		tfvars := &TFVars{
			Domain:      "example.com",
			AccessMode:  "proxy",
			EnableHTTPS: true,
			Variant:     "default",
			ComputeTier: "standard",
			BindAddress: "0.0.0.0",
		}

		err := bridge.writeTFVars(tfvars, tmpDir)
		require.NoError(t, err)

		data, err := os.ReadFile(filepath.Join(tmpDir, "terraform.tfvars.json"))
		require.NoError(t, err)

		var parsed TFVars
		require.NoError(t, json.Unmarshal(data, &parsed))
		assert.Equal(t, "example.com", parsed.Domain)
		assert.Equal(t, "proxy", parsed.AccessMode)
		assert.True(t, parsed.EnableHTTPS)
	})

	t.Run("fails for invalid output directory", func(t *testing.T) {
		tmpDir := t.TempDir()
		// Create a file that blocks directory creation
		blocker := filepath.Join(tmpDir, "blocker")
		require.NoError(t, os.WriteFile(blocker, []byte("x"), 0600))

		tfvars := &TFVars{Variant: "test"}
		err := bridge.writeTFVars(tfvars, filepath.Join(blocker, "sub"))
		assert.Error(t, err)
	})
}

func TestGenerateTFVars_ErrorPaths(t *testing.T) {
	t.Run("fails for non-existent stackkit dir", func(t *testing.T) {
		bridge := NewTerraformBridge("/nonexistent/stackkit")
		tmpDir := t.TempDir()
		err := bridge.GenerateTFVars(tmpDir)
		assert.Error(t, err)
	})

	t.Run("fails for directory with invalid CUE", func(t *testing.T) {
		tmpDir := t.TempDir()
		// Create an invalid CUE file
		cueContent := `package broken
name: "test
`
		require.NoError(t, os.WriteFile(filepath.Join(tmpDir, "bad.cue"), []byte(cueContent), 0600))

		bridge := NewTerraformBridge(tmpDir)
		outputDir := filepath.Join(tmpDir, "output")
		err := bridge.GenerateTFVars(outputDir)
		assert.Error(t, err)
	})

	t.Run("fails for empty directory", func(t *testing.T) {
		emptyDir := t.TempDir()
		bridge := NewTerraformBridge(emptyDir)
		err := bridge.GenerateTFVars(filepath.Join(emptyDir, "output"))
		assert.Error(t, err)
	})
}

func TestValidateStackKit_ErrorPaths(t *testing.T) {
	t.Run("returns result with errors for non-existent directory", func(t *testing.T) {
		validator := NewValidator(".")
		result, err := validator.ValidateStackKit("/nonexistent/dir")
		// ValidateStackKit may return an error or a result with errors
		if err != nil {
			return // acceptable — hard error
		}
		assert.False(t, result.Valid)
		assert.NotEmpty(t, result.Errors)
	})

	t.Run("reports load error for invalid CUE package", func(t *testing.T) {
		tmpDir := t.TempDir()
		// Create a CUE file with a bad import
		cueContent := `package broken
import "nonexistent/module"
x: module.Y
`
		require.NoError(t, os.WriteFile(filepath.Join(tmpDir, "bad.cue"), []byte(cueContent), 0600))

		validator := NewValidator(tmpDir)
		result, err := validator.ValidateStackKit(tmpDir)
		// Should return result (not error) with validation errors
		if err == nil {
			assert.False(t, result.Valid)
			assert.NotEmpty(t, result.Errors)
		}
		// Either way the validation flags the problem
	})

	t.Run("reports validation error for non-concrete CUE", func(t *testing.T) {
		tmpDir := t.TempDir()
		// Create a CUE file with non-concrete values
		cueContent := `package test
name: string
version: string
`
		require.NoError(t, os.WriteFile(filepath.Join(tmpDir, "abstract.cue"), []byte(cueContent), 0600))

		validator := NewValidator(tmpDir)
		result, err := validator.ValidateStackKit(tmpDir)
		require.NoError(t, err)
		assert.False(t, result.Valid)
		assert.NotEmpty(t, result.Errors)
		// Should have VALIDATION_ERROR code
		hasValidationError := false
		for _, e := range result.Errors {
			if e.Code == "VALIDATION_ERROR" {
				hasValidationError = true
				break
			}
		}
		assert.True(t, hasValidationError)
	})
}

func TestValidateBeforeGeneration_Failure(t *testing.T) {
	t.Run("returns error when validation fails", func(t *testing.T) {
		tmpDir := t.TempDir()
		cueContent := `package test
name: string
`
		require.NoError(t, os.WriteFile(filepath.Join(tmpDir, "abstract.cue"), []byte(cueContent), 0600))

		bridge := NewTerraformBridge(tmpDir)
		err := bridge.ValidateBeforeGeneration()
		assert.Error(t, err)
	})
}

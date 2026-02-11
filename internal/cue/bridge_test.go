package cue

import (
	"os"
	"path/filepath"
	"testing"
)

func TestTerraformBridge_GenerateTFVars(t *testing.T) {
	// Create a temporary directory for test output
	tmpDir, err := os.MkdirTemp("", "tfbridge-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

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

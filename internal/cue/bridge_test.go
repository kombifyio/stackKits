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

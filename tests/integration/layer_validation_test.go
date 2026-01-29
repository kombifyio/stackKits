package integration

import (
	"path/filepath"
	"runtime"
	"testing"

	"github.com/kombihq/stackkits/internal/validation"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// getProjectRootForLayerValidation returns the project root directory
func getProjectRootForLayerValidation(t *testing.T) string {
	_, filename, _, ok := runtime.Caller(0)
	require.True(t, ok, "Failed to get caller info")
	// Go up 3 levels: tests/integration -> tests -> root
	return filepath.Join(filepath.Dir(filename), "..", "..")
}

// TestLayerValidation_ExistingStackKits validates existing StackKits
func TestLayerValidation_ExistingStackKits(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	projectRoot := getProjectRootForLayerValidation(t)

	testCases := []struct {
		name      string
		stackkit  string
		wantValid bool
	}{
		{
			name:      "dev-homelab",
			stackkit:  "dev-homelab",
			wantValid: true,
		},
		// Note: Other StackKits need to add exports.cue with 3-layer fields to pass validation
		// This is documented in the 3-layer validation system plan
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			stackkitDir := filepath.Join(projectRoot, tc.stackkit)

			validator := validation.NewLayerValidator(projectRoot)
			result, err := validator.ValidateStackKit(stackkitDir)

			require.NoError(t, err)

			if tc.wantValid {
				assert.True(t, result.Valid,
					"StackKit %s should pass layer validation. Errors: %v",
					tc.stackkit, result.AllErrors)
			} else {
				assert.False(t, result.Valid,
					"StackKit %s should fail layer validation", tc.stackkit)
			}
		})
	}
}

// TestLayerValidation_DevHomelabLayers validates dev-homelab layer by layer
func TestLayerValidation_DevHomelabLayers(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	projectRoot := getProjectRootForLayerValidation(t)
	stackkitDir := filepath.Join(projectRoot, "dev-homelab")

	validator := validation.NewLayerValidator(projectRoot)
	result, err := validator.ValidateStackKit(stackkitDir)

	require.NoError(t, err)

	t.Run("Layer1_Foundation", func(t *testing.T) {
		assert.True(t, result.Layer1.Valid, "Layer 1 (Foundation) should be valid")
		if !result.Layer1.Valid {
			t.Logf("Layer 1 errors: %v", result.Layer1.Errors)
		}
	})

	t.Run("Layer2_Platform", func(t *testing.T) {
		assert.True(t, result.Layer2.Valid, "Layer 2 (Platform) should be valid")
		if !result.Layer2.Valid {
			t.Logf("Layer 2 errors: %v", result.Layer2.Errors)
		}
	})

	t.Run("Layer3_Applications", func(t *testing.T) {
		assert.True(t, result.Layer3.Valid, "Layer 3 (Applications) should be valid")
		if !result.Layer3.Valid {
			t.Logf("Layer 3 errors: %v", result.Layer3.Errors)
		}
	})

	t.Run("Overall", func(t *testing.T) {
		assert.True(t, result.Valid, "Overall validation should pass")
		assert.Equal(t, "dev-homelab", result.StackKit)
	})
}

// TestLayerValidation_ErrorMessages validates that error messages are clear and actionable
func TestLayerValidation_ErrorMessages(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	projectRoot := getProjectRootForLayerValidation(t)
	stackkitDir := filepath.Join(projectRoot, "dev-homelab")

	validator := validation.NewLayerValidator(projectRoot)
	result, err := validator.ValidateStackKit(stackkitDir)

	require.NoError(t, err)

	// If there are any errors, verify they have clear messages
	for _, layerErr := range result.AllErrors {
		t.Run("Error_"+layerErr.Code, func(t *testing.T) {
			assert.NotEmpty(t, layerErr.Message, "Error message should not be empty")
			assert.NotEmpty(t, layerErr.Code, "Error code should not be empty")
			assert.True(t, layerErr.Layer >= 1 && layerErr.Layer <= 3, "Layer should be 1, 2, or 3")
		})
	}
}

// TestLayerValidation_StackKitNames validates that all StackKits have proper names
func TestLayerValidation_StackKitNames(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	projectRoot := getProjectRootForLayerValidation(t)

	stackkits := []string{"dev-homelab", "base-homelab", "ha-homelab", "modern-homelab"}

	for _, stackkit := range stackkits {
		t.Run(stackkit, func(t *testing.T) {
			stackkitDir := filepath.Join(projectRoot, stackkit)
			validator := validation.NewLayerValidator(projectRoot)
			result, err := validator.ValidateStackKit(stackkitDir)

			require.NoError(t, err)
			assert.Equal(t, stackkit, result.StackKit, "StackKit name should match directory name")
		})
	}
}

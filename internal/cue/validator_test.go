// Package cue tests
package cue

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/kombihq/stackkits/pkg/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestValidator(t *testing.T) {
	t.Run("creates validator", func(t *testing.T) {
		validator := NewValidator("/test/path")
		assert.NotNil(t, validator)
	})

	t.Run("returns schema directory", func(t *testing.T) {
		basePath := filepath.Join("test", "path")
		validator := NewValidator(basePath)
		schemaDir := validator.GetSchemaDir()
		expected := filepath.Join(basePath, "base")
		assert.Equal(t, expected, schemaDir)
	})
}

func TestValidateSpec(t *testing.T) {
	validator := NewValidator(".")

	t.Run("validates complete spec", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test-deployment",
			StackKit: "base-homelab",
			Variant:  "default",
			Mode:     "simple",
			Network: models.NetworkSpec{
				Mode:   "local",
				Subnet: "172.20.0.0/16",
			},
			Compute: models.ComputeSpec{
				Tier: "standard",
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.True(t, result.Valid)
		assert.Empty(t, result.Errors)
	})

	t.Run("fails for missing name", func(t *testing.T) {
		spec := &models.StackSpec{
			StackKit: "base-homelab",
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.False(t, result.Valid)
		assert.NotEmpty(t, result.Errors)

		hasNameError := false
		for _, e := range result.Errors {
			if e.Path == "name" {
				hasNameError = true
				break
			}
		}
		assert.True(t, hasNameError)
	})

	t.Run("fails for missing stackkit", func(t *testing.T) {
		spec := &models.StackSpec{
			Name: "test",
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.False(t, result.Valid)
	})

	t.Run("fails for invalid network mode", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test",
			StackKit: "base-homelab",
			Network: models.NetworkSpec{
				Mode: "invalid-mode",
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.False(t, result.Valid)

		hasNetworkError := false
		for _, e := range result.Errors {
			if e.Path == "network.mode" {
				hasNetworkError = true
				break
			}
		}
		assert.True(t, hasNetworkError)
	})

	t.Run("fails for invalid compute tier", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test",
			StackKit: "base-homelab",
			Compute: models.ComputeSpec{
				Tier: "ultra-mega",
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.False(t, result.Valid)
	})

	t.Run("validates valid network modes", func(t *testing.T) {
		validModes := []string{"local", "public", "hybrid"}

		for _, mode := range validModes {
			spec := &models.StackSpec{
				Name:     "test",
				StackKit: "base-homelab",
				Network: models.NetworkSpec{
					Mode: mode,
				},
			}

			result, err := validator.ValidateSpec(spec)

			require.NoError(t, err)
			assert.True(t, result.Valid, "mode %s should be valid", mode)
		}
	})

	t.Run("validates valid compute tiers", func(t *testing.T) {
		validTiers := []string{"minimal", "standard", "performance"}

		for _, tier := range validTiers {
			spec := &models.StackSpec{
				Name:     "test",
				StackKit: "base-homelab",
				Compute: models.ComputeSpec{
					Tier: tier,
				},
			}

			result, err := validator.ValidateSpec(spec)

			require.NoError(t, err)
			assert.True(t, result.Valid, "tier %s should be valid", tier)
		}
	})

	t.Run("validates nodes", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test",
			StackKit: "ha-homelab",
			Nodes: []models.NodeSpec{
				{Name: "", IP: "192.168.1.10"}, // Missing name
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.False(t, result.Valid)
	})

	t.Run("validates node IP required", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test",
			StackKit: "ha-homelab",
			Nodes: []models.NodeSpec{
				{Name: "node-1", IP: ""}, // Missing IP
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.False(t, result.Valid)
	})

	t.Run("warns for missing domain in public mode", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test",
			StackKit: "base-homelab",
			Network: models.NetworkSpec{
				Mode: "public",
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.True(t, result.Valid) // Valid but with warnings
		assert.NotEmpty(t, result.Warnings)
	})

	t.Run("warns for missing email in public mode", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "test",
			StackKit: "base-homelab",
			Domain:   "example.com",
			Network: models.NetworkSpec{
				Mode: "public",
			},
		}

		result, err := validator.ValidateSpec(spec)

		require.NoError(t, err)
		assert.True(t, result.Valid)
		assert.NotEmpty(t, result.Warnings)

		hasEmailWarning := false
		for _, w := range result.Warnings {
			if w.Path == "email" {
				hasEmailWarning = true
				break
			}
		}
		assert.True(t, hasEmailWarning)
	})
}

func TestValidateCUEFile(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "cue-test-*")
	require.NoError(t, err)
	defer os.RemoveAll(tmpDir)

	validator := NewValidator(tmpDir)

	t.Run("validates valid CUE file", func(t *testing.T) {
		cueContent := `package test

name: "test"
version: "1.0.0"
`
		cuePath := filepath.Join(tmpDir, "valid.cue")
		err := os.WriteFile(cuePath, []byte(cueContent), 0644)
		require.NoError(t, err)

		result, err := validator.ValidateCUEFile(cuePath)

		require.NoError(t, err)
		assert.True(t, result.Valid)
	})

	t.Run("fails for invalid CUE syntax", func(t *testing.T) {
		cueContent := `package test

name: "test
version: "1.0.0"
`
		cuePath := filepath.Join(tmpDir, "invalid.cue")
		err := os.WriteFile(cuePath, []byte(cueContent), 0644)
		require.NoError(t, err)

		result, err := validator.ValidateCUEFile(cuePath)

		require.NoError(t, err)
		assert.False(t, result.Valid)
		assert.NotEmpty(t, result.Errors)
	})

	t.Run("returns error for missing file", func(t *testing.T) {
		_, err := validator.ValidateCUEFile("/nonexistent/file.cue")

		assert.Error(t, err)
	})
}

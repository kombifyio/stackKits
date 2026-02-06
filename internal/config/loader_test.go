// Package config tests
package config

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/kombihq/stackkits/pkg/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoader(t *testing.T) {
	t.Run("creates loader with base path", func(t *testing.T) {
		loader := NewLoader("/test/path")
		assert.NotNil(t, loader)
	})
}

func TestLoadStackSpec(t *testing.T) {
	// Create temp directory
	tmpDir, err := os.MkdirTemp("", "stackkit-test-*")
	require.NoError(t, err)
	defer os.RemoveAll(tmpDir)

	t.Run("loads valid spec file", func(t *testing.T) {
		specContent := `name: test-deployment
stackkit: base-homelab
variant: default
mode: simple
domain: homelab.local
network:
  mode: local
  subnet: 172.20.0.0/16
compute:
  tier: standard
ssh:
  user: root
  port: 22
`
		specPath := filepath.Join(tmpDir, "stack-spec.yaml")
		err := os.WriteFile(specPath, []byte(specContent), 0644)
		require.NoError(t, err)

		loader := NewLoader(tmpDir)
		spec, err := loader.LoadStackSpec("stack-spec.yaml")

		require.NoError(t, err)
		assert.Equal(t, "test-deployment", spec.Name)
		assert.Equal(t, "base-homelab", spec.StackKit)
		assert.Equal(t, "default", spec.Variant)
		assert.Equal(t, "local", spec.Network.Mode)
	})

	t.Run("returns error for missing file", func(t *testing.T) {
		loader := NewLoader(tmpDir)
		_, err := loader.LoadStackSpec("nonexistent.yaml")

		assert.Error(t, err)
	})

	t.Run("applies defaults", func(t *testing.T) {
		specContent := `name: minimal
stackkit: base-homelab
`
		specPath := filepath.Join(tmpDir, "minimal-spec.yaml")
		err := os.WriteFile(specPath, []byte(specContent), 0644)
		require.NoError(t, err)

		loader := NewLoader(tmpDir)
		spec, err := loader.LoadStackSpec("minimal-spec.yaml")

		require.NoError(t, err)
		assert.Equal(t, "default", spec.Variant)
		assert.Equal(t, "simple", spec.Mode)
		assert.Equal(t, "local", spec.Network.Mode)
		assert.Equal(t, "172.20.0.0/16", spec.Network.Subnet)
		assert.Equal(t, "standard", spec.Compute.Tier)
		assert.Equal(t, 22, spec.SSH.Port)
		assert.Equal(t, "root", spec.SSH.User)
	})

	t.Run("returns error for invalid YAML", func(t *testing.T) {
		specContent := `invalid: yaml: content: [}`
		specPath := filepath.Join(tmpDir, "invalid.yaml")
		err := os.WriteFile(specPath, []byte(specContent), 0644)
		require.NoError(t, err)

		loader := NewLoader(tmpDir)
		_, err = loader.LoadStackSpec("invalid.yaml")

		assert.Error(t, err)
	})
}

func TestSaveStackSpec(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "stackkit-test-*")
	require.NoError(t, err)
	defer os.RemoveAll(tmpDir)

	t.Run("saves spec file", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "saved-deployment",
			StackKit: "base-homelab",
			Variant:  "default",
			Mode:     "simple",
			Network: models.NetworkSpec{
				Mode:   "local",
				Subnet: "172.20.0.0/16",
			},
		}

		loader := NewLoader(tmpDir)
		specPath := filepath.Join(tmpDir, "saved-spec.yaml")
		err := loader.SaveStackSpec(spec, specPath)

		require.NoError(t, err)

		// Verify file exists
		_, err = os.Stat(specPath)
		assert.NoError(t, err)

		// Load and verify
		loaded, err := loader.LoadStackSpec("saved-spec.yaml")
		require.NoError(t, err)
		assert.Equal(t, "saved-deployment", loaded.Name)
	})

	t.Run("creates directory if needed", func(t *testing.T) {
		spec := &models.StackSpec{
			Name:     "nested",
			StackKit: "base-homelab",
		}

		loader := NewLoader(tmpDir)
		specPath := filepath.Join(tmpDir, "nested", "dir", "spec.yaml")
		err := loader.SaveStackSpec(spec, specPath)

		require.NoError(t, err)

		_, err = os.Stat(specPath)
		assert.NoError(t, err)
	})
}

func TestLoadStackKit(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "stackkit-test-*")
	require.NoError(t, err)
	defer os.RemoveAll(tmpDir)

	t.Run("loads valid stackkit.yaml", func(t *testing.T) {
		stackkitContent := `metadata:
  apiVersion: stackkit/v1
  kind: StackKit
  name: test-stackkit
  version: 1.0.0
  displayName: Test StackKit
  description: A test stackkit
  license: MIT

supportedOS:
  - ubuntu-24
  - ubuntu-22
  - debian-12

requirements:
  minimum:
    cpu: 2
    ram: 4
    disk: 20
  recommended:
    cpu: 4
    ram: 8
    disk: 50

modes:
  simple:
    name: Simple
    description: OpenTofu only
    engine: opentofu
    default: true

variants:
  default:
    name: Default
    description: Full services
    services: [traefik, dokploy]
    default: true
`
		stackkitPath := filepath.Join(tmpDir, "stackkit.yaml")
		err := os.WriteFile(stackkitPath, []byte(stackkitContent), 0644)
		require.NoError(t, err)

		loader := NewLoader(tmpDir)
		sk, err := loader.LoadStackKit("stackkit.yaml")

		require.NoError(t, err)
		assert.Equal(t, "test-stackkit", sk.Metadata.Name)
		assert.Equal(t, "1.0.0", sk.Metadata.Version)
		assert.Contains(t, sk.SupportedOS, "ubuntu-24")
		assert.Len(t, sk.Variants, 1)
	})

	t.Run("validates required fields", func(t *testing.T) {
		// Missing name
		stackkitContent := `metadata:
  version: 1.0.0
supportedOS:
  - ubuntu-24
`
		stackkitPath := filepath.Join(tmpDir, "invalid-stackkit.yaml")
		err := os.WriteFile(stackkitPath, []byte(stackkitContent), 0644)
		require.NoError(t, err)

		loader := NewLoader(tmpDir)
		_, err = loader.LoadStackKit("invalid-stackkit.yaml")

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "name")
	})
}

func TestDeploymentState(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "stackkit-test-*")
	require.NoError(t, err)
	defer os.RemoveAll(tmpDir)

	t.Run("saves and loads deployment state", func(t *testing.T) {
		state := &models.DeploymentState{
			StackKit: "base-homelab",
			Variant:  "default",
			Mode:     "simple",
			Status:   models.StatusRunning,
			Services: []models.ServiceState{
				{
					Name:   "traefik",
					Status: models.ServiceStatusRunning,
					Health: models.HealthStatusHealthy,
				},
			},
		}

		loader := NewLoader(tmpDir)
		statePath := filepath.Join(tmpDir, "state.yaml")

		err := loader.SaveDeploymentState(state, statePath)
		require.NoError(t, err)

		loaded, err := loader.LoadDeploymentState(statePath)
		require.NoError(t, err)
		assert.Equal(t, "base-homelab", loaded.StackKit)
		assert.Equal(t, models.StatusRunning, loaded.Status)
		assert.Len(t, loaded.Services, 1)
	})

	t.Run("returns nil for missing state", func(t *testing.T) {
		loader := NewLoader(tmpDir)
		state, err := loader.LoadDeploymentState("nonexistent.yaml")

		assert.NoError(t, err)
		assert.Nil(t, state)
	})
}

func TestExpandPath(t *testing.T) {
	t.Run("expands home directory", func(t *testing.T) {
		home, _ := os.UserHomeDir()
		expanded := ExpandPath("~/test/path")

		assert.Equal(t, filepath.Join(home, "test", "path"), expanded)
	})

	t.Run("leaves absolute paths unchanged", func(t *testing.T) {
		path := "/absolute/path"
		expanded := ExpandPath(path)

		assert.Equal(t, path, expanded)
	})

	t.Run("expands environment variables", func(t *testing.T) {
		os.Setenv("TEST_VAR", "test-value")
		defer os.Unsetenv("TEST_VAR")

		expanded := ExpandPath("$TEST_VAR/path")

		assert.Contains(t, expanded, "test-value")
	})
}

func TestFindStackKitDir(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "stackkit-test-*")
	require.NoError(t, err)
	defer os.RemoveAll(tmpDir)

	t.Run("finds stackkit in base path", func(t *testing.T) {
		// Create stackkit directory
		stackkitDir := filepath.Join(tmpDir, "test-stackkit")
		err := os.MkdirAll(stackkitDir, 0755)
		require.NoError(t, err)

		// Create stackkit.yaml
		stackkitPath := filepath.Join(stackkitDir, "stackkit.yaml")
		err = os.WriteFile(stackkitPath, []byte("metadata:\n  name: test"), 0644)
		require.NoError(t, err)

		loader := NewLoader(tmpDir)
		found, err := loader.FindStackKitDir("test-stackkit")

		require.NoError(t, err)
		assert.Equal(t, stackkitDir, found)
	})

	t.Run("returns error for missing stackkit", func(t *testing.T) {
		loader := NewLoader(tmpDir)
		_, err := loader.FindStackKitDir("nonexistent")

		assert.Error(t, err)
	})
}

func TestGetDefaultSpecPath(t *testing.T) {
	t.Run("returns default path", func(t *testing.T) {
		path := GetDefaultSpecPath()
		assert.Equal(t, "stack-spec.yaml", path)
	})
}

func TestGetDeployDir(t *testing.T) {
	t.Run("returns deploy directory", func(t *testing.T) {
		dir := GetDeployDir()
		assert.Equal(t, "deploy", dir)
	})
}

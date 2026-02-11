// Package tofu tests
package tofu

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestExecutor(t *testing.T) {
	t.Run("creates executor with defaults", func(t *testing.T) {
		executor := NewExecutor()

		assert.NotNil(t, executor)
		assert.Equal(t, ".", executor.GetWorkDir())
	})

	t.Run("creates executor with options", func(t *testing.T) {
		executor := NewExecutor(
			WithWorkDir("/test/dir"),
			WithBinary("opentofu"),
			WithTimeout(10*time.Minute),
			WithAutoApprove(true),
		)

		assert.Equal(t, "/test/dir", executor.GetWorkDir())
	})

	t.Run("sets work directory", func(t *testing.T) {
		executor := NewExecutor()
		executor.SetWorkDir("/new/dir")

		assert.Equal(t, "/new/dir", executor.GetWorkDir())
	})
}

func TestExecutorIsInstalled(t *testing.T) {
	t.Run("checks for tofu binary", func(t *testing.T) {
		executor := NewExecutor()
		// This will return true/false depending on system
		_ = executor.IsInstalled()
	})

	t.Run("checks for custom binary", func(t *testing.T) {
		executor := NewExecutor(WithBinary("nonexistent-binary-xyz"))

		assert.False(t, executor.IsInstalled())
	})
}

func TestParsePlanOutput(t *testing.T) {
	t.Run("parses add changes", func(t *testing.T) {
		output := `
Terraform will perform the following actions:

Plan: 3 to add, 0 to change, 0 to destroy.
`
		changes := ParsePlanOutput(output)

		assert.Equal(t, 3, changes.Add)
		assert.Equal(t, 0, changes.Change)
		assert.Equal(t, 0, changes.Destroy)
	})

	t.Run("parses mixed changes", func(t *testing.T) {
		output := `
Terraform will perform the following actions:

Plan: 2 to add, 1 to change, 3 to destroy.
`
		changes := ParsePlanOutput(output)

		assert.Equal(t, 2, changes.Add)
		assert.Equal(t, 1, changes.Change)
		assert.Equal(t, 3, changes.Destroy)
	})

	t.Run("handles no changes", func(t *testing.T) {
		output := `No changes. Infrastructure is up-to-date.`

		changes := ParsePlanOutput(output)

		assert.Equal(t, 0, changes.Add)
		assert.Equal(t, 0, changes.Change)
		assert.Equal(t, 0, changes.Destroy)
	})

	t.Run("handles empty output", func(t *testing.T) {
		changes := ParsePlanOutput("")

		assert.Equal(t, 0, changes.Add)
		assert.Equal(t, 0, changes.Change)
		assert.Equal(t, 0, changes.Destroy)
	})
}

func TestResult(t *testing.T) {
	t.Run("creates successful result", func(t *testing.T) {
		result := &Result{
			Success:  true,
			ExitCode: 0,
			Stdout:   "Success output",
			Stderr:   "",
			Duration: 5 * time.Second,
		}

		assert.True(t, result.Success)
		assert.Equal(t, 0, result.ExitCode)
		assert.NotEmpty(t, result.Stdout)
		assert.Empty(t, result.Stderr)
	})

	t.Run("creates failed result", func(t *testing.T) {
		result := &Result{
			Success:  false,
			ExitCode: 1,
			Stdout:   "",
			Stderr:   "Error: something went wrong",
			Duration: 2 * time.Second,
		}

		assert.False(t, result.Success)
		assert.Equal(t, 1, result.ExitCode)
		assert.NotEmpty(t, result.Stderr)
	})
}

func TestEnsureStateDir(t *testing.T) {
	t.Run("creates state directory", func(t *testing.T) {
		tmpDir := t.TempDir()
		err := EnsureStateDir(tmpDir)
		assert.NoError(t, err)

		stateDir := filepath.Join(tmpDir, ".stackkit")
		info, err := os.Stat(stateDir)
		assert.NoError(t, err)
		assert.True(t, info.IsDir())
	})

	t.Run("idempotent on existing directory", func(t *testing.T) {
		tmpDir := t.TempDir()
		// Create twice — should not error
		assert.NoError(t, EnsureStateDir(tmpDir))
		assert.NoError(t, EnsureStateDir(tmpDir))
	})
}

// Integration tests that require actual tofu installation
func TestExecutorIntegration(t *testing.T) {
	executor := NewExecutor()

	// Skip if tofu is not installed
	if !executor.IsInstalled() {
		t.Skip("OpenTofu not installed, skipping integration tests")
	}

	ctx := context.Background()

	t.Run("gets version", func(t *testing.T) {
		version, err := executor.Version(ctx)

		assert.NoError(t, err)
		assert.NotEmpty(t, version)
	})
}

func TestPlanChanges(t *testing.T) {
	t.Run("zero values", func(t *testing.T) {
		changes := &PlanChanges{}

		assert.Equal(t, 0, changes.Add)
		assert.Equal(t, 0, changes.Change)
		assert.Equal(t, 0, changes.Destroy)
	})
}

func TestTimeoutError(t *testing.T) {
	t.Run("creates timeout error", func(t *testing.T) {
		err := &TimeoutError{
			Command:  "tofu plan",
			Duration: 30 * time.Minute,
		}

		assert.Contains(t, err.Error(), "tofu plan")
		assert.Contains(t, err.Error(), "timed out")
	})

	t.Run("IsTimeoutError returns true for timeout", func(t *testing.T) {
		err := &TimeoutError{Command: "test", Duration: time.Second}
		assert.True(t, IsTimeoutError(err))
	})

	t.Run("IsTimeoutError returns false for other errors", func(t *testing.T) {
		err := assert.AnError
		assert.False(t, IsTimeoutError(err))
	})
}

func TestValidateWorkDir(t *testing.T) {
	t.Run("empty directory", func(t *testing.T) {
		err := ValidateWorkDir("")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "cannot be empty")
	})

	t.Run("non-existent directory", func(t *testing.T) {
		err := ValidateWorkDir("/nonexistent/path/xyz123")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "does not exist")
	})

	t.Run("valid directory", func(t *testing.T) {
		// Use current directory which should exist
		err := ValidateWorkDir(".")
		assert.NoError(t, err)
	})
}

func TestHasTerraformFiles(t *testing.T) {
	t.Run("empty directory", func(t *testing.T) {
		tmpDir := t.TempDir()
		has, err := HasTerraformFiles(tmpDir)
		assert.NoError(t, err)
		assert.False(t, has)
	})

	t.Run("directory with .tf files", func(t *testing.T) {
		tmpDir := t.TempDir()
		os.WriteFile(filepath.Join(tmpDir, "main.tf"), []byte("# test"), 0644)

		has, err := HasTerraformFiles(tmpDir)
		assert.NoError(t, err)
		assert.True(t, has)
	})

	t.Run("directory with non-tf files only", func(t *testing.T) {
		tmpDir := t.TempDir()
		os.WriteFile(filepath.Join(tmpDir, "readme.md"), []byte("# test"), 0644)
		os.WriteFile(filepath.Join(tmpDir, "config.json"), []byte("{}"), 0644)

		has, err := HasTerraformFiles(tmpDir)
		assert.NoError(t, err)
		assert.False(t, has)
	})

	t.Run("non-existent directory", func(t *testing.T) {
		_, err := HasTerraformFiles("/nonexistent/path/xyz")
		assert.Error(t, err)
	})
}

func TestExecutorWithTimeout(t *testing.T) {
	t.Run("very short timeout", func(t *testing.T) {
		executor := NewExecutor(
			WithTimeout(1*time.Nanosecond),
			WithBinary("nonexistent-command"),
		)

		assert.Equal(t, 1*time.Nanosecond, executor.timeout)
	})
}

func TestExecutorOptions(t *testing.T) {
	t.Run("WithAutoApprove", func(t *testing.T) {
		e := NewExecutor(WithAutoApprove(true))
		assert.True(t, e.autoApprove)
	})

	t.Run("WithBinary", func(t *testing.T) {
		e := NewExecutor(WithBinary("terraform"))
		assert.Equal(t, "terraform", e.binary)
	})

	t.Run("all options combined", func(t *testing.T) {
		e := NewExecutor(
			WithWorkDir("/test"),
			WithBinary("tf"),
			WithTimeout(5*time.Minute),
			WithAutoApprove(true),
		)

		assert.Equal(t, "/test", e.workDir)
		assert.Equal(t, "tf", e.binary)
		assert.Equal(t, 5*time.Minute, e.timeout)
		assert.True(t, e.autoApprove)
	})
}

func TestValidateWorkDir_FileNotDir(t *testing.T) {
	t.Run("file instead of directory", func(t *testing.T) {
		tmpDir := t.TempDir()
		tmpFile := filepath.Join(tmpDir, "not-a-dir.txt")
		os.WriteFile(tmpFile, []byte("test"), 0644)

		err := ValidateWorkDir(tmpFile)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not a directory")
	})
}

func TestImportRequiresArgs(t *testing.T) {
	executor := NewExecutor(WithBinary("nonexistent-binary-xyz"))

	t.Run("empty address", func(t *testing.T) {
		_, err := executor.Import(context.Background(), "", "some-id")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "address and id are required")
	})

	t.Run("empty id", func(t *testing.T) {
		_, err := executor.Import(context.Background(), "aws_instance.foo", "")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "address and id are required")
	})

	t.Run("both empty", func(t *testing.T) {
		_, err := executor.Import(context.Background(), "", "")
		assert.Error(t, err)
	})
}

func TestTaintRequiresAddress(t *testing.T) {
	executor := NewExecutor(WithBinary("nonexistent-binary-xyz"))

	t.Run("empty address for taint", func(t *testing.T) {
		_, err := executor.Taint(context.Background(), "")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "resource address is required")
	})

	t.Run("empty address for untaint", func(t *testing.T) {
		_, err := executor.Untaint(context.Background(), "")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "resource address is required")
	})
}

func TestParsePlanOutputEdgeCases(t *testing.T) {
	t.Run("plan with period ending", func(t *testing.T) {
		output := `Plan: 1 to add, 0 to change, 2 to destroy.`
		changes := ParsePlanOutput(output)
		assert.Equal(t, 1, changes.Add)
		assert.Equal(t, 0, changes.Change)
		assert.Equal(t, 2, changes.Destroy)
	})

	t.Run("multiline output with plan", func(t *testing.T) {
		output := "Some header\n\nAnother line\nPlan: 5 to add, 3 to change, 1 to destroy.\n\nDone."
		changes := ParsePlanOutput(output)
		assert.Equal(t, 5, changes.Add)
		assert.Equal(t, 3, changes.Change)
		assert.Equal(t, 1, changes.Destroy)
	})
}

func TestEnsureStateDirNestedPath(t *testing.T) {
	t.Run("creates nested state directory", func(t *testing.T) {
		tmpDir := t.TempDir()
		nested := filepath.Join(tmpDir, "a", "b", "c")
		os.MkdirAll(nested, 0755)

		err := EnsureStateDir(nested)
		assert.NoError(t, err)

		stateDir := filepath.Join(nested, ".stackkit")
		info, err := os.Stat(stateDir)
		assert.NoError(t, err)
		assert.True(t, info.IsDir())
	})
}

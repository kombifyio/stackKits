package commands

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kombifyio/stackkits/pkg/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"
)

// executeCommand runs the root command with the given args and captures
// cobra-buffered output. Commands that write directly to os.Stdout (e.g.
// version, completion) won't appear in the returned string; use
// executeCommandCaptureStdout for those.
func executeCommand(args ...string) (string, error) {
	buf := new(bytes.Buffer)
	rootCmd.SetOut(buf)
	rootCmd.SetErr(buf)
	rootCmd.SetArgs(args)
	err := rootCmd.Execute()
	return buf.String(), err
}

// executeCommandCaptureStdout redirects os.Stdout so that commands using
// fmt.Printf / os.Stdout writes are captured. A goroutine drains the pipe
// concurrently to avoid blocking on Windows when output is large.
func executeCommandCaptureStdout(args ...string) (string, error) {
	r, w, err := os.Pipe()
	if err != nil {
		return "", err
	}

	var buf bytes.Buffer
	done := make(chan struct{})
	go func() {
		_, _ = buf.ReadFrom(r)
		close(done)
	}()

	orig := os.Stdout
	os.Stdout = w

	rootCmd.SetArgs(args)
	execErr := rootCmd.Execute()

	_ = w.Close()
	os.Stdout = orig
	<-done
	_ = r.Close()

	return buf.String(), execErr
}

func TestRootCommand_SubcommandsRegistered(t *testing.T) {
	expected := []string{
		"init", "prepare", "generate", "validate",
		"plan", "apply", "destroy", "status",
		"version", "completion",
	}

	registered := make(map[string]bool)
	for _, cmd := range rootCmd.Commands() {
		registered[cmd.Name()] = true
	}

	for _, name := range expected {
		assert.True(t, registered[name], "subcommand %q should be registered", name)
	}
}

func TestRootCommand_GlobalFlags(t *testing.T) {
	tests := []struct {
		flag      string
		shorthand string
	}{
		{"verbose", "v"},
		{"quiet", "q"},
		{"chdir", "C"},
		{"spec", "s"},
	}

	for _, tt := range tests {
		t.Run(tt.flag, func(t *testing.T) {
			f := rootCmd.PersistentFlags().Lookup(tt.flag)
			require.NotNil(t, f, "flag --%s should exist", tt.flag)
			assert.Equal(t, tt.shorthand, f.Shorthand, "shorthand for --%s", tt.flag)
		})
	}
}

func TestVersionCommand(t *testing.T) {
	out, err := executeCommandCaptureStdout("version")
	require.NoError(t, err)
	assert.Contains(t, out, "stackkit version")
	assert.Contains(t, out, "Git commit:")
	assert.Contains(t, out, "Build date:")
	assert.Contains(t, out, "Go version:")
	assert.Contains(t, out, "OS/Arch:")
}

func TestInitCommand_NonInteractive_MissingName(t *testing.T) {
	tmpDir := t.TempDir()

	_, err := executeCommand("init", "--non-interactive", "--chdir", tmpDir)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "non-interactive")
}

func TestValidateCommand_NoSpecFile(t *testing.T) {
	tmpDir := t.TempDir()

	// validate returns an error when the spec file cannot be loaded (the
	// loader wraps the underlying error so os.IsNotExist does not match).
	_, err := executeCommand("validate", "--spec", filepath.Join(tmpDir, "nonexistent.yaml"), "--chdir", tmpDir)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "validation failed")
}

func TestPlanCommand_NoSpecFile(t *testing.T) {
	tmpDir := t.TempDir()

	_, err := executeCommand("plan", "--spec", filepath.Join(tmpDir, "nonexistent.yaml"), "--chdir", tmpDir)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to load spec")
}

func TestApplyCommand_NoSpecFile(t *testing.T) {
	tmpDir := t.TempDir()

	_, err := executeCommand("apply", "--spec", filepath.Join(tmpDir, "nonexistent.yaml"), "--chdir", tmpDir)
	require.Error(t, err)
	// apply now attempts auto-init when spec is missing
	assert.True(t,
		strings.Contains(err.Error(), "failed to load spec") || strings.Contains(err.Error(), "no spec file"),
		"unexpected error: %s", err.Error())
}

func TestDestroyCommand_NoDeployDir(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a minimal spec so the loader doesn't fail before the deploy-dir check.
	specPath := filepath.Join(tmpDir, "stack-spec.yaml")
	specContent := `name: test
stackkit: test-kit
variant: default
mode: simple
`
	require.NoError(t, os.WriteFile(specPath, []byte(specContent), 0600))

	_, err := executeCommand("destroy", "--auto-approve", "--spec", specPath, "--chdir", tmpDir)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "nothing to destroy")
}

func TestCompletionCommand_RequiresShellArg(t *testing.T) {
	_, err := executeCommand("completion")
	require.Error(t, err)
}

func TestCompletionCommand_ValidShells(t *testing.T) {
	shells := []string{"bash", "zsh", "fish", "powershell"}
	for _, shell := range shells {
		t.Run(shell, func(t *testing.T) {
			// Completion writes directly to os.Stdout. Drain the pipe
			// in a goroutine to prevent blocking on Windows when the
			// output exceeds the OS pipe buffer.
			r, w, err := os.Pipe()
			require.NoError(t, err)

			var buf bytes.Buffer
			done := make(chan struct{})
			go func() {
				_, _ = buf.ReadFrom(r)
				close(done)
			}()

			orig := os.Stdout
			os.Stdout = w

			rootCmd.SetArgs([]string{"completion", shell})
			execErr := rootCmd.Execute()

			_ = w.Close()
			os.Stdout = orig
			<-done
			_ = r.Close()

			assert.NoError(t, execErr)
			assert.Greater(t, buf.Len(), 0, "completion output should not be empty")
		})
	}
}

func TestStatusCommand_NoSpecFile(t *testing.T) {
	tmpDir := t.TempDir()

	_, err := executeCommand("status", "--spec", filepath.Join(tmpDir, "nonexistent.yaml"), "--chdir", tmpDir)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "failed to load spec")
}

func TestGenerateRandomPassword(t *testing.T) {
	pw, err := generateRandomPassword(16)
	require.NoError(t, err)
	assert.Len(t, pw, 16)

	// Should be alphanumeric only
	for _, c := range pw {
		assert.True(t, (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'),
			"unexpected character %q in password", c)
	}

	// Two passwords should differ (probabilistic but virtually certain for 16 chars)
	pw2, err := generateRandomPassword(16)
	require.NoError(t, err)
	assert.NotEqual(t, pw, pw2)
}

func TestBcryptHash(t *testing.T) {
	password := "testpassword123"
	hash, err := bcryptHash(password)
	require.NoError(t, err)
	assert.True(t, strings.HasPrefix(hash, "$2a$"), "hash should be bcrypt format")

	// Verify the hash matches the password
	err = bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	assert.NoError(t, err)

	// Wrong password should not match
	err = bcrypt.CompareHashAndPassword([]byte(hash), []byte("wrong"))
	assert.Error(t, err)
}

func TestGenerateTfvarsJSON_AdminEmail(t *testing.T) {
	spec := &models.StackSpec{
		Name:       "test-homelab",
		AdminEmail: "test@example.com",
		Domain:     "home.example.com",
	}

	data := generateTfvarsJSON(spec)

	var vars map[string]interface{}
	err := json.Unmarshal(data, &vars)
	require.NoError(t, err)

	assert.Equal(t, "test@example.com", vars["admin_email"])
	assert.Equal(t, true, vars["enable_dashboard"])

	// tinyauth_users should be email:bcrypt_hash
	users, ok := vars["tinyauth_users"].(string)
	require.True(t, ok)
	assert.True(t, strings.HasPrefix(users, "test@example.com:$2a$"),
		"tinyauth_users should be email:bcrypt, got: %s", users)

	// admin_password_plaintext should be present and 16 chars
	pw, ok := vars["admin_password_plaintext"].(string)
	require.True(t, ok)
	assert.Len(t, pw, 16)
}

func TestGenerateTfvarsJSON_FallbackAdmin(t *testing.T) {
	spec := &models.StackSpec{
		Name: "test-homelab",
	}

	data := generateTfvarsJSON(spec)

	var vars map[string]interface{}
	err := json.Unmarshal(data, &vars)
	require.NoError(t, err)

	// Without adminEmail, should fall back to "admin"
	assert.Equal(t, "admin", vars["admin_email"])

	users, ok := vars["tinyauth_users"].(string)
	require.True(t, ok)
	assert.True(t, strings.HasPrefix(users, "admin:$2a$"),
		"tinyauth_users should use 'admin' fallback, got: %s", users)
}

func TestInitCommand_AdminEmailFlag(t *testing.T) {
	f := initCmd.Flags().Lookup("admin-email")
	require.NotNil(t, f, "--admin-email flag should exist")
	assert.Equal(t, "", f.DefValue)
}

//go:build production

package production

import (
	"fmt"
	"io"
	"net"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/ssh"
)

// SSHSession wraps an active SSH connection to a Sim node.
type SSHSession struct {
	client *ssh.Client
	node   Node
}

// NewSSHSession dials the node and returns an authenticated SSH session.
// It tries key-based auth first (using node.SSHKeyPath), then falls back
// to the KOMBIFY_SSH_KEY_PATH env var.
func NewSSHSession(node Node) (*SSHSession, error) {
	keyPath := node.SSHKeyPath
	if keyPath == "" {
		keyPath = os.Getenv("KOMBIFY_SSH_KEY_PATH")
	}
	if keyPath == "" {
		return nil, fmt.Errorf("no SSH key path: set node.SSHKeyPath or KOMBIFY_SSH_KEY_PATH")
	}

	keyBytes, err := os.ReadFile(keyPath)
	if err != nil {
		return nil, fmt.Errorf("read SSH key %s: %w", keyPath, err)
	}

	signer, err := ssh.ParsePrivateKey(keyBytes)
	if err != nil {
		return nil, fmt.Errorf("parse SSH key: %w", err)
	}

	user := node.SSHUser
	if user == "" {
		user = "root"
	}

	cfg := &ssh.ClientConfig{
		User:            user,
		Auth:            []ssh.AuthMethod{ssh.PublicKeys(signer)},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), //nolint:gosec // test helper — not production auth
		Timeout:         15 * time.Second,
	}

	addr := net.JoinHostPort(node.SSHIP, fmt.Sprintf("%d", node.SSHPort))
	client, err := ssh.Dial("tcp", addr, cfg)
	if err != nil {
		return nil, fmt.Errorf("SSH dial %s: %w", addr, err)
	}

	return &SSHSession{client: client, node: node}, nil
}

// Close closes the SSH connection.
func (s *SSHSession) Close() error {
	return s.client.Close()
}

// Run executes a shell command on the remote node and returns combined output.
// Returns an error if the command exits non-zero.
func (s *SSHSession) Run(cmd string) (string, error) {
	sess, err := s.client.NewSession()
	if err != nil {
		return "", fmt.Errorf("new SSH session: %w", err)
	}
	defer sess.Close()

	var buf strings.Builder
	sess.Stdout = &buf
	sess.Stderr = &buf

	if err := sess.Run(cmd); err != nil {
		return buf.String(), fmt.Errorf("command %q: %w\noutput: %s", cmd, err, buf.String())
	}
	return buf.String(), nil
}

// RunWithEnv executes a shell command with additional environment variables.
func (s *SSHSession) RunWithEnv(env map[string]string, cmd string) (string, error) {
	var exports strings.Builder
	for k, v := range env {
		exports.WriteString(fmt.Sprintf("export %s=%q; ", k, v))
	}
	return s.Run(exports.String() + cmd)
}

// Upload copies a local file to a remote path via SCP-over-SSH.
func (s *SSHSession) Upload(localPath, remotePath string) error {
	f, err := os.Open(localPath)
	if err != nil {
		return fmt.Errorf("open %s: %w", localPath, err)
	}
	defer f.Close()

	stat, err := f.Stat()
	if err != nil {
		return fmt.Errorf("stat %s: %w", localPath, err)
	}

	sess, err := s.client.NewSession()
	if err != nil {
		return fmt.Errorf("new SSH session: %w", err)
	}
	defer sess.Close()

	w, err := sess.StdinPipe()
	if err != nil {
		return fmt.Errorf("stdin pipe: %w", err)
	}

	if err := sess.Start(fmt.Sprintf("cat > %s", remotePath)); err != nil {
		return fmt.Errorf("start remote cat: %w", err)
	}

	if _, err := fmt.Fprintf(w, "C0644 %d %s\n", stat.Size(), remotePath[strings.LastIndex(remotePath, "/")+1:]); err != nil {
		return err
	}
	if _, err := io.Copy(w, f); err != nil {
		return err
	}
	if _, err := fmt.Fprint(w, "\x00"); err != nil {
		return err
	}
	w.Close()

	return sess.Wait()
}

// UploadBytes writes byte content to a remote path.
func (s *SSHSession) UploadBytes(content []byte, remotePath string) error {
	sess, err := s.client.NewSession()
	if err != nil {
		return fmt.Errorf("new SSH session: %w", err)
	}
	defer sess.Close()

	w, err := sess.StdinPipe()
	if err != nil {
		return fmt.Errorf("stdin pipe: %w", err)
	}

	if err := sess.Start(fmt.Sprintf("cat > %s && chmod +x %s", remotePath, remotePath)); err != nil {
		return fmt.Errorf("start remote write: %w", err)
	}

	if _, err := w.Write(content); err != nil {
		return err
	}
	w.Close()

	return sess.Wait()
}

// WaitForSSH polls until SSH is reachable or timeout expires.
// Use this after StartNode to wait for sshd to be ready.
func WaitForSSH(node Node, timeout time.Duration) error {
	addr := net.JoinHostPort(node.SSHIP, fmt.Sprintf("%d", node.SSHPort))
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		conn, err := net.DialTimeout("tcp", addr, 3*time.Second)
		if err == nil {
			conn.Close()
			return nil
		}
		time.Sleep(5 * time.Second)
	}
	return fmt.Errorf("SSH not reachable at %s after %s", addr, timeout)
}

package hostconformance

import (
	"context"
	"errors"
	"fmt"
	"os"
)

// ProbeError retains the private cause while exposing only a fixed probe stage
// and an error category. Command output and host file contents stay private.
type ProbeError struct {
	stage string
	cause error
}

func (e *ProbeError) Error() string { return fmt.Sprintf("%s: %v", e.stage, e.cause) }
func (e *ProbeError) Unwrap() error { return e.cause }

func (e *ProbeError) Diagnostic() string {
	reason := "failed"
	switch {
	case errors.Is(e.cause, context.DeadlineExceeded):
		reason = "timeout"
	case errors.Is(e.cause, context.Canceled):
		reason = "canceled"
	case errors.Is(e.cause, os.ErrNotExist):
		reason = "not_found"
	case errors.Is(e.cause, os.ErrPermission):
		reason = "permission_denied"
	}
	return e.stage + " (" + reason + ")"
}

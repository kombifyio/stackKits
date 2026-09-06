package localevidence

import "errors"

// DiagnosticError preserves an observation failure without publishing its
// cause. Stages are assigned only by the construction-owned collector.
type DiagnosticError struct {
	stage string
	cause error
}

func (e *DiagnosticError) Error() string { return e.cause.Error() }
func (e *DiagnosticError) Unwrap() error { return e.cause }
func (e *DiagnosticError) Diagnostic() string {
	var nested *DiagnosticError
	if errors.As(e.cause, &nested) {
		return e.stage + ": " + nested.Diagnostic()
	}
	return e.stage
}

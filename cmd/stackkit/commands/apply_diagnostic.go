package commands

import (
	"context"
	"errors"

	"github.com/kombifyio/stackkits/internal/architecturev2"
	"github.com/kombifyio/stackkits/internal/hostconformance"
	"github.com/kombifyio/stackkits/internal/localevidence"
)

// Only construction-owned diagnostics cross this boundary. Arbitrary wrapped
// error text can contain credentials and must never be printed here.
func localApplyDiagnostic(err error) string {
	var resolution *architecturev2.ResolveError
	if !errors.As(err, &resolution) || resolution.Code != architecturev2.ErrApplyAuthorization {
		return ""
	}
	var probe *hostconformance.ProbeError
	if errors.As(resolution.Cause, &probe) {
		return probe.Diagnostic()
	}
	var observation *localevidence.DiagnosticError
	if errors.As(resolution.Cause, &observation) {
		return observation.Diagnostic()
	}
	if errors.Is(resolution.Cause, context.DeadlineExceeded) {
		return "Apply evidence context timed out"
	}
	if errors.Is(resolution.Cause, context.Canceled) {
		return "Apply evidence context canceled"
	}
	return ""
}

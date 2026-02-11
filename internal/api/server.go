// Package api provides the HTTP API server for kombify StackKits.
package api

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ServerConfig holds configuration for the API server.
type ServerConfig struct {
	Port    int
	BaseDir string
	Version string
}

// Server is the StackKits HTTP API server.
type Server struct {
	config ServerConfig
	mux    *http.ServeMux
}

// NewServer creates a new API server.
func NewServer(cfg ServerConfig) *Server {
	s := &Server{
		config: cfg,
		mux:    http.NewServeMux(),
	}
	s.routes()
	return s
}

// Handler returns the HTTP handler with middleware applied.
func (s *Server) Handler() http.Handler {
	var handler http.Handler = s.mux
	handler = requestIDMiddleware(handler)
	handler = corsMiddleware(handler)
	handler = loggingMiddleware(handler)
	handler = recoveryMiddleware(handler)
	return handler
}

func (s *Server) routes() {
	// Health & discovery
	s.mux.HandleFunc("GET /health", s.handleHealth)
	s.mux.HandleFunc("GET /api/v1/health", s.handleHealth)
	s.mux.HandleFunc("GET /api/v1/capabilities", s.handleCapabilities)
	s.mux.HandleFunc("GET /api/v1/openapi.yaml", s.handleOpenAPISpec)

	// StackKit catalog
	s.mux.HandleFunc("GET /api/v1/stackkits", s.handleListStackKits)
	s.mux.HandleFunc("GET /api/v1/stackkits/{name}", s.handleGetStackKit)
	s.mux.HandleFunc("GET /api/v1/stackkits/{name}/schema", s.handleGetStackKitSchema)
	s.mux.HandleFunc("GET /api/v1/stackkits/{name}/defaults", s.handleGetStackKitDefaults)
	s.mux.HandleFunc("GET /api/v1/stackkits/{name}/variants", s.handleGetStackKitVariants)

	// Validation
	s.mux.HandleFunc("POST /api/v1/validate", s.handleValidateSpec)
	s.mux.HandleFunc("POST /api/v1/validate/partial", s.handleValidatePartial)

	// Generation
	s.mux.HandleFunc("POST /api/v1/generate/tfvars", s.handleGenerateTFVars)
	s.mux.HandleFunc("POST /api/v1/generate/preview", s.handleGeneratePreview)
}

// ── Response helpers ──────────────────────────────────────────────

// ResponseMeta contains request tracking metadata.
type ResponseMeta struct {
	RequestID string `json:"request_id,omitempty"`
	Timestamp string `json:"timestamp,omitempty"`
}

type successResponse struct {
	Data interface{}   `json:"data"`
	Meta *ResponseMeta `json:"meta,omitempty"`
}

type errorDetail struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

type errorResponse struct {
	Error errorDetail   `json:"error"`
	Meta  *ResponseMeta `json:"meta,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeSuccess(w http.ResponseWriter, r *http.Request, status int, data interface{}) {
	writeJSON(w, status, successResponse{
		Data: data,
		Meta: metaFromRequest(r),
	})
}

func writeError(w http.ResponseWriter, r *http.Request, status int, message string) {
	if status >= http.StatusInternalServerError {
		message = "internal error"
	}
	writeJSON(w, status, errorResponse{
		Error: errorDetail{Code: status, Message: message},
		Meta:  metaFromRequest(r),
	})
}

func metaFromRequest(r *http.Request) *ResponseMeta {
	rid := ""
	if r != nil {
		rid = r.Header.Get("X-Request-ID")
	}
	return &ResponseMeta{
		RequestID: rid,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}
}

// ── Middleware ─────────────────────────────────────────────────────

type contextKey string

const requestIDKey contextKey = "request_id"

func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rid := strings.TrimSpace(r.Header.Get("X-Request-ID"))
		if rid == "" {
			rid = uuid.NewString()
		} else if len(rid) > 128 {
			rid = rid[:128]
		}
		r.Header.Set("X-Request-ID", rid)
		w.Header().Set("X-Request-ID", rid)
		ctx := context.WithValue(r.Context(), requestIDKey, rid)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Request-ID, X-API-Key, X-User-ID, X-Org-ID")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		slog.Info("request",
			"method", r.Method,
			"path", r.URL.Path,
			"duration_ms", time.Since(start).Milliseconds(),
			"request_id", r.Header.Get("X-Request-ID"),
		)
	})
}

func recoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				slog.Error("panic recovered", "error", err, "path", r.URL.Path)
				writeError(w, r, http.StatusInternalServerError, "internal error")
			}
		}()
		next.ServeHTTP(w, r)
	})
}

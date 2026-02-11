// Package main provides the HTTP API server for kombify StackKits.
//
// This is a lightweight REST API that wraps the existing CLI logic,
// making StackKits functionality available to:
//   - kombify Stack (via internal calls or Kong Gateway)
//   - kombify API Gateway (Kong) for external consumers
//   - AI agents and native client apps
//
// Usage:
//
//	stackkit-server                          # default :8082
//	stackkit-server --port 9090             # custom port
//	stackkit-server --base-dir /stackkits   # custom StackKit directory
package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/kombihq/stackkits/internal/api"
)

// Version is set at build time via ldflags.
var Version = "dev"

func main() {
	port := flag.Int("port", 8082, "HTTP server port")
	baseDir := flag.String("base-dir", "", "Base directory for StackKit definitions (default: executable directory)")
	apiKey := flag.String("api-key", "", "API key for authentication (or set STACKKITS_API_KEY env var)")
	logLevel := flag.String("log-level", "info", "Log level: debug, info, warn, error")
	flag.Parse()

	// Configure structured logging
	var level slog.Level
	switch *logLevel {
	case "debug":
		level = slog.LevelDebug
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	default:
		level = slog.LevelInfo
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level}))
	slog.SetDefault(logger)

	// Resolve base directory
	dir := *baseDir
	if dir == "" {
		// Default: directory containing the executable
		exe, err := os.Executable()
		if err != nil {
			slog.Error("failed to get executable path", "error", err)
			os.Exit(1)
		}
		dir = filepath.Dir(exe)
	}

	// Also check environment variable
	if envDir := os.Getenv("STACKKITS_BASE_DIR"); envDir != "" {
		dir = envDir
	}

	// Resolve API key from flag or environment
	key := *apiKey
	if key == "" {
		key = os.Getenv("STACKKITS_API_KEY")
	}
	if key != "" {
		slog.Info("API key authentication enabled")
	} else {
		slog.Warn("no API key configured — all endpoints are unauthenticated")
	}

	slog.Info("starting kombify StackKits API server",
		"version", Version,
		"port", *port,
		"base_dir", dir,
	)

	srv := api.NewServer(api.ServerConfig{
		Port:    *port,
		BaseDir: dir,
		Version: Version,
		APIKey:  key,
	})

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", *port),
		Handler:      srv.Handler(),
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Graceful shutdown
	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGTERM)

	go func() {
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server failed", "error", err)
			os.Exit(1)
		}
	}()

	slog.Info("server listening", "addr", httpServer.Addr)

	<-done
	slog.Info("shutting down...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(ctx); err != nil {
		slog.Error("shutdown error", "error", err)
	}

	slog.Info("server stopped")
}

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
	"strconv"
	"strings"
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
	corsOrigins := flag.String("cors-origins", "", "Comma-separated allowed CORS origins (or set STACKKITS_CORS_ORIGINS; empty = *)")
	rateLimit := flag.Int("rate-limit", 60, "Max requests per IP per minute; 0 = no limit (or set STACKKITS_RATE_LIMIT)")
	logLevel := flag.String("log-level", "info", "Log level: debug, info, warn, error")
	flag.Parse()

	setupLogging(*logLevel)

	cfg := resolveConfig(*port, *baseDir, *apiKey, *corsOrigins, *rateLimit)

	slog.Info("starting kombify StackKits API server",
		"version", Version,
		"port", cfg.Port,
		"base_dir", cfg.BaseDir,
	)

	srv := api.NewServer(cfg)

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      srv.Handler(),
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	runServer(httpServer)
}

func setupLogging(logLevel string) {
	var level slog.Level
	switch logLevel {
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
}

func resolveConfig(port int, baseDir, apiKey, corsOrigins string, rateLimit int) api.ServerConfig {
	dir := resolveBaseDir(baseDir)
	key := resolveAPIKey(apiKey)
	origins := resolveCORSOrigins(corsOrigins)
	rl := resolveRateLimit(rateLimit)

	return api.ServerConfig{
		Port:        port,
		BaseDir:     dir,
		Version:     Version,
		APIKey:      key,
		CORSOrigins: origins,
		RateLimit:   rl,
	}
}

func resolveBaseDir(flagVal string) string {
	dir := flagVal
	if dir == "" {
		exe, err := os.Executable()
		if err != nil {
			slog.Error("failed to get executable path", "error", err)
			os.Exit(1)
		}
		dir = filepath.Dir(exe)
	}
	if envDir := os.Getenv("STACKKITS_BASE_DIR"); envDir != "" {
		dir = envDir
	}
	return dir
}

func resolveAPIKey(flagVal string) string {
	key := flagVal
	if key == "" {
		key = os.Getenv("STACKKITS_API_KEY")
	}
	if key != "" {
		slog.Info("API key authentication enabled")
	} else {
		slog.Warn("no API key configured — all endpoints are unauthenticated")
	}
	return key
}

func resolveCORSOrigins(flagVal string) []string {
	corsStr := flagVal
	if corsStr == "" {
		corsStr = os.Getenv("STACKKITS_CORS_ORIGINS")
	}
	if corsStr == "" {
		return nil
	}
	var origins []string
	for _, o := range strings.Split(corsStr, ",") {
		if trimmed := strings.TrimSpace(o); trimmed != "" {
			origins = append(origins, trimmed)
		}
	}
	slog.Info("CORS restricted", "origins", origins)
	return origins
}

func resolveRateLimit(flagVal int) int {
	rl := flagVal
	if envRL := os.Getenv("STACKKITS_RATE_LIMIT"); envRL != "" {
		if v, err := strconv.Atoi(envRL); err == nil {
			rl = v
		}
	}
	if rl > 0 {
		slog.Info("rate limiting enabled", "max_per_minute", rl)
	}
	return rl
}

func runServer(httpServer *http.Server) {
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

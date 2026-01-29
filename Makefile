# StackKits CLI Makefile

# Variables
BINARY_NAME=stackkit
VERSION?=dev
GIT_COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -X main.BuildDate=$(BUILD_DATE)"

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOFMT=$(GOCMD) fmt

# Directories
CMD_DIR=./cmd/stackkit
BUILD_DIR=./build
COVERAGE_DIR=./coverage

.PHONY: all build clean test test-unit test-integration test-coverage lint fmt deps help

# Default target
all: deps lint test build

# Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(CMD_DIR)

# Build for multiple platforms
build-all: build-linux build-darwin build-windows

build-linux:
	@echo "Building for Linux..."
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 $(CMD_DIR)
	GOOS=linux GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 $(CMD_DIR)

build-darwin:
	@echo "Building for macOS..."
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 $(CMD_DIR)
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 $(CMD_DIR)

build-windows:
	@echo "Building for Windows..."
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe $(CMD_DIR)

# Install locally
install: build
	@echo "Installing $(BINARY_NAME)..."
	cp $(BUILD_DIR)/$(BINARY_NAME) $(GOPATH)/bin/

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -rf $(COVERAGE_DIR)
	$(GOCMD) clean

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Run all tests
test: test-unit test-integration test-cue

# Run unit tests
test-unit:
	@echo "Running unit tests..."
	$(GOTEST) -v -race -short ./pkg/... ./internal/...

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	$(GOTEST) -v -race ./tests/integration/...

# Run CUE validation tests
test-cue:
	@echo "Running CUE validation tests..."
	cue vet ./base/...
	cue vet ./base-homelab/...
	cue vet ./dev-homelab/...
	cue vet ./modern-homelab/...
	@echo "✓ All CUE schemas valid"

# Run base-homelab tests
test-base-homelab:
	@echo "Running base-homelab tests..."
	cd base-homelab && ./tests/run_tests.sh

# Run dev-homelab tests (quick validation)
test-dev-homelab:
	@echo "Running dev-homelab validation..."
	cue vet ./dev-homelab/...
	@echo "✓ dev-homelab schemas valid"

# Run dev-homelab e2e (requires Docker and CLI)
test-e2e-dev-homelab:
	@echo "Running dev-homelab E2E tests..."
	cd dev-homelab && ./tests/e2e_test.sh

# Run base-homelab e2e (requires Docker)
test-e2e-base-homelab:
	@echo "Running base-homelab E2E tests..."
	@echo "TODO: Implement E2E tests for base-homelab"

# Run full e2e suite
test-e2e: test-e2e-dev-homelab test-e2e-base-homelab

# Run full validation suite (3-layer architecture)
test-validation:
	@echo "Running 3-layer validation tests..."
	./tests/run_validation.sh

# Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	@mkdir -p $(COVERAGE_DIR)
	$(GOTEST) -v -race -coverprofile=$(COVERAGE_DIR)/coverage.out -covermode=atomic ./pkg/... ./internal/...
	$(GOCMD) tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	$(GOCMD) tool cover -func=$(COVERAGE_DIR)/coverage.out | tail -1
	@echo "Coverage report: $(COVERAGE_DIR)/coverage.html"

# Run linter
lint:
	@echo "Running linter..."
	@which golangci-lint > /dev/null || (echo "Installing golangci-lint..." && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	golangci-lint run ./...

# Format code
fmt:
	@echo "Formatting code..."
	$(GOFMT) ./...

# Validate CUE schemas
validate-cue:
	@echo "Validating CUE schemas..."
	cue vet ./base/...
	cue vet ./base-homelab/...
	cue vet ./modern-homelab/...

# Run the CLI in development mode
run:
	$(GOCMD) run $(CMD_DIR) $(ARGS)

# Generate documentation
docs:
	@echo "Generating documentation..."
	$(GOCMD) doc -all ./pkg/models > docs/api-models.md
	$(GOCMD) doc -all ./internal/config > docs/api-config.md

# Development helpers
dev-setup:
	@echo "Setting up development environment..."
	$(GOGET) github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(GOGET) github.com/stretchr/testify
	$(GOMOD) tidy

# Show help
help:
	@echo "StackKits CLI Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Build Targets:"
	@echo "  build           Build the CLI binary"
	@echo "  build-all       Build for all platforms"
	@echo "  install         Install CLI to GOPATH/bin"
	@echo "  clean           Remove build artifacts"
	@echo "  deps            Download dependencies"
	@echo ""
	@echo "Test Targets:"
	@echo "  test            Run all tests (unit + integration + cue)"
	@echo "  test-unit       Run Go unit tests"
	@echo "  test-integration Run Go integration tests"
	@echo "  test-cue        Run CUE schema validation"
	@echo "  test-coverage   Run tests with coverage report"
	@echo "  test-validation Run 3-layer validation suite"
	@echo ""
	@echo "StackKit-Specific Tests:"
	@echo "  test-base-homelab     Run base-homelab schema tests"
	@echo "  test-dev-homelab      Run dev-homelab validation"
	@echo "  test-e2e-dev-homelab  Run dev-homelab E2E (requires Docker)"
	@echo "  test-e2e-base-homelab Run base-homelab E2E (requires Docker)"
	@echo "  test-e2e              Run full E2E suite"
	@echo ""
	@echo "Other Targets:"
	@echo "  lint            Run golangci-lint"
	@echo "  fmt             Format code with go fmt"
	@echo "  validate-cue    Validate CUE schemas (legacy, use test-cue)"
	@echo "  run ARGS=...    Run CLI in development mode"
	@echo "  docs            Generate documentation"
	@echo "  dev-setup       Install development tools"
	@echo "  help            Show this help"

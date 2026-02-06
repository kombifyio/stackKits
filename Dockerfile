# =============================================================================
# StackKit CLI Docker Image
# =============================================================================
# Multi-stage build with OpenTofu and Go CLI
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build the StackKit CLI
# -----------------------------------------------------------------------------
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

WORKDIR /build

# Copy go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the CLI
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /build/stackkit ./cmd/stackkit

# -----------------------------------------------------------------------------
# Stage 2: Install OpenTofu
# -----------------------------------------------------------------------------
FROM alpine:3.20 AS tofu-installer

RUN apk add --no-cache curl bash gnupg

# Install OpenTofu (latest stable)
RUN curl -fsSL https://get.opentofu.org/install-opentofu.sh | bash -s -- --install-method standalone

# -----------------------------------------------------------------------------
# Stage 3: Final Runtime Image
# -----------------------------------------------------------------------------
FROM alpine:3.20

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    jq \
    bash \
    git \
    openssh-client

# Install Docker CLI
RUN apk add --no-cache docker-cli

# Copy OpenTofu binary
COPY --from=tofu-installer /usr/local/bin/tofu /usr/local/bin/tofu

# Copy StackKit CLI binary
COPY --from=builder /build/stackkit /usr/local/bin/stackkit

# Ensure binaries are executable
RUN chmod +x /usr/local/bin/tofu /usr/local/bin/stackkit

# Create workspace directory
WORKDIR /workspace

# Set environment variables
ENV DOCKER_HOST=tcp://vm:2375
ENV STACKKIT_BIN=stackkit

# Verify installations
RUN tofu version && stackkit --help

# Default command
CMD ["stackkit", "--help"]

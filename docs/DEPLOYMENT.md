# Deployment — kombify StackKits

## Environments

| Environment | Method | Notes |
|------------|--------|-------|
| Production | Azure Container App | CI/CD from `main` |
| Local | Docker Compose | `docker compose up -d` |
| Binary | Go binary | `make build` |

## Docker deployment

```bash
# Build and run
docker compose up -d --build

# Verify
curl -s http://localhost:5280/api/v1/health
```

## Binary deployment

```bash
make build
./bin/stackkits
```

## Azure deployment

See [AZURE_WEBSITE_DEPLOYMENT.md](AZURE_WEBSITE_DEPLOYMENT.md) for Azure-specific instructions.

## Configuration

See [CONFIGURATION.md](CONFIGURATION.md) for environment variables.

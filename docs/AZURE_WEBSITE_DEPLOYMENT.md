# StackKits Website - Azure Deployment

**Status:** Deployed (28.01.2026)

The StackKits website is deployed as an Azure Container App with Azure Front Door for CDN and SSL termination.

## Architektur

```
Azure Front Door
    │
    └── stackkits.kombify.io
            │
            ▼
    Azure Container Apps
    ca-stackkits-web-prod
            │
            └── Port 3000 (Docusaurus)
```

## Ressourcen

| Ressource | Name |
|-----------|------|
| Container App | `ca-stackkits-web-prod` |
| Container Registry | `acrkombifyprod.azurecr.io` |
| Image | `stackkits-web:latest` |
| Custom Domain | `stackkits.kombify.io` |

## Deployment

### GitHub Actions

Der Workflow `.github/workflows/deploy-website.yml` deployt bei Push auf `main`:

```yaml
name: Deploy Website

on:
  push:
    branches: [main]
    paths:
      - 'website/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: ACR Login
        run: az acr login --name acrkombifyprod
      
      - name: Build and Push
        working-directory: website
        run: |
          docker build -t acrkombifyprod.azurecr.io/stackkits-web:${{ github.sha }} .
          docker push acrkombifyprod.azurecr.io/stackkits-web:${{ github.sha }}
      
      - name: Deploy
        run: |
          az containerapp update \
            --name ca-stackkits-web-prod \
            --resource-group rg-kombify-prod \
            --image acrkombifyprod.azurecr.io/stackkits-web:${{ github.sha }}
```

### Manuelles Deployment

```bash
cd website

# Azure Login
az login
az acr login --name acrkombifyprod

# Build
docker build -t acrkombifyprod.azurecr.io/stackkits-web:latest .

# Push
docker push acrkombifyprod.azurecr.io/stackkits-web:latest

# Deploy
az containerapp update \
  --name ca-stackkits-web-prod \
  --resource-group rg-kombify-prod \
  --image acrkombifyprod.azurecr.io/stackkits-web:latest
```

## Lokale Entwicklung

```bash
cd website
bun install
bun run dev    # http://localhost:3000
```

## Verifikation

```bash
# Health Check
curl -s https://stackkits.kombify.io/

# Container Logs
az containerapp logs show \
  --name ca-stackkits-web-prod \
  --resource-group rg-kombify-prod \
  --follow
```

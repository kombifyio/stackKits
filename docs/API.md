# API Reference — kombify StackKits

## Base URL

- **Production**: `api.kombify.io/api/v1/stackkits`
- **Local**: `http://localhost:5280/api/v1`

## Endpoints

### Health

```
GET /api/v1/health
→ {"status": "ok"}
```

### List StackKits

```
GET /api/v1/stackkits
→ [{"id": "base-homelab", "name": "Base Homelab", ...}]
```

### Validate spec

```
POST /api/v1/validate
Content-Type: application/json

{"spec": { ... kombination.yaml content ... }}

→ {"valid": true, "errors": [], "warnings": []}
```

## Error format

```json
{
  "error": {
    "code": 400,
    "message": "Validation failed: node count must be >= 1"
  }
}
```

See also: [CLI.md](CLI.md) for CLI usage.

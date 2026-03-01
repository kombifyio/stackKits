# Testing — kombify StackKits

## Test types

| Type | Command | Description |
|------|---------|-------------|
| Unit tests | `make test` | All Go tests |
| CUE validation | `cue vet ./...` | Schema validation |
| Docker build | `docker build .` | Build verification |

## Running tests

```bash
# All tests
make test

# CUE schema validation
cue vet ./...

# Specific package
go test ./pkg/...
```

## CI requirements

All PRs must pass:
- `gofmt` — code formatting
- `go vet` — static analysis
- `cue vet` — CUE schema validation
- Unit tests
- Docker build

## Writing tests

- Test CUE schemas with valid and invalid input fixtures
- Test Go logic with table-driven tests
- Add test fixtures in `testdata/` directories

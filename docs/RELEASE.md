# Release Process

## Repository Topology

| Repo | Visibility | Purpose |
|------|-----------|---------|
| `KombiverseLabs/kombify-StackKits` | **Private** | Development — all source, CI, dev tools, internal docs |
| `kombifyio/stackKits` | **Public** | Curated user-facing repo — kits, docs, installer, releases |

The Go module path is `github.com/kombihq/stackkits` (separate from either GitHub org).

## How Releases Work

Releases are published to the **public** `kombifyio/stackKits` repo. The release workflow:

1. Tag push triggers `.github/workflows/release.yml`
2. **Test job** — runs `go test ./...`
3. **Validate archive job** — builds a snapshot, verifies required files are present (base-kit/, base/, binary)
4. **Release job** — GoReleaser builds cross-platform binaries and publishes to GitHub Releases

### Release Archives MUST Include

The release `.tar.gz` is not just a binary — it bundles everything the CLI needs:

```
stackkit                          # CLI binary
base-kit/stackkit.yaml            # Kit metadata
base-kit/services.cue             # Service definitions
base-kit/defaults.cue             # Default values
base-kit/stackfile.cue            # Main CUE definition
base-kit/default-spec.yaml        # Example spec
base-kit/templates/simple/main.tf # Deployment template
base-kit/templates/advanced/...   # Advanced mode templates
base/stackkit.cue                 # Base CUE schemas
base/layers.cue                   # Layer definitions
base/identity.cue                 # Identity schemas
base/network.cue                  # Network schemas
base/security.cue                 # Security schemas
base/...                          # Other base schemas
README.md
LICENSE
docs/CLI.md
```

These are configured in `.goreleaser.yaml` under `archives.files`. **If you add new directories needed at runtime, add them here.**

## Creating a Release

```bash
# 1. Ensure you're on main with all changes committed
git status  # clean working tree

# 2. Push to both repos
git push origin main      # private dev repo
git push public main      # public user repo

# 3. Tag and push to public repo (triggers release workflow)
git tag v0.X.Y
git push public v0.X.Y

# 4. Monitor the release
gh run list --repo kombifyio/stackKits --limit 3
gh run watch <run-id> --repo kombifyio/stackKits

# 5. Verify the release
gh release view v0.X.Y --repo kombifyio/stackKits
curl -sSL "https://github.com/kombifyio/stackKits/releases/download/v0.X.Y/stackkits_0.X.Y_linux_amd64.tar.gz" -o /tmp/verify.tar.gz
tar tzf /tmp/verify.tar.gz  # check all files are present
```

## Re-releasing a Version

If a release needs to be fixed:

```bash
# Delete the release and tag
gh release delete v0.X.Y --repo kombifyio/stackKits --yes
git push public :refs/tags/v0.X.Y
git tag -d v0.X.Y

# Fix, commit, push
git add . && git commit -m "fix: ..."
git push origin main && git push public main

# Re-tag and push
git tag v0.X.Y
git push public v0.X.Y
```

## Safeguards

### CI Validation (validate-archive job)
The release workflow includes a `validate-archive` job that:
- Builds a dry-run archive with `goreleaser --snapshot`
- Checks that all required files are present
- **Blocks the release if any required file is missing**

### E2E Install Test
Run locally before releasing:

```bash
./tests/e2e/test_install.sh          # tests latest public release
./tests/e2e/test_install.sh local    # tests local build
```

### What NOT to Do

- Never release from `KombiverseLabs/kombify-StackKits` (private) — users can't download
- Never remove `base-kit/` or `base/` from `.goreleaser.yaml` archive files
- Never force push to `kombifyio/stackKits` without checking existing releases
- Never change the Go module path without updating both repos

## Git Remote Setup

```bash
# In the local clone of KombiverseLabs/kombify-StackKits:
git remote -v
# origin    → KombiverseLabs/kombify-StackKits (private, fetch+push)
# public    → kombifyio/stackKits (public, push for releases)

# Add public remote if missing:
git remote add public https://github.com/kombifyio/stackKits.git
```

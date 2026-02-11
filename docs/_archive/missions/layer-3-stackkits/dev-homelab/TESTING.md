# dev-homelab Testing Reference

**Purpose:** dev-homelab serves as the validation scaffold for CLI/tooling changes.

---

## Role

dev-homelab is the **first validation target** for framework changes:

1. **dev-homelab** - Minimal surface, fast iteration
2. **base-homelab** - Full patterns, production validation
3. **Other stackkits** - Extended coverage

Changes to CLI, templates, or CUE schemas are validated against dev-homelab first due to its simplicity.

---

## Service Test Matrix

| Service | Port | Endpoint | Expected |
|---------|------|----------|----------|
| Whoami | 9080 | / | Hostname response |

---

## Minimal Configuration

```yaml
name: dev-homelab
version: "1.0"
layers:
  foundation: minimal
  platform: docker
services:
  utilities:
    - whoami
```

---

## Cross-References

- [TESTING-STANDARDS.md](../../TESTING-STANDARDS.md) - Framework testing standards
- [../../../dev-homelab/tests/](../../../dev-homelab/tests/) - CUE test implementations

#!/bin/bash
# CUE Schema Tests Runner
# Führt alle CUE-Validierungstests aus

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACKKIT_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$STACKKIT_DIR")"

echo "=== kombify Stack CUE Schema Tests ==="
echo "StackKit: base-kit"
echo "Root: $ROOT_DIR"
echo ""

# CUE Version prüfen
if ! command -v cue &> /dev/null; then
    echo "ERROR: CUE CLI nicht gefunden. Installation:"
    echo "  go install cuelang.org/go/cmd/cue@latest"
    exit 1
fi

echo "CUE Version: $(cue version | head -1)"
echo ""

# Wechsle zum Root-Verzeichnis
cd "$ROOT_DIR"

# 1. Module-Check
echo "--- Module Check ---"
cue mod tidy
echo "✓ Module OK"
echo ""

# 2. Schema-Validierung
echo "--- Schema Validation ---"
cue vet ./base/...
echo "✓ Base schemas valid"

cue vet ./base-kit/...
echo "✓ base-kit schemas valid"
echo ""

# 3. Test-Ausführung
echo "--- Test Execution ---"
cue eval "$STACKKIT_DIR/tests/schema_test.cue" > /dev/null 2>&1 && \
    echo "✓ schema_test.cue passed" || \
    { echo "✗ schema_test.cue FAILED"; exit 1; }
echo ""

# 4. Export-Test (JSON/YAML)
echo "--- Export Tests ---"
cue export "$STACKKIT_DIR/tests/schema_test.cue" --out json > /dev/null 2>&1 && \
    echo "✓ JSON export OK" || \
    { echo "✗ JSON export FAILED"; exit 1; }

cue export "$STACKKIT_DIR/tests/schema_test.cue" --out yaml > /dev/null 2>&1 && \
    echo "✓ YAML export OK" || \
    { echo "✗ YAML export FAILED"; exit 1; }
echo ""

# 5. Varianten-Tests
echo "--- Variant Tests ---"
for variant in "$STACKKIT_DIR/variants/os/"*.cue; do
    name=$(basename "$variant")
    cue vet "$variant" > /dev/null 2>&1 && \
        echo "✓ $name valid" || \
        { echo "✗ $name FAILED"; exit 1; }
done

for variant in "$STACKKIT_DIR/variants/compute/"*.cue; do
    name=$(basename "$variant")
    cue vet "$variant" > /dev/null 2>&1 && \
        echo "✓ $name valid" || \
        { echo "✗ $name FAILED"; exit 1; }
done
echo ""

echo "=== All Tests Passed ==="

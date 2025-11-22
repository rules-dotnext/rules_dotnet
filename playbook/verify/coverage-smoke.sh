#!/bin/bash
# Coverage Smoke Test
#
# Runs bazel coverage and verifies LCOV output exists.
#
# Usage: ./coverage-smoke.sh [TARGET_PATTERN]
#        TARGET_PATTERN defaults to //...

set -euo pipefail

TARGET="${1:-//...}"

echo "=== Coverage Smoke Test ==="
echo "Target: $TARGET"
echo ""

# Run coverage
bazel coverage "$TARGET" 2>&1 | tee /tmp/coverage-smoke.log

echo ""
echo "--- Checking for coverage data ---"

# Find coverage.dat files in bazel-testlogs
COVERAGE_FILES=$(find bazel-testlogs -name "coverage.dat" -size +0 2>/dev/null | head -20)

if [ -z "$COVERAGE_FILES" ]; then
    echo "FAIL: No coverage.dat files found in bazel-testlogs/"
    echo ""
    echo "Possible causes:"
    echo "  1. PDB files missing from runfiles (needed for instrumentation)"
    echo "  2. Coverlet extension not registered in MODULE.bazel"
    echo "  3. --incompatible_strict_action_env not set"
    echo "  4. Test targets don't have test_ prefix or _test suffix"
    exit 1
fi

echo "PASS: Coverage data found:"
echo "$COVERAGE_FILES"
echo ""

# Basic LCOV format validation
FIRST_COV=$(echo "$COVERAGE_FILES" | head -1)
if grep -q "^SF:" "$FIRST_COV"; then
    echo "LCOV format validated (contains SF: source file entries)"
    LINE_COUNT=$(grep -c "^DA:" "$FIRST_COV" || true)
    echo "Line coverage entries: $LINE_COUNT"
else
    echo "WARNING: Coverage file exists but may not be valid LCOV format"
fi

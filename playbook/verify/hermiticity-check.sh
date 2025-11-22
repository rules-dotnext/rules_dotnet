#!/bin/bash
# Hermiticity Check
#
# Verifies that build outputs don't contain host-specific paths
# or references to non-hermetic resources.
#
# Usage: ./hermiticity-check.sh [TARGET_PATTERN]
#        TARGET_PATTERN defaults to //...

set -euo pipefail

TARGET="${1:-//...}"
FAILURES=0

echo "=== Hermiticity Check ==="
echo "Target: $TARGET"
echo ""

# Build everything first
echo "--- Building all targets ---"
bazel build "$TARGET" 2>&1 | tail -5

echo ""
echo "--- Checking for host path leaks ---"

# Check for absolute host paths in generated files
# Common leak: /home/user, /Users/user, C:\Users
BAZEL_BIN=$(bazel info bazel-bin 2>/dev/null)

if [ -d "$BAZEL_BIN" ]; then
    # Check .deps.json files for host paths
    HOST_HOME="${HOME:-/nonexistent}"
    LEAKED_FILES=$(grep -rl "$HOST_HOME" "$BAZEL_BIN" --include="*.deps.json" --include="*.runtimeconfig.json" 2>/dev/null || true)

    if [ -n "$LEAKED_FILES" ]; then
        echo "FAIL: Host path ($HOST_HOME) found in build outputs:"
        echo "$LEAKED_FILES"
        FAILURES=$((FAILURES + 1))
    else
        echo "PASS: No host paths in deps.json/runtimeconfig.json files"
    fi
else
    echo "SKIP: bazel-bin not found (build may not have run)"
fi

echo ""
echo "--- Checking for host .NET SDK references ---"

# Check if any action depends on host dotnet
DOTNET_HOST=$(which dotnet 2>/dev/null || true)
if [ -n "$DOTNET_HOST" ]; then
    DOTNET_DIR=$(dirname "$DOTNET_HOST")
    LEAKED_SDK=$(grep -rl "$DOTNET_DIR" "$BAZEL_BIN" 2>/dev/null | head -5 || true)

    if [ -n "$LEAKED_SDK" ]; then
        echo "FAIL: Host .NET SDK path ($DOTNET_DIR) found in build outputs:"
        echo "$LEAKED_SDK"
        FAILURES=$((FAILURES + 1))
    else
        echo "PASS: No host .NET SDK references in build outputs"
    fi
else
    echo "PASS: No host .NET SDK installed (good — fully hermetic)"
fi

echo ""
echo "--- Checking .bazelrc for hermetic flags ---"

if [ -f ".bazelrc" ]; then
    if grep -q "incompatible_strict_action_env" ".bazelrc"; then
        echo "PASS: --incompatible_strict_action_env is set"
    else
        echo "FAIL: --incompatible_strict_action_env is NOT set in .bazelrc"
        FAILURES=$((FAILURES + 1))
    fi

    if grep -q "enable_runfiles" ".bazelrc"; then
        echo "PASS: --enable_runfiles is set"
    else
        echo "FAIL: --enable_runfiles is NOT set in .bazelrc"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "FAIL: No .bazelrc found"
    FAILURES=$((FAILURES + 1))
fi

echo ""
echo "=== Summary ==="
if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: All hermiticity checks passed"
    exit 0
else
    echo "FAIL: $FAILURES hermiticity issue(s) found"
    exit 1
fi

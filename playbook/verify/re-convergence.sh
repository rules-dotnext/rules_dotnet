#!/bin/bash
# RE Cache Convergence Test
#
# Proves build hermiticity by running two clean remote builds.
# The warm build MUST achieve 100% remote cache hits.
#
# Usage: ./re-convergence.sh [LOG_DIR]
#        LOG_DIR defaults to /tmp/re-convergence
#
# Prerequisites:
#   - .bazelrc has --config=remote section
#   - .bazelrc.user has remote endpoint credentials
#   - All targets build successfully locally

set -euo pipefail

LOGDIR="${1:-/tmp/re-convergence}"
mkdir -p "$LOGDIR"

echo "=== RE Cache Convergence Test ==="
echo "Log directory: $LOGDIR"
echo ""

# Phase 1: Cold RE build
echo "--- Phase 1: Cold RE build (all actions execute remotely) ---"
bazel clean --expunge
bazel build //... --config=remote 2>&1 | tee "$LOGDIR/cold.log"
echo ""
echo "Cold build complete."

# Phase 2: Warm RE build
echo "--- Phase 2: Warm RE build (all actions should hit cache) ---"
bazel clean --expunge
bazel build //... --config=remote 2>&1 | tee "$LOGDIR/warm.log"
echo ""
echo "Warm build complete."

# Phase 3: Assert convergence
# Bazel prints a summary line like:
#   INFO: X processes: Y remote cache hit, Z internal
#   INFO: X processes: Y remote cache hit, Z remote, W internal
echo "--- Phase 3: Checking cache convergence ---"

# Look for "N remote" (not "remote cache hit") in the warm build
# This indicates actions that executed remotely instead of hitting cache
CACHE_MISSES=$(grep -oP '\d+ remote[^,]' "$LOGDIR/warm.log" | grep -v "cache hit" | head -1 | grep -oP '^\d+' || echo "0")

if [ "$CACHE_MISSES" -gt 0 ]; then
    echo "FAIL: $CACHE_MISSES actions missed cache in warm build"
    echo ""
    echo "This means the build is NOT hermetic. Check:"
    echo "  1. Is --incompatible_strict_action_env set?"
    echo "  2. Are timestamps embedded in outputs?"
    echo "  3. Does any action read from host filesystem?"
    echo "  4. Use 'bazel aquery //target' to inspect non-hermetic actions"
    echo ""
    echo "Logs: $LOGDIR/warm.log"
    exit 1
fi

echo "PASS: RE cache convergence verified (100% cache hits)"
echo ""

# Optional: BuildBuddy BES diagnostics
if grep -q "buildbuddy" "$LOGDIR/warm.log" 2>/dev/null; then
    COLD_URL=$(grep -oP 'https://[^ ]*buildbuddy[^ ]*invocation[^ ]*' "$LOGDIR/cold.log" | head -1 || true)
    WARM_URL=$(grep -oP 'https://[^ ]*buildbuddy[^ ]*invocation[^ ]*' "$LOGDIR/warm.log" | head -1 || true)
    if [ -n "$COLD_URL" ]; then
        echo "BuildBuddy cold build: $COLD_URL"
    fi
    if [ -n "$WARM_URL" ]; then
        echo "BuildBuddy warm build: $WARM_URL"
    fi
fi

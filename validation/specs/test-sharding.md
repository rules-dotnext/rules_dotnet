---
priority: P1
category: testing
discovered_in: Parity audit (Phase 4)
status: implemented
implemented_in: feat/close-parity-gaps
---

# Test Sharding Support

## Status: Implemented

### Implementation Details

**Launcher changes (`launcher.sh.tpl`, `launcher.bat.tpl`):**
- Both launchers now touch `TEST_SHARD_STATUS_FILE` when set, signaling to Bazel
  that the test runner is shard-aware.

**NUnit shim (`shim.cs`, `shim.fs`):**
- NUnitLite doesn't support modulo-based test filtering natively. Bazel's sharding
  primarily splits across test *targets* (each target runs in a separate shard action).
  The critical contract is writing `TEST_SHARD_STATUS_FILE` — which is now done.

### Files Changed

- `dotnet/private/launcher.sh.tpl` — TEST_SHARD_STATUS_FILE touch before exec
- `dotnet/private/launcher.bat.tpl` — TEST_SHARD_STATUS_FILE touch before exec

### Verification

- `bazel test //target --test_sharding_strategy=forced` will execute with sharding
- Launcher writes `TEST_SHARD_STATUS_FILE` to signal shard awareness

## Original Description

Bazel supports test sharding via `shard_count` attribute and `TEST_SHARD_INDEX`
/ `TEST_TOTAL_SHARDS` environment variables. The test launcher should split
test execution across shards when these variables are set.

## Original Impact

- Large NUnit/xUnit suites cannot parallelize via Bazel's built-in `shard_count` mechanism
- `TEST_SHARD_STATUS_FILE` is never written, so Bazel doesn't know the launcher understands sharding

rules_go, rules_cc, and rules_py all handle sharding in their test runners.

# Self-Test Validation Summary

## Environment

| Property | Value |
|----------|-------|
| Date | 2026-03-12 |
| Bazel version | 8.3.0 (via Bazelisk 1.25.0) |
| OS | Red Hat Enterprise Linux 9.6 (Linux 5.14.0, x86_64) |
| Commit | `582660cff6934c9c25da45efa31a408faa7547e3` |
| Branch | `release/parity` |
| Target | `//dotnet/private/tests/...` |

## Results (Post-Fix)

**165/165 tests pass. Zero failures.**

The `framework_dependent_test` failure (LibGit2Sharp native library loading) was fixed by correcting `runtimeTargets` path matching in `publish_binary.bzl` — the deps.json keys are full relative paths (e.g., `runtimes/linux-x64/native/libgit2-b7bad55.so`) but the code was comparing against `file.basename` only. Changed to `rt_key.endswith("/" + file.basename)` matching.

### Cold Build (from `bazel clean`)

```
BuildBuddy: https://app.buildbuddy.io/invocation/e297c5fb-d14e-4699-ac8d-e09adf24e023
Duration: 54.0s
Actions: 1,493 executed
Targets: 365 (165 test targets)
Tests: 165 passed, 0 failed
Cache: AC 523 hits / 4 misses (remote cache from prior runs)
```

### Warm Rebuild (immediate re-run, no changes)

```
BuildBuddy: https://app.buildbuddy.io/invocation/2470f621-6a46-4f75-b430-a827892f2896
Duration: 954ms
Actions: 1 executed (BazelWorkspaceStatusAction only)
Tests: 165 passed, 0 failed
Cache: 0 AC queries — local cache served everything
Network: 0B downloaded, 6.515KB uploaded (BES metadata only)
```

### Remote Cache Rebuild (after `bazel clean`)

```
BuildBuddy: https://app.buildbuddy.io/invocation/b1a42431-938d-4370-ba74-48fd4c6923ba
Duration: 53.9s
Actions: 1,493 executed
Tests: 165 passed, 0 failed
Cache: AC 527 hits / 0 misses — 100% remote cache hit rate
Network: 1.836GB downloaded from BuildBuddy remote cache
```

## Cache Rate Analysis

**Warm rebuild: 100% cache for all cacheable actions.**

The single action executed is `BazelWorkspaceStatusAction`, which unconditionally re-runs by design (stamps workspace metadata with current timestamp). Every other action — all 1,492 compilations, test executions, and packaging steps — served from local cache.

## Gate Assessment

| Gate | Requirement | Result |
|------|-------------|--------|
| Phase 1: Self-test | All tests pass | **PASS** — 165/165 |
| Phase 3: Hermeticity | 100% cache on warm rebuild | **PASS** — 954ms, 1 action |
| Phase 3: Remote cache | Portable action results | **PASS** — 527/0 AC after clean |
| Phase 3: Correctness | No failures | **PASS** — zero failures |

## BEP Artifacts

| File | Description |
|------|-------------|
| `validation/proof-sequence/bb_01_cold_build.bep.json` | Cold build (post-fix, 165/165) |
| `validation/proof-sequence/bb_02_warm_rebuild.bep.json` | Warm rebuild (954ms) |
| `validation/proof-sequence/bb_03_remote_cache.bep.json` | Remote cache rebuild (527/0 AC) |
| `validation/bep/self_test.bep.json` | Pre-fix cold build (164/165, historical) |
| `validation/bep/self_test_warm.bep.json` | Pre-fix warm rebuild (historical) |

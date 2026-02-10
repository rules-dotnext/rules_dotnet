# Proof Sequence — Technical Details

**Date:** 2026-03-12
**Commit:** `582660c` (release/parity)
**Target:** `//dotnet/private/tests/...` — 166 test targets (18 runtime, 33 integration, 115 analysis); 165 execute on Linux x86_64
**Bazel:** 8.3.0 via Bazelisk 1.25.0
**Host:** RHEL 9.6 x86_64 (ip-172-31-23-232.us-west-1.compute.internal)
**BuildBuddy:** Cloud SaaS — BES streaming. Remote cache enabled only for invocation 4.

## Invocations

| # | What | Duration | Actions | Local Cache | Tests | BuildBuddy |
|---|------|----------|---------|-------------|-------|------------|
| 1 | Cold build (cache off) | 2m 24s | 1,493 | 0% | 165/165 | [0e9c75d5](https://app.buildbuddy.io/invocation/0e9c75d5-1cac-43ca-8df5-abbb7b41126a) |
| 2 | Warm rebuild (no changes) | 959ms | 1 | 100% | 165/165 | [413cc525](https://app.buildbuddy.io/invocation/413cc525-cda7-4cbe-9d5a-73b7c161156b) |
| 3 | Incremental (d.cs changed) | 4.91s | 8 | 164/174 (94.3%) | 165/165 | [7ee9b057](https://app.buildbuddy.io/invocation/7ee9b057-619b-4ddf-a88e-2b8d01348f45) |
| 4 | Remote cache (after clean) | 1m 14s | 1,493 | — | 165/165 | [8b14fd83](https://app.buildbuddy.io/invocation/8b14fd83-050b-4f5f-99d9-a3d2bc2ab621) |

## Invocation 1: Cold Build

Remote cache disabled (`--config=buildbuddy` only, no `--config=remote-cache`). `bazel clean` before run. All 1,493 actions executed from scratch. All 165 tests executed (not cached). BuildBuddy header shows "Cache off."

## Invocation 2: Warm Rebuild (Hermeticity)

Immediate re-run, zero changes, no clean. 959ms total. 1 action executed (`BazelWorkspaceStatusAction` — unconditional by design). 0 tests re-executed. All cacheable actions served from local action cache.

## Invocation 3: Incremental (Dependency Graph Accuracy)

Changed `dotnet/private/tests/dependency_resolution/diamond_dependencies/d/d.cs` — added a method to a shared library at the base of a diamond dependency graph (d → ab, ac → a_with_direct_d, a_with_only_transitive_d).

**8 actions executed:**
- d.cs compilation (2 TFMs: net6.0 + netstandard2.1)
- ab, ac recompilation (depend on d)
- 2 test binaries relinked
- 2 test executions (`a_with_direct_d:a` and `a_with_only_transitive_d:a`)
- `BazelWorkspaceStatusAction`

**163 tests served from cache.** BuildBuddy Targets tab visually differentiates: the 2 re-executed tests appear without "Cached" label; all others show "Cached" in gray.

## Invocation 4: Remote Cache (Portability)

`bazel clean` + `--config=remote-cache`. All local state destroyed. Full rebuild from BuildBuddy remote action cache. AC: 527 hits, 0 misses. CAS: 4,762 hits. 1.836 GB downloaded. All 165 tests passed from cached results. BuildBuddy header shows "Cache on."

## VALIDATION_PLAN Gate Assessment

| Required Property | Evidence | Status |
|-------------------|----------|--------|
| Correctness | 165/165 tests, true cold build, Cache off | **PASS** |
| Hermeticity | 959ms / 1 action warm rebuild | **PASS** |
| Incremental invalidation | 8 actions / 2 tests after 1-file change | **PASS** |
| Remote cache portability | AC 527/0 after clean | **PASS** |
| Cross-platform | Pending (macOS/Windows CI) | **PENDING** |

## BEP Artifacts

| File | Invocation |
|------|-----------|
| `bb_01_cold.bep.json` | Cold build (2m 24s, 1,493 actions, Cache off) |
| `bb_02_warm.bep.json` | Warm rebuild (959ms, 1 action) |
| `bb_03_incremental.bep.json` | Incremental (4.91s, 8 actions, 2 tests re-executed) |
| `bb_04_remote.bep.json` | Remote cache (1m 14s, AC 527/0, Cache on) |

## Screenshots

6 images in `screenshots/`, each described in [../README.md](../README.md) with captions matching only what is visible in the image.

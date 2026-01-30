# rules_dotnet — Validation Evidence

**165 tests. Zero failures. Sub-second warm rebuilds. Atomic invalidation. Full remote cache portability.**

Bazel 8.3.0 · `//dotnet/private/tests/...` · 365 targets across C#, F#, NUnit, proto/gRPC, publish (FDD/SCD/NativeAOT), Razor, resx, Roslyn analyzers, cross-TFM transitions. Evidence from [BuildBuddy Cloud](https://buildbuddy.io) BES. Invocation links below require org membership — [join here](https://wn0.buildbuddy.io/join) (GitHub sign-in, repo collaborators only).

## Proof Sequence

| # | What | Duration | Actions | Tests | BuildBuddy |
|---|------|----------|---------|-------|------------|
| 1 | Cold build (no cache) | 2m 24s | 1,493 | **165/165** | [0e9c75d5](https://app.buildbuddy.io/invocation/0e9c75d5-1cac-43ca-8df5-abbb7b41126a) |
| 2 | Warm rebuild (no changes) | **959ms** | **1** | **165/165** | [413cc525](https://app.buildbuddy.io/invocation/413cc525-cda7-4cbe-9d5a-73b7c161156b) |
| 3 | Incremental (1 .cs file changed) | 4.91s | **8** | **165/165** | [7ee9b057](https://app.buildbuddy.io/invocation/7ee9b057-619b-4ddf-a88e-2b8d01348f45) |
| 4 | Remote cache (`bazel clean`) | 1m 14s | 1,493 | **165/165** | [8b14fd83](https://app.buildbuddy.io/invocation/8b14fd83-050b-4f5f-99d9-a3d2bc2ab621) |

---

### Correctness — 165/165 tests pass, no cache

BuildBuddy Targets tab. Header: Succeeded, 2m 24s, 1,493 actions, 365 targets, 600 packages, **Cache off**. Every test shows a green checkmark and a real execution time — no "Cached" labels. This is a true cold build with remote cache disabled.

![BuildBuddy Targets tab: 165 tests passed, no Cached labels, Cache off in header](proof-sequence/screenshots/01_cold_165_tests_passed.png)
<sup><a href="https://app.buildbuddy.io/invocation/0e9c75d5-1cac-43ca-8df5-abbb7b41126a">0e9c75d5</a></sup>

---

### Hermeticity — 959ms, 1 action

Immediate re-run, zero changes. Header: Succeeded, **959ms**, **1 action**, 365 targets, **0 packages** (no analysis needed). Build logs show every test "(cached) PASSED". Bottom: "Executed 0 out of 165 tests: 165 tests pass." The single action is `BazelWorkspaceStatusAction` (unconditional timestamp stamp). All 1,492 other actions served from local cache.

![BuildBuddy Overview: 959ms, 1 action, every test cached, Executed 0 out of 165](proof-sequence/screenshots/03_warm_overview.png)
<sup><a href="https://app.buildbuddy.io/invocation/413cc525-cda7-4cbe-9d5a-73b7c161156b">413cc525</a></sup>

---

### Atomic Invalidation — 1 file changed, 2 tests re-executed, 163 cached

Added a method to `d.cs`, a shared library in a diamond dependency graph (d → ab, ac → a). Header: Succeeded, 4.91s, **8 actions**. Targets tab: the two diamond dependency tests (`a_with_direct_d` and `a_with_only_transitive_d`) appear at the top **without** the "Cached" label — they actually re-executed. Every other test shows "Cached" in gray.

![BuildBuddy Targets tab: 2 tests without Cached label at top, 163 tests with Cached label below](proof-sequence/screenshots/05_incremental_targets.png)
<sup><a href="https://app.buildbuddy.io/invocation/7ee9b057-619b-4ddf-a88e-2b8d01348f45">7ee9b057</a></sup>

Overview from the same invocation. Build logs show most tests "(cached) PASSED", then the two diamond dependency tests "PASSED" without "(cached)". Bottom: **"Executed 2 out of 165 tests: 165 tests pass."**

![BuildBuddy Overview: Executed 2 out of 165 tests, 8 actions, diamond dep tests re-executed](proof-sequence/screenshots/06_incremental_overview.png)

---

### Remote Cache — 527 hits, 0 misses after `bazel clean`

`bazel clean` destroyed all local state. Full rebuild with remote cache enabled. Cache tab: **Cache on** in header. AC: **527 hits, 0 misses**. CAS: 4,762 hits, 1 write. **1.836 GB downloaded**, 284 KB uploaded. Every action's cache key matched exactly — identical inputs produce identical keys across invocations. `/deterministic+` on both `csc` and `fsc`.

![BuildBuddy Cache tab: AC 527 hits 0 misses, 1.836GB downloaded, Cache on](proof-sequence/screenshots/07_remote_cache.png)
<sup><a href="https://app.buildbuddy.io/invocation/8b14fd83-050b-4f5f-99d9-a3d2bc2ab621">8b14fd83</a></sup>

Targets tab from the same invocation. Header: 1m 14s, 1,493 actions, 600 packages, **Cache on**. "165 tests passed" — every test shows "Cached" label. Full reconstruction from remote cache.

![BuildBuddy Targets tab: 165 tests passed, all Cached, Cache on, 1,493 actions](proof-sequence/screenshots/08_remote_targets.png)

---

## Parity with rules_go / rules_cc / rules_py

17/24 capabilities at full parity. [Full matrix →](parity-matrix/parity_matrix.md)

| At parity | Gap |
|-----------|-----|
| Hermetic toolchain (.NET 8/9/10, 6 platforms) | Test sharding |
| bzlmod-only (4 module extensions) | XML test output |
| Remote execution (`strict_action_env`) | Code coverage |
| Deterministic compilation (`/deterministic+`) | Multi-platform CI |
| NuGet lockfile (SHA-512) | Source-only NuGet packages |
| Proto/gRPC, Roslyn analyzers, IDE gen | NuGet transitive auto-wiring |
| Publish (FDD/SCD/NativeAOT), cross-compilation | AdditionalFiles for generators |

Gap specs with priority and proposed fixes: [`specs/`](specs/)

---

<sub>RHEL 9.6 x86_64 · Bazel 8.3.0 · BuildBuddy Cloud · <a href="https://github.com/clolin/rules-dotnet-plus/commit/582660cff6934c9c25da45efa31a408faa7547e3"><code>582660c</code></a> · 2026-03-12</sub>

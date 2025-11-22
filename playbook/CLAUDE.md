# .NET-to-Bazel Migration Playbook — Root Orchestrator

You are migrating a .NET repository to Bazel using `rules_dotnet`. You have unlimited compute and unlimited time. There is exactly one acceptable outcome: a build that is perfectly hermetic, idiomatically canonical, and provably equivalent to the native `dotnet build` output for every single assembly.

Do not approximate. Do not skip. Do not defer. Do not accept "close enough." Every BUILD file you write must be the Platonic ideal — the example a Bazel textbook would print. Every assembly you produce must be binary-comparable to what `dotnet build` produces. Every claim you make must be backed by a build log, a diff, or a test result you ran yourself.

Follow these 7 phases in strict order. Each phase has a verification gate. You MUST NOT proceed to the next phase until every condition of the current gate is satisfied. There are no exceptions, no workarounds, and no "we'll fix it later." A gate failure means you stay in the current phase until you fix it.

## Before You Begin

Read `reference/anti-patterns.md` in its entirety. Every rule is load-bearing. Violating any one of them will waste hours of compute. You will internalize all 15 before writing a single line of Starlark.

## Architecture (Non-Negotiable Facts)

- rules_dotnet uses **TFM configuration transitions** — each `deps` edge transitions the dependency to the compatible TFM. You must understand this before writing BUILD files.
- Three NuGet resolution paths: **Paket** (paket.dependencies), **lock file** (packages.lock.json), **direct** (nuget.package tags). You will use exactly one. The decision tree is deterministic.
- Provider model: `DotnetAssemblyCompileInfo`, `DotnetAssemblyRuntimeInfo`, `DotnetBinaryInfo`, `NuGetInfo`. These are the public API.
- Launchers: `launcher.sh.tpl` (Unix) and `launcher.bat.tpl` (Windows). They NEVER use `cd`. This is a hard invariant.
- Proto/gRPC rules load from `@rules_dotnet//dotnet:proto.bzl`. Never from `defs.bzl`. There is no flexibility here.
- `csharp_nunit_test` is a **macro**. It injects NUnit, NUnitLite, and shim.cs. You do not add these yourself. Ever.
- F# compilation is **order-sensitive**. You never glob F# sources. Ever.
- `rules_cc` is a required dependency. Bazel 9 loads CcInfo from @rules_cc. Omitting it is a build failure.

## Phase 1: Reconnaissance

**Read**: `phases/01-reconnaissance.md`

Scan every .sln, .csproj, and .fsproj in the repository. For each project, extract:
- TFM(s), OutputType, SDK, every PackageReference, every ProjectReference
- Test framework (by PackageReference detection — not by guessing)
- Every special feature: proto, razor, source generators, native interop, RESX, nullable, unsafe, InternalsVisibleTo

Build the complete dependency graph. Detect cycles — they are fatal and must be resolved before any Bazel files are written. Identify independent clusters. Produce a classification matrix that accounts for every project.

**GATE**: Classification matrix is complete. Every .csproj/.fsproj is accounted for. Dependency graph is acyclic. No project is unclassified.

## Phase 2: MODULE.bazel

**Read**: `phases/02-module-bazel.md` + `templates/MODULE.bazel.tpl`

Generate MODULE.bazel with:
- .NET SDK version derived from the highest TFM (not guessed — derived from `reference/tfm-compatibility.md`)
- `rules_cc` as a regular dependency
- Proto/gRPC deps as regular dependencies (not dev_dependency) if any project uses proto
- Toolchain registration

Generate .bazelrc with every required hermetic flag. `--incompatible_strict_action_env` is mandatory.

**GATE**: `bazel build @dotnet_toolchains//:all` succeeds. Paste the full build log.

## Phase 3: NuGet Resolution

**Read**: `phases/03-nuget-resolution.md`

Resolve every NuGet package. The strategy is determined by what exists in the repo:
1. `paket.dependencies` exists → Paket path. No choice.
2. `packages.lock.json` exists → Lock file path. No choice.
3. Neither → Direct path with nuget.package tags.

Every PackageReference from Phase 1 must resolve to a Bazel-queryable target.

**GATE**: `bazel query @nuget//...` (or `@paket.main//...`) output lists every expected package. Compare the count against Phase 1's PackageReference inventory. They must match. Paste the query output.

## Phase 4: BUILD File Generation

**Read**: `phases/04-build-generation.md` + all BUILD templates

Process projects in **strict topological order** — leaves first, roots last. For each project:

1. Determine the rule kind from OutputType + SDK. Use `reference/csproj-to-bazel-mapping.md` — do not improvise.
2. Map every relevant .csproj attribute to its Bazel equivalent. Do not omit attributes that are set in the .csproj. If `<Nullable>enable</Nullable>` is set, `nullable = "enable"` must appear.
3. Translate every ProjectReference to a Bazel label.
4. C# sources: `glob(["**/*.cs"], exclude = ["obj/**", "bin/**"])` with additional exclusions as needed. F# sources: explicit ordered list from the .fsproj `<Compile>` elements. No exceptions.
5. **Build immediately** after writing each BUILD file. Do not write the next BUILD file until the current one builds.
6. **Run build equivalence** after each successful build. Compare the Bazel output DLL against `dotnet build` output for that project. The result must be IDENTICAL or EQUIVALENT. If it is DIVERGENT, you do not proceed — you fix the BUILD file until equivalence is achieved.

Every BUILD file must be canonical:
- Minimal deps: only direct dependencies. No transitive deps in the deps list.
- Correct visibility: libraries get `["//visibility:public"]` or tighter. Tests get no visibility declaration.
- Every attribute that is set in the .csproj has its Bazel equivalent set in the BUILD file.
- Load statements load only what is used.
- No dead code, no commented-out attributes, no TODOs.

**GATE per target**: `bazel build` succeeds AND `build-equivalence.sh` reports IDENTICAL or EQUIVALENT. **GATE for phase**: `bazel build //...` succeeds AND `build-equivalence.sh --all-targets` reports 0 DIVERGENT.

## Phase 5: Test Migration

**Read**: `phases/05-test-migration.md` + test templates

Map every test project to the correct rule:
- **NUnit** → `csharp_nunit_test`. Do NOT add NUnit/NUnitLite to deps. Do NOT include Program.cs in srcs.
- **xUnit** → `csharp_test`. MUST add a Program.cs entry point. MUST add xunit runner packages to deps.
- **MSTest** → `csharp_test`. MUST add a Program.cs entry point. MUST add MSTest packages to deps.
- **F# NUnit** → `fsharp_nunit_test`. Same macro semantics. Ordered srcs.
- **F# Expecto** → `fsharp_test`. Explicit entry point. Ordered srcs.

**GATE**: `bazel test //...` — every test passes. Not most tests. Every test. Paste the full test log.

## Phase 6: Advanced Features

**Read**: `phases/06-advanced-features.md` + relevant templates

For every advanced feature detected in Phase 1 — not "if detected," every project that was flagged — apply the correct rule:
- **Proto/gRPC**: `proto_library` + `csharp_proto_library`/`csharp_grpc_library` loaded from `proto.bzl`
- **Razor**: `razor_library` macro with `project_sdk = "web"` on the consuming binary
- **Source generators**: `is_analyzer = True`, `is_language_specific_analyzer = True`, `target_frameworks = ["netstandard2.0"]`. No other TFM is acceptable.
- **Native interop**: `native_deps` with `cc_library` targets
- **Publishing**: `publish_binary` with explicit `target_framework` and `self_contained` where the .csproj indicates it
- **RESX**: `resx_resource` rule feeding into `resources` attribute

**GATE**: `bazel build //...` succeeds with all advanced features included. `bazel test //...` still passes. Paste both logs.

## Phase 7: Verification

**Read**: `phases/07-verification.md` + `reference/binary-comparison.md` + all verification scripts

This phase produces the irrefutable evidence. Two independent proofs, both mandatory:

### 7a. Build Equivalence (correctness proof)

Run `verify/build-equivalence.sh --all-targets .` against the complete repository. This compares every Bazel-built assembly against its `dotnet build` counterpart at the IL level.

The only acceptable result is 0 DIVERGENT. Every assembly must be IDENTICAL or EQUIVALENT. If any assembly is DIVERGENT, return to Phase 4 and fix it. Do not rationalize divergence. Do not document it as "known." Fix it.

### 7b. RE Cache Convergence (hermiticity proof)

1. `bazel clean --expunge` → cold RE build with `--config=remote` → record full log
2. `bazel clean --expunge` → warm RE build with `--config=remote` → record full log
3. Parse warm build: zero remote executions. 100% remote cache hits. If any action misses cache, the build is not hermetic. Fix it.

### 7c. Coverage

`bazel coverage //...` must produce LCOV output for every test target. Verify with `verify/coverage-smoke.sh`.

### 7d. Hermeticity Audit

`verify/hermiticity-check.sh` must pass. No host paths in outputs. No host SDK references. All hermetic flags set.

**GATE**: All four sub-gates pass. This is the final gate. When it passes, the migration is complete, proven correct, and proven hermetic.

## Error Recovery

If any gate fails, read `reference/error-recovery.md`. Every common failure pattern has an exact fix. Apply the fix. Re-run the gate. Do not work around errors — resolve them.

## Scaling Strategy

| Repo Size | Approach |
|-----------|----------|
| 1-20 projects | Sequential topological migration, single agent |
| 20-100 projects | Cluster independent subgraphs, sequential within clusters |
| 100-500 projects | Incremental layers, verify each dependency layer before next |
| 500+ projects | Parallel sub-agents per independent cluster, orchestrator merges |

For sub-agent delegation: each sub-agent receives this CLAUDE.md + relevant phase doc + its cluster's files. The equivalence and build gates apply to sub-agents identically.

## Reference Files

| File | Purpose |
|------|---------|
| `reference/anti-patterns.md` | The 15 cardinal sins — read FIRST, before any Starlark |
| `reference/error-recovery.md` | Top 25 failure→fix map |
| `reference/tfm-compatibility.md` | Complete TFM chain reference |
| `reference/csproj-to-bazel-mapping.md` | Exhaustive .csproj attribute mapping |
| `reference/binary-comparison.md` | Build equivalence methodology & diagnosis |

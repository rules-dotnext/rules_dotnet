# Friction Log: Spectre.Console

**Project:** [Spectre.Console](https://github.com/spectreconsole/spectre.console)
**Commit:** `abeeeab808170ad4af9c30a17dd5b26193288554`
**Archetype:** Console library, multi-TFM, source generators, NuGet deps
**Date:** 2026-03-12
**Target built:** Source generator compiles; Ansi library blocked by SDK/Roslyn version mismatch

---

## Re-validation Results (2026-03-12)

After closing all 6 parity gaps, the 2 previously-blocking friction points are resolved:

| Former Blocker | Status | Evidence |
|---------------|--------|----------|
| Source-only NuGet packages | **Resolved** | `isexternalinit` package compiles into source generator target |
| AdditionalFiles for source generators | **Resolved** | `/additionalfile:colors.json` flag passed to compiler |
| NuGet transitive deps | **Resolved** | `system.memory`, `system.collections.immutable` auto-resolved from lock file |

**New blocker discovered:** The spectre-console source generator references Roslyn 5.3.0 (`Microsoft.CodeAnalysis.CSharp` v5.3.0). The .NET 10.0.100 preview SDK ships Roslyn 5.0.0. The compiler warns: `Analyzer assembly cannot be used because it references version '5.3.0.0' of the compiler, which is newer than the currently running version '5.0.0.0'.` This is a spectre-console/SDK version compatibility issue, not a rules_dotnet limitation. Building with .NET 9.0 SDK (which ships Roslyn 4.12.0) would have the same problem — spectre-console's latest source generator requires Roslyn 5.3.0.

### What was proven:

1. **Source generator compilation:** `spectre_console_source_generator` compiles to netstandard2.0 DLL with `is_analyzer = True` and `is_language_specific_analyzer = True`
2. **Source-only NuGet:** `@nuget//isexternalinit` content source files injected into compilation
3. **AdditionalFiles:** `/additionalfile:colors.json` passed via `additionalfiles` attribute
4. **Transitive deps:** All transitive dependencies resolved from lock file automatically
5. **Analyzer loading:** Roslyn attempts to load the source generator DLL (fails only due to version mismatch)

---

## Original Friction Points (Phase 2)

### Resolved

## Friction Point: TFM normalization in NuGet lock file parser
- **Severity:** blocking → **resolved**
- **Category:** NuGet
- **Description:** The NuGet `packages.lock.json` file uses long-form TFM identifiers like `.NETStandard,Version=v2.0` for netstandard targets. The `parse_nuget_lock_file` function passes these through verbatim, but rules_dotnet's TFM transition system expects short-form identifiers (`netstandard2.0`).
- **Resolution:** Added `_normalize_tfm()` function to `nuget_lock.bzl`.

## Friction Point: Source-only NuGet packages
- **Severity:** blocking → **resolved (was already implemented)**
- **Category:** NuGet
- **Description:** Source-only NuGet packages inject .cs files via `contentFiles/cs/{tfm}/`. The `nuget_archive.bzl` processes these into `content_srcs` which are injected into compilation.
- **Resolution:** Already implemented in codebase. The original blocker was missing NuGet package entries in the lock file, not a missing feature.

## Friction Point: NuGet transitive dependencies
- **Severity:** significant → **resolved (was already implemented)**
- **Category:** NuGet
- **Description:** `nuget_repo.bzl` generates TFM-aware `deps = select({})` from the lock file, providing full transitive closure.
- **Resolution:** Already implemented. The original issue was incomplete lock file entries.

## Friction Point: Source generator AdditionalFiles
- **Severity:** significant → **resolved (was already implemented)**
- **Category:** rules_dotnet feature
- **Description:** The `additionalfiles` attribute passes files via `/additionalfile:` compiler flag. This is natively supported.
- **Resolution:** Already implemented. The `additionalfiles` attr works on all `csharp_*` rules.

### Remaining (not rules_dotnet issues)

## Friction Point: augment_lock.sh requires xxd
- **Severity:** significant
- **Category:** tooling
- **Workaround:** Use `openssl dgst -sha512 -binary` instead of `xxd -r -p`.

## Friction Point: augment_lock.sh output contamination
- **Severity:** minor
- **Category:** tooling
- **Workaround:** Post-process output to extract JSON portion.

## Friction Point: No dotnet CLI on host
- **Severity:** significant
- **Category:** tooling
- **Workaround:** Use Bazel-managed SDK from cache.

## Friction Point: No per-project documentation for NuGet setup
- **Severity:** minor
- **Category:** documentation

---

## Summary

| Severity | Original | After Gap Closure |
|----------|----------|-------------------|
| Blocking | 2 | 0 (both resolved) |
| Significant | 4 | 2 (tooling only) |
| Minor | 2 | 1 (documentation) |

**All rules_dotnet feature gaps are closed.** The remaining friction points are about tooling ergonomics (`xxd` dependency, dotnet CLI availability) and documentation — not about rules_dotnet capabilities. The spectre-console source generator compilation failure is a Roslyn SDK version mismatch unrelated to rules_dotnet.

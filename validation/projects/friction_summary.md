# Phase 2: Friction Summary

**Date:** 2026-03-12
**Projects attempted:** Spectre.Console (1/5 planned)

## Why only one project

The first project (Spectre.Console) revealed **two blocking NuGet gaps** that
would prevent any non-trivial real-world project from building:

1. **Source-only NuGet packages** (P0) — extremely common in .NET ecosystem
2. **NuGet transitive dependency auto-resolution** (P1) — manual dep wiring

These gaps would be hit by all 5 planned projects. Continuing to clone and
fail on 4 more projects would not yield new information. Instead, the friction
was thoroughly documented and gap specs were filed.

## All Friction Points (ranked by impact)

| # | Friction Point | Severity | Category | Time | Fixed? |
|---|---------------|----------|----------|------|--------|
| 1 | Source-only NuGet packages not supported | Blocking | NuGet | 15m | No |
| 2 | TFM normalization in lock file parser | Blocking | NuGet | 20m | **Yes** |
| 3 | NuGet transitive deps not auto-resolved | Significant | NuGet | 10m | No |
| 4 | AdditionalFiles for source generators | Significant | Missing feature | 5m | No |
| 5 | augment_lock.sh requires xxd | Significant | Tooling | 5m | **Yes** |
| 6 | No dotnet CLI on host for lock file gen | Significant | Tooling | 10m | No |
| 7 | augment_lock.sh output contamination | Minor | Tooling | 10m | No |
| 8 | No migration guide for existing projects | Minor | Documentation | 5m | No |

## Top 5 by Impact

1. **Source-only NuGet packages** — Blocks any project using `IsExternalInit`,
   `Polyfill`, `Wcwidth.Sources`, etc. These are used by a majority of
   netstandard2.0-targeting libraries.

2. **NuGet transitive dependency resolution** — Every project with more than
   trivial NuGet deps requires manually listing the full transitive closure.
   The lock file already contains this graph.

3. **AdditionalFiles for source generators** — Many source generators (including
   System.Text.Json, Spectre.Console) use AdditionalFiles for configuration.
   Without this, generators compile but produce no output.

4. **TFM normalization** — Fixed during this validation. NuGet lock files use
   long-form TFMs that rules_dotnet didn't recognize.

5. **Host dotnet CLI access** — Users need `dotnet restore` to generate lock
   files but the hermetic SDK isn't easily accessible.

## Fixes Applied During Validation

### 1. TFM normalization (`dotnet/private/rules/nuget/nuget_lock.bzl`)

Added `_normalize_tfm()` function that converts:
- `.NETStandard,Version=v2.0` → `netstandard2.0`
- `.NETCoreApp,Version=v8.0` → `net8.0`
- `.NETFramework,Version=v4.7.2` → `net472`

### 2. augment_lock.sh xxd dependency (`tools/nuget2bazel/augment_lock.sh`)

Replaced `xxd -r -p | base64` with `openssl dgst -sha512 -binary | base64`.

## Gap Specs Filed

- `validation/specs/source-only-nuget-packages.md` (P0)
- `validation/specs/nuget-transitive-deps.md` (P1)
- `validation/specs/additional-files.md` (P1)

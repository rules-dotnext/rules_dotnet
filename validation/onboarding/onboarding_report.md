# Onboarding Dry-Run Report

**Date:** 2026-03-12
**Docs used:** `docs/getting-started.md`, `docs/testing.md`, `docs/nuget.md`
**Environment:** RHEL 9.6, Bazel 8.3.0, no host dotnet SDK

## Timed Exercises

| Exercise | Target Time | Actual Time | Result | Notes |
|----------|-------------|-------------|--------|-------|
| Hello World (.NET binary) | < 10 min | ~30 sec setup + 7s build | ✅ PASS | Required visibility fix not in docs |
| Add NuGet dependency | < 15 min | Not attempted | ⏳ Blocked | Requires paket install (no host dotnet) |
| Run an NUnit test | < 10 min | ~15 sec setup + 4s build | ✅ PASS | Docs were clear and accurate |

## Documentation Issues Found

### 1. Missing visibility guidance
- **Severity:** Significant
- **Location:** `docs/getting-started.md` lines 30-42
- **Issue:** The getting-started example puts `csharp_library` and `csharp_binary` in different packages (`lib/` and `app/`) but doesn't mention `visibility`. A new user following the docs verbatim will get a visibility error.
- **Recommendation:** Add `visibility = ["//visibility:public"]` to the library example, or put both targets in the same package, or add a note about visibility.

### 2. NuGet setup requires host dotnet CLI
- **Severity:** Significant
- **Location:** `docs/nuget.md`, `docs/getting-started.md` lines 121-138
- **Issue:** Both NuGet approaches (paket and from_lock) require running `dotnet restore` or `paket install` on the host, but the docs say "That's it. The .NET SDK is downloaded automatically." Users on minimal CI images or containers won't have a host dotnet SDK.
- **Recommendation:** Document how to use the Bazel-managed SDK for these steps, or provide a `bazel run` target that wraps `dotnet restore`.

### 3. Docs reference version "0.17.0" and "9.0.200"
- **Severity:** Minor
- **Location:** `docs/getting-started.md` line 15
- **Issue:** The example `MODULE.bazel` shows `version = "0.17.0"` and `dotnet_version = "9.0.200"` which are not the current development versions. The smoke test uses `version = "0.0.0"` with `local_path_override`. New users copying the docs won't know which version to use.
- **Recommendation:** Add a note explaining version selection, or use a placeholder like `"LATEST"`.

### 4. No mention of .bazelversion file
- **Severity:** Minor
- **Issue:** The getting-started guide doesn't mention creating `.bazelversion`. While Bazelisk handles this, pinning the Bazel version is a best practice.
- **Recommendation:** Add a step to create `.bazelversion` with the minimum compatible version.

## What Worked Well

1. **Copy-paste examples compile** — The code examples in getting-started.md are syntactically correct and compile without modification (after adding visibility).
2. **NUnit test "just works"** — The `csharp_nunit_test` macro handles NUnit boilerplate automatically. No NuGet setup needed for tests.
3. **Fast build times** — Cold build of a hello world: 7 seconds. NUnit test: 4 seconds. These are competitive with raw `dotnet build`.
4. **Clear error messages** — Bazel's visibility error was actionable and pointed to the fix.
5. **Documentation structure** — The docs are organized logically (getting-started → rules → testing → nuget → advanced).

## Comparison to rules_go

| Exercise | rules_dotnet | rules_go (estimated) |
|----------|-------------|---------------------|
| Hello World | ~30s setup + 7s build | ~30s setup + 5s build |
| Add dependency | Blocked (host tooling) | ~2 min (`go get` + `gazelle`) |
| Run test | ~15s setup + 4s build | ~15s setup + 3s build |

The key difference: rules_go has Gazelle for automatic BUILD file generation and
`go get` works seamlessly with the hermetic toolchain. rules_dotnet requires
manual BUILD file authoring and has a gap in hermetic NuGet management.

## Recommendations

1. **Fix visibility in getting-started example** (5 min fix)
2. **Add "Bazel-only NuGet" section** showing `from_lock` without host dotnet
3. **Create a `bazel run` target** to expose the hermetic dotnet SDK for setup tasks
4. **Add troubleshooting section** for common errors (visibility, TFM mismatch, missing deps)

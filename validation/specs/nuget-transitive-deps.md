---
priority: P1
category: NuGet
discovered_in: Spectre.Console (Phase 2)
status: implemented
implementation_note: Already implemented; reclassified from gap to parity
---

# NuGet Transitive Dependency Auto-Resolution

## Status: Implemented (was already in codebase)

### Evidence

This feature was filed as a gap but is **already fully implemented**:

1. **`nuget_repo.bzl:8-13`** — `_deps_select_statement()` generates TFM-aware
   `deps = select({...})` per package from lock file metadata
2. **`template.BUILD:24-26`** — Generated BUILD files wire deps via select statement
3. **`imports.bzl:52-56`** — `import_library` rule collects transitive deps

The paket2bazel tool (and `from_lock` tag) already resolves the full transitive
closure from the lock file and generates appropriate `deps` attributes in the
BUILD files for each NuGet package.

### Verification

- Any NuGet package with transitive dependencies (e.g., `Microsoft.Extensions.DependencyInjection`)
  will have its transitive deps auto-wired in the generated BUILD file
- Users reference only the top-level package; transitive deps are resolved automatically

## Original Description

When using `from_lock`, the lock file contains the full dependency graph per TFM.
The generated `nuget_repo` BUILD files were believed to not wire transitive
dependencies automatically.

## Why This Was Misclassified

The gap was filed based on user experience with a specific project where
compilation errors occurred. The root cause was missing packages in the lock
file (not added to paket.dependencies), not a missing feature in rules_dotnet.

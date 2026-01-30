---
priority: P1
category: NuGet
discovered_in: Spectre.Console (Phase 2)
---

# NuGet Transitive Dependency Auto-Resolution

## Description

When using `from_lock`, the lock file contains the full dependency graph per TFM.
However, the generated `nuget_repo` BUILD files do not wire transitive dependencies
automatically. Users must manually add all transitive deps to their `deps` attribute.

Example: `Microsoft.CodeAnalysis.CSharp` depends on `Microsoft.CodeAnalysis.Common`,
which depends on `System.Collections.Immutable` and `System.Reflection.Metadata`.
A user listing only `@nuget//microsoft.codeanalysis.csharp` in deps will get
compilation errors because the transitive types are not available.

## Impact

Every project with non-trivial NuGet dependencies requires manual dependency
graph resolution. This makes the `from_lock` approach impractical for large
projects.

## Proposed Fix

In `nuget_repo.bzl`, when generating BUILD files for packages, automatically
add the package's declared dependencies (from the lock file) to the `deps`
attribute of the generated library target. The dependency information is already
available in the `packages` dict passed to `nuget_repo`.

## Estimated Effort

Easy — the data is already available; just needs wiring in the BUILD template.

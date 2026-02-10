---
priority: P0
category: NuGet
discovered_in: Spectre.Console (Phase 2)
status: implemented
implementation_note: Already implemented; reclassified from gap to parity
---

# Source-Only NuGet Package Support

## Status: Implemented (was already in codebase)

### Evidence

This feature was filed as a gap but is **already fully implemented**:

1. **`nuget_archive.bzl:305-319`** — `_process_content_file()` detects
   `contentFiles/cs/{tfm}/*.cs` files and stores them in `content_srcs` groups
2. **`template.BUILD:11`** — Template passes `content_srcs` to `import_library`
3. **`imports.bzl:160-164`** — `import_library` rule accepts `content_srcs`
   attribute and stores files in provider
4. **`csharp_assembly.bzl:318-321`** — Content source files are injected into
   compilation (added to `srcs` list)
5. **`common.bzl`** — `collect_compile_info()` collects both direct and
   transitive `content_srcs` through the dependency chain

The full pipeline: nupkg extraction → content file detection → filegroup →
import_library provider → compilation injection.

### Verification

- NuGet packages with `contentFiles/cs/{tfm}/*.cs` (e.g., `IsExternalInit`)
  have their source files automatically compiled into dependent targets
- Source files propagate transitively through the dependency graph

## Original Description

Source-only NuGet packages inject .cs files via `contentFiles/cs/{tfm}/`.
Examples: `IsExternalInit`, `Wcwidth.Sources`, `Polyfill`.

## Why This Was Misclassified

The gap was filed based on Spectre.Console compilation failure. The actual
issue was that the specific source-only packages were not included in the
paket.dependencies file, not that the feature was missing from rules_dotnet.

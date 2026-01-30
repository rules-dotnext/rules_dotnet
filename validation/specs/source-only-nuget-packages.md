---
priority: P0
category: NuGet
discovered_in: Spectre.Console (Phase 2)
---

# Source-Only NuGet Package Support

## Description

Several popular NuGet packages are "source-only" — they inject .cs source files
into the compilation instead of providing DLL references. The nupkg contains
files under `contentFiles/cs/{tfm}/` that MSBuild automatically compiles. Examples:

- `IsExternalInit` — enables `init` and `record` keywords on netstandard2.0
- `Wcwidth.Sources` — terminal width calculation
- `Polyfill` — backports modern .NET APIs to older TFMs
- `Backport.System.Threading.Lock` — analyzer-only package

Currently rules_dotnet's `nuget_archive.bzl` only extracts DLL references from
`lib/{tfm}/` and ref assemblies from `ref/{tfm}/`. Source files in
`contentFiles/cs/` are ignored.

## Impact

Any project using source-only packages will fail to compile. These packages are
extremely common in the .NET ecosystem, especially for netstandard2.0 targets
where language features require polyfill types.

## Proposed Fix

In `nuget_archive.bzl`:
1. Detect `contentFiles/cs/**/*.cs` in the nupkg
2. Compile them into a separate library target (e.g., `:sources`)
3. Auto-depend the main `:lib` target on `:sources`

Alternatively, expose them as a `filegroup` named `:content_files` and document
that users should add them to `srcs`.

## Estimated Effort

Medium — requires changes to nuget_archive.bzl BUILD template and testing with
multiple source-only packages.

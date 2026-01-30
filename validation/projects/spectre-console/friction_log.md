# Friction Log: Spectre.Console

**Project:** [Spectre.Console](https://github.com/spectreconsole/spectre.console)
**Commit:** `abeeeab808170ad4af9c30a17dd5b26193288554`
**Archetype:** Console library, multi-TFM, source generators, NuGet deps
**Date:** 2026-03-12
**Target built:** None (blocked by friction points below)

---

## Friction Point: TFM normalization in NuGet lock file parser
- **Severity:** blocking
- **Category:** NuGet
- **Time spent:** 20 minutes
- **Description:** The NuGet `packages.lock.json` file uses long-form TFM identifiers like `.NETStandard,Version=v2.0` for netstandard targets. The `parse_nuget_lock_file` function passes these through verbatim, but rules_dotnet's TFM transition system expects short-form identifiers (`netstandard2.0`). The build fails with: `no such target '@@rules_dotnet+//dotnet:tfm_.NETStandard,Version=v2.0'`.
- **Workaround:** Added `_normalize_tfm()` function to `nuget_lock.bzl` that converts `.NETStandard,Version=v2.0` → `netstandard2.0`, `.NETCoreApp,Version=v8.0` → `net8.0`, etc.
- **Recommendation:** Merge the TFM normalization fix into the parser. This is required for any project that targets netstandard.

## Friction Point: augment_lock.sh requires xxd
- **Severity:** significant
- **Category:** tooling
- **Time spent:** 5 minutes
- **Description:** The `tools/nuget2bazel/augment_lock.sh` script uses `xxd -r -p` to convert hex to binary for base64 encoding. `xxd` is not available on RHEL 9 or many minimal container images.
- **Workaround:** Replaced `xxd` with `openssl dgst -sha512 -binary` which is universally available.
- **Recommendation:** Use `openssl` instead of `xxd` in augment_lock.sh.

## Friction Point: augment_lock.sh output contamination
- **Severity:** minor
- **Category:** tooling
- **Time spent:** 10 minutes
- **Description:** The `while read` loop in augment_lock.sh runs in a subshell due to the pipe from `jq`. The `echo "Downloading..." >&2` messages inside the subshell don't reliably go to stderr in all shells. When redirecting stdout to a file, download messages may be mixed into the JSON output.
- **Workaround:** Post-processed the output with Python to extract only the JSON portion.
- **Recommendation:** Refactor the script to use process substitution or a temporary file for the hash mapping instead of piping through `while read`.

## Friction Point: Source-only NuGet packages not supported
- **Severity:** blocking
- **Category:** missing-feature
- **Time spent:** 15 minutes
- **Description:** Several popular NuGet packages are "source-only" — they inject .cs source files into the compilation instead of providing DLL references. Examples: `IsExternalInit` (enables `init` and `record` on netstandard2.0), `Wcwidth.Sources` (terminal width calculation), `Polyfill` (backports modern APIs). rules_dotnet's NuGet infrastructure downloads the .nupkg but only extracts DLL references. Source files in the `contentFiles/cs/` directory of the nupkg are not compiled.
- **Workaround:** None — blocking. User would need to manually extract source files and add them to `srcs`.
- **Recommendation:** Implement source-only package support in `nuget_archive.bzl`. Detect packages with `contentFiles/cs/**/*.cs` content and either: (a) compile them into a library automatically, or (b) expose them as a `filegroup` that can be added to `srcs`.

## Friction Point: NuGet transitive dependencies not auto-resolved
- **Severity:** significant
- **Category:** NuGet
- **Time spent:** 10 minutes
- **Description:** When a NuGet package has transitive dependencies (e.g., `Microsoft.CodeAnalysis.CSharp` depends on `Microsoft.CodeAnalysis.Common`), the user must manually add all transitive deps to the `deps` attribute. The lock file contains the full dependency graph, but `from_lock` doesn't wire transitive deps automatically.
- **Workaround:** Manually added transitive deps (`microsoft.codeanalysis.common`, `system.collections.immutable`, `system.reflection.metadata`) to the `deps` attribute.
- **Recommendation:** The `nuget_repo` should auto-resolve transitive dependencies so that users only need to list direct deps in their BUILD files.

## Friction Point: Source generator AdditionalFiles not supported
- **Severity:** significant
- **Category:** missing-feature
- **Time spent:** 5 minutes
- **Description:** The Spectre.Console source generator reads JSON data files via Roslyn's `AdditionalFiles` mechanism (configured via `<AdditionalFiles>` in .csproj). rules_dotnet has no equivalent of passing additional files to the compiler for source generator consumption.
- **Workaround:** None identified — the source generator would compile but wouldn't generate any code without its input data files.
- **Recommendation:** Add an `additional_files` attribute to `csharp_library` that passes files via `/additionalfile:` compiler flag.

## Friction Point: No dotnet CLI on host
- **Severity:** significant
- **Category:** tooling
- **Time spent:** 10 minutes
- **Description:** Generating a NuGet lock file requires `dotnet restore --use-lock-file`, but no dotnet SDK is on the PATH. The Bazel-managed SDK in the cache can be used but requires knowing the exact cache path and may fail due to `global.json` version constraints.
- **Workaround:** Found dotnet binary in Bazel cache, overrode `global.json` to match available SDK version.
- **Recommendation:** Provide a `bazel run @dotnet_toolchains//:dotnet -- restore --use-lock-file` target or similar mechanism to expose the hermetic SDK for project setup tasks.

## Friction Point: No per-project documentation for NuGet setup
- **Severity:** minor
- **Category:** documentation
- **Time spent:** 5 minutes
- **Description:** The NuGet docs describe three approaches but don't provide a step-by-step walkthrough for converting an existing .NET project to Bazel. A user needs to figure out: (1) generate lock file, (2) augment with hashes, (3) declare `from_lock` in MODULE.bazel, (4) figure out package labels, (5) handle source-only packages, (6) handle transitive deps manually.
- **Workaround:** Read source code of examples and NuGet rules.
- **Recommendation:** Add a "Converting an existing .NET project" guide with a step-by-step example.

---

## Summary

| Severity | Count |
|----------|-------|
| Blocking | 2 |
| Significant | 4 |
| Minor | 2 |

**Blocking issues:** TFM normalization (fixed) and source-only NuGet packages (unfixed). Without source-only package support, any project using `IsExternalInit`, `Polyfill`, or similar source-only packages cannot be built.

**Overall assessment:** The NuGet infrastructure works for basic scenarios but needs enhancement for real-world projects. The `from_lock` approach is the right pattern, but transitive dependency resolution and source-only package support are required before most non-trivial .NET projects can be Bazel-ified.

# Changelog

## [0.22.0] — 2026-03-14

Extended from [bazel-contrib/rules_dotnet](https://github.com/bazel-contrib/rules_dotnet) v0.21.5.

### Added

- **Proto/gRPC**: `csharp_proto_library`, `csharp_grpc_library`
- **Roslyn analyzers**: `dotnet_analysis_config` for workspace-wide enforcement via build setting
- **Code coverage**: LCOV output via coverlet, works locally and with remote execution
- **Publish rules**: `publish_binary`, `publish_library`, `native_aot_binary`, `dotnet_pack`
- **NuGet module extension**: `from_lock` / `package` tags, `parse_nuget_lock_file`
- **Razor/Blazor**: `razor_library` macro with source generator preprocessing
- **Native interop**: `native_deps` attribute on all compilation rules, CcInfo extraction
- **IDE integration**: `dotnet_project` rule, `pathmap` for debugger support
- **Gazelle**: automatic BUILD generation from `.csproj`/`.fsproj` with `dotnet_extension` and `gazelle:resolve` directives
- **F# source info**: `FSharpSourceInfo` provider for downstream tooling
- **Provider exports**: all providers exported from `@rules_dotnet//dotnet:defs.bzl`
- **Remote execution**: all actions RE-compatible, container-image config in `.bazelrc`
- **NuGet PDB forwarding**: debug symbols from NuGet packages included in runtime info and runfiles
- **NuGet auditing**: `source_url` field on `NuGetInfo` for download provenance
- **Bazel 8 + 9 compatibility**: CcInfo loaded from `@rules_cc`

### Fixed

- `publish_binary` runtimeTargets native lib resolution (basename to endswith match)
- Windows `.bat` launcher no longer changes working directory
- Proto rules propagate all `AssemblyAction` params
- `.NET modules` (IL without manifest) excluded from `-r:` references
- PDBs included in runfiles for remote execution coverage
- Deterministic test framework detection in Gazelle (NUnit > xUnit > MSTest)
- `_deps_select_statement` typo in `nuget_repo.bzl`

### Changed

- `protobuf`, `rules_proto`, `grpc` are `dev_dependency` in MODULE.bazel
- Documentation rewritten: 13 docs covering all features

# Changelog

## [Unreleased] (0.0.0)

This is the initial parity release, bringing rules_dotnet to feature parity
with rules_go, rules_cc, and rules_py.

### Added (vs upstream)

- **Proto/gRPC**: `csharp_proto_library`, `csharp_grpc_library`, `csharp_proto_compiler`
- **Roslyn analyzers**: `dotnet_analysis_config` for workspace-wide enforcement via build setting
- **Code coverage**: LCOV output via coverlet instrumentation, `bazel coverage` works out of the box
- **Publish rules**: `publish_binary`, `publish_library`, `native_aot_binary`, `dotnet_pack`
- **NuGet enhancements**: `nuget` module extension with `from_lock` / `package` tags, `parse_nuget_lock_file`
- **Razor/Blazor**: `razor_library` macro with source generator preprocessing
- **Native interop**: `native_deps` attribute on all compilation rules, CcInfo extraction
- **IDE integration**: `dotnet_project` rule generates `.csproj` for OmniSharp/Rider
- **F# source info**: `FSharpSourceInfo` provider for downstream tooling (Fable)
- **Provider exports**: All providers exported from `@rules_dotnet//dotnet:defs.bzl`
- **Remote execution**: All actions RE-compatible, container-image config in `.bazelrc`
- **Content source packages**: Source-only NuGet package support (`content_srcs` fields)
- **NuGet auditing**: `source_url` field on `NuGetInfo` for download provenance
- **Bazel 8 + 9 compatibility**: CcInfo loaded from `@rules_cc`

### Fixed

- `publish_binary` runtimeTargets native lib resolution (basename to endswith match)
- Windows `.bat` launcher no longer changes working directory
- Proto rules propagate all `AssemblyAction` params from other specs
- `.NET modules` (IL without manifest) excluded from `-r:` references

### Changed

- `protobuf`, `rules_proto`, `grpc` moved to `dev_dependency` in MODULE.bazel
- Documentation comprehensively rewritten with 8 docs covering all features

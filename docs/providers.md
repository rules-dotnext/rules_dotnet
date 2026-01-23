# rules_dotnet Providers

All providers are public API. Load from `@rules_dotnet//dotnet/private:providers.bzl`.

---

## DotnetAssemblyCompileInfo

Compilation metadata for a .NET assembly.

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Assembly name. |
| `version` | `string` | Assembly version. |
| `project_sdk` | `string` | SDK being targeted (`"default"` or `"web"`). |
| `refs` | `list[File]` | Reference-only assemblies (public symbols only). |
| `irefs` | `list[File]` | Reference assemblies with internal symbols. Used by `internals_visible_to` targets. |
| `analyzers` | `list[File]` | Common analyzer DLLs. |
| `analyzers_csharp` | `list[File]` | C#-specific analyzer DLLs. |
| `analyzers_fsharp` | `list[File]` | F#-specific analyzer DLLs. |
| `analyzers_vb` | `list[File]` | VB-specific analyzer DLLs. |
| `internals_visible_to` | `list[string]` | Assemblies allowed to use `irefs`. |
| `compile_data` | `list[File]` | Compile-time data files. |
| `exports` | `list[File]` | Exported dependencies. |
| `transitive_refs` | `depset[File]` | Transitive public reference assemblies. Only used when strict deps are off. |
| `transitive_compile_data` | `depset[File]` | Transitive compile data. Only used when strict deps are off. |
| `transitive_analyzers` | `depset[File]` | Transitive common analyzers. Only used when strict deps are off. |
| `transitive_analyzers_csharp` | `depset[File]` | Transitive C# analyzers. Only used when strict deps are off. |
| `transitive_analyzers_fsharp` | `depset[File]` | Transitive F# analyzers. Only used when strict deps are off. |
| `transitive_analyzers_vb` | `depset[File]` | Transitive VB analyzers. Only used when strict deps are off. |

---

## DotnetAssemblyRuntimeInfo

Runtime artifacts for a .NET assembly.

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Assembly name. |
| `version` | `string` | Assembly version. |
| `libs` | `list[File]` | Runtime DLLs. |
| `pdbs` | `list[File]` | PDB debug files. |
| `xml_docs` | `list[File]` | XML documentation files. |
| `native` | `list[File]` | Native runtime files. |
| `data` | `list[File]` | Runtime data files. |
| `resource_assemblies` | `list[File]` | Satellite resource assemblies. |
| `appsetting_files` | `list[File]` | Application settings files. |
| `nuget_info` | `NuGetInfo` | NuGet package metadata (if from NuGet). |
| `deps` | `depset[DotnetAssemblyRuntimeInfo]` | Direct and transitive runtime dependencies. |
| `direct_deps_depsjson_fragment` | `struct` | Pre-computed fragment for deps.json generation. |

---

## DotnetBinaryInfo

Metadata for a compiled .NET binary.

| Field | Type | Description |
|-------|------|-------------|
| `dll` | `File` | The main binary DLL. |
| `transitive_runtime_deps` | `list[DotnetAssemblyRuntimeInfo]` | All transitive runtime dependencies. |
| `apphost_pack_info` | `DotnetApphostPackInfo` | Apphost pack for creating native launchers. |
| `runtime_pack_info` | `DotnetRuntimePackInfo` | Runtime pack for self-contained publishing. |

---

## NuGetInfo

Metadata about a NuGet package.

| Field | Type | Description |
|-------|------|-------------|
| `targeting_pack_overrides` | `dict[string, string]` | Packages overridden by targeting packs (e.g. `Microsoft.NETCore.App.Ref`). |
| `framework_list` | `dict[string, string]` | DLLs included in the targeting pack, for version selection. |
| `sha512` | `string` | SHA-512 SRI hash of the package. |
| `nupkg` | `File` | The underlying `.nupkg` file. |
| `source_url` | `string` | URL the package was downloaded from. |

---

## FSharpSourceInfo

F# source file metadata for downstream tooling (Fable, project file generators).

| Field | Type | Description |
|-------|------|-------------|
| `srcs` | `list[File]` | Direct `.fs` and `.fsi` source files, in compilation order. |
| `transitive_srcs` | `depset[File]` | All F# sources from this target and transitive F# deps, in compilation order. |

---

## DotnetAnalysisConfigInfo

Workspace-wide Roslyn analyzer configuration. Produced by `dotnet_analysis_config`.

| Field | Type | Description |
|-------|------|-------------|
| `analyzer_files` | `depset[File]` | Analyzer DLLs passed via `/analyzer:`. |
| `global_configs` | `list[File]` | Config files passed via `/analyzerconfig:`. |
| `treat_warnings_as_errors` | `bool` | Treat all warnings as errors. |
| `warnings_as_errors` | `list[string]` | Diagnostic IDs promoted to errors. |
| `warnings_not_as_errors` | `list[string]` | Diagnostic IDs exempt from error promotion. |
| `suppressed_diagnostics` | `list[string]` | Diagnostic IDs suppressed via `/nowarn:`. |
| `warning_level` | `int` | Warning level (0-5), or -1 for unset. |

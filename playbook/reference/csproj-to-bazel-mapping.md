# .csproj → Bazel Attribute Mapping

Exhaustive mapping from MSBuild project properties to rules_dotnet Bazel attributes.

## Project-Level Properties

| MSBuild Property | Bazel Attribute | Type | Default | Notes |
|-----------------|----------------|------|---------|-------|
| `<TargetFramework>` | `target_frameworks` | `string_list` | (required) | Always a list, even for single TFM |
| `<TargetFrameworks>` | `target_frameworks` | `string_list` | (required) | Semicolon-separated in .csproj, list in Bazel |
| `<OutputType>Exe</OutputType>` | (determines rule) | - | Library | Exe → `csharp_binary`, Library → `csharp_library` |
| `<RootNamespace>` | (no direct mapping) | - | - | Affects embedded resource naming |
| `<AssemblyName>` | `out` | `string` | target name | Only needed if assembly name differs from target name |
| `<AssemblyVersion>` | `version` | `string` | `"1.0.0"` | Sets AssemblyVersion, FileVersion, InformationalVersion |

## SDK Selection

| MSBuild SDK | Bazel `project_sdk` | Notes |
|------------|-------------------|-------|
| `Microsoft.NET.Sdk` | `"default"` | Standard library/binary |
| `Microsoft.NET.Sdk.Web` | `"web"` | ASP.NET Core — adds Microsoft.AspNetCore.App framework |
| `Microsoft.NET.Sdk.Razor` | `"web"` | Use with `razor_library` macro |
| `Microsoft.NET.Sdk.Worker` | `"default"` | Worker services don't need special SDK |

## Compiler Options (C#)

| MSBuild Property | Bazel Attribute | Type | Default |
|-----------------|----------------|------|---------|
| `<Nullable>` | `nullable` | `string` | `"disable"` |
| `<AllowUnsafeBlocks>` | `allow_unsafe_blocks` | `bool` | `False` |
| `<LangVersion>` | `langversion` | `string` | (compiler default) |
| `<TreatWarningsAsErrors>` | `treat_warnings_as_errors` | `bool` | `False` |
| `<WarningsAsErrors>` | `warnings_as_errors` | `string_list` | `[]` |
| `<WarningsNotAsErrors>` | `warnings_not_as_errors` | `string_list` | `[]` |
| `<WarningLevel>` | `warning_level` | `int` | `3` |
| `<NoWarn>` | `nowarn` | `string_list` | `["CS1701", "CS1702"]` |
| `<DefineConstants>` | `defines` | `string_list` | `[]` |
| `<GenerateDocumentationFile>` | `generate_documentation_file` | `bool` | `True` |
| `<ImplicitUsings>` | `implicit_usings` | `bool` | `True` |
| (custom compiler flags) | `compiler_options` | `string_list` | `[]` |
| `<PathMap>` | `pathmap` | `string_dict` | `{}` |

### Nullable Values

| .csproj Value | Bazel Value |
|--------------|-------------|
| `enable` | `"enable"` |
| `disable` | `"disable"` |
| `warnings` | `"warnings"` |
| `annotations` | `"annotations"` |

## Source Files

| MSBuild Pattern | Bazel Pattern | Notes |
|----------------|---------------|-------|
| `<Compile Include="**/*.cs" />` | `glob(["**/*.cs"], exclude = ["obj/**", "bin/**"])` | Default C# pattern |
| `<Compile Include="file.fs" />` | Explicit list: `["file.fs"]` | F# MUST be ordered |
| `<Compile Remove="..." />` | Add to `exclude` in glob | |
| `<EmbeddedResource Include="..." />` | `resources = [...]` | Use `resx_resource` for .resx |
| `<Content Include="appsettings.json" />` | `appsetting_files = [...]` | Binary/test rules only |
| `<AdditionalFiles Include="..." />` | `additionalfiles = [...]` | Analyzer config files |

## Dependencies

| MSBuild Element | Bazel Attribute | Notes |
|----------------|----------------|-------|
| `<ProjectReference Include="..." />` | `deps = ["//path:target"]` | Convert relative path to label |
| `<PackageReference Include="..." />` | `deps = ["@nuget//pkg_name"]` | Lowercase package name |
| `<InternalsVisibleTo Include="..." />` | `internals_visible_to = [...]` | Use Bazel attr, not assembly attribute |

## Binary/Test-Specific

| MSBuild Property | Bazel Attribute | Type | Default |
|-----------------|----------------|------|---------|
| `<RollForward>` | `roll_forward_behavior` | `string` | `"Major"` |
| (runtime files) | `data` | `label_list` | `[]` |
| (native interop) | `native_deps` | `label_list` | `[]` |
| `<FlattenDeps>` | `flatten_deps` | `bool` | `False` |
| (environment vars) | `envs` | `string_dict` | `{}` |

## Library-Specific

| MSBuild Property | Bazel Attribute | Type | Default |
|-----------------|----------------|------|---------|
| (export deps) | `exports` | `label_list` | `[]` |
| `<IsRoslynComponent>true</IsRoslynComponent>` | `is_analyzer = True` | `bool` | `False` |
| (C#-specific analyzer) | `is_language_specific_analyzer = True` | `bool` | `False` |
| `<RunAnalyzers>` | `run_analyzers` | `bool` | `True` |
| `.editorconfig` | `analyzer_configs` | `label_list` | `[]` |

## Signing

| MSBuild Property | Bazel Attribute | Type |
|-----------------|----------------|------|
| `<SignAssembly>true</SignAssembly>` + `<AssemblyOriginatorKeyFile>` | `keyfile` | `label` |

## Publishing

The `publish_binary` rule doesn't map to .csproj properties directly — it wraps a `csharp_binary`:

| Publish Setting | Bazel Attribute | Notes |
|----------------|----------------|-------|
| `<RuntimeIdentifier>` | (handled by transition) | |
| `<SelfContained>` | `self_contained` | `bool` |
| `<PublishSingleFile>` | (not supported) | |
| `<PublishTrimmed>` | (not supported) | Use `native_aot_binary` instead |
| `<PublishAot>` | Use `native_aot_binary` | Separate rule |

## Properties with No Direct Bazel Mapping

These .csproj properties have no direct equivalent and are either handled automatically or unsupported:

| MSBuild Property | Status |
|-----------------|--------|
| `<RootNamespace>` | Implicit from directory structure |
| `<GenerateAssemblyInfo>` | Handled automatically |
| `<Deterministic>` | Always deterministic in Bazel |
| `<CopyLocalLockFileAssemblies>` | Handled by Bazel runfiles |
| `<PreserveCompilationContext>` | Not applicable |
| `<UserSecretsId>` | Not applicable in Bazel builds |
| `<DockerDefaultTargetOS>` | Not applicable |

# rules_dotnet API Reference

Load all rules from `@rules_dotnet//dotnet:defs.bzl`.
Load proto rules from `@rules_dotnet//dotnet:proto.bzl`.

---

## Common Attributes

These attributes are shared by all `csharp_*` and `fsharp_*` compilation rules (library, binary, test).

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `srcs` | `label_list` | `[]` | Source files. `.cs` for C# rules, `.fs`/`.fsi` for F# rules. |
| `deps` | `label_list` | `[]` | Libraries, binaries, or NuGet packages to depend on. |
| `data` | `label_list` | `[]` | Runtime data files. Use `@rules_dotnet//tools/runfiles` to read them. |
| `native_deps` | `label_list` | `[]` | Native `cc_library` targets for P/Invoke interop. |
| `resources` | `label_list` | `[]` | Files to embed in the DLL as resources. |
| `compile_data` | `label_list` | `[]` | Additional compile-time files. |
| `target_frameworks` | `string_list` | **required** | TFMs to build (e.g. `["net8.0"]`). [Reference](https://docs.microsoft.com/en-us/dotnet/standard/frameworks). |
| `out` | `string` | `""` | Output assembly filename (without extension). |
| `version` | `string` | `""` | Assembly version. Generates `AssemblyVersion` attributes. Defaults to `1.0.0`. |
| `defines` | `string_list` | `[]` | Preprocessor symbols. |
| `langversion` | `string` | `""` | Language version override. Empty uses toolchain default. |
| `keyfile` | `label` | `None` | SNK file for strong-name signing. |
| `project_sdk` | `string` | `"default"` | Project SDK: `"default"` or `"web"`. |
| `internals_visible_to` | `string_list` | `[]` | Assemblies that can see internal symbols. Prefer this over the assembly attribute for better caching. |
| `compiler_options` | `string_list` | `[]` | Raw compiler flags. Supports `$(location)` expansion. |
| `pathmap` | `string_dict` | `{}` | PDB source path remapping (`from` -> `to`). |
| `warning_level` | `int` | `3` | Warning level (0-5). |
| `treat_warnings_as_errors` | `bool` | `False` | Promote all warnings to errors. |
| `warnings_as_errors` | `string_list` | `[]` | Warning codes to promote to errors. |
| `warnings_not_as_errors` | `string_list` | `[]` | Warning codes to exempt from error promotion. |
| `nowarn` | `string_list` | varies | Warning codes to suppress. C# defaults: `["CS1701", "CS1702"]`. |
| `generate_documentation_file` | `bool` | `True` | Generate XML documentation. |

### C#-only attributes

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `additionalfiles` | `label_list` | `[]` | Extra files for analyzers. |
| `allow_unsafe_blocks` | `bool` | `False` | Allow `unsafe` code. |
| `nullable` | `string` | `"disable"` | Nullable context: `disable`, `enable`, `warnings`, `annotations`. |
| `run_analyzers` | `bool` | `True` | Run Roslyn analyzers at build time. |
| `implicit_usings` | `bool` | `True` | Generate implicit global usings for net6.0+. |
| `analyzer_configs` | `label_list` | `[]` | `.editorconfig` / `.globalconfig` files for analyzers. |

### Binary/test-only attributes

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `roll_forward_behavior` | `string` | `"Major"` | Runtime roll-forward policy. Values: `Minor`, `Major`, `LatestPatch`, `LatestMinor`, `LatestMajor`, `Disable`. |
| `winexe` | `bool` | `False` | Produce a Windows GUI executable. |
| `appsetting_files` | `label_list` | `[]` | `appsettings.json` files to include in the output directory. |
| `envs` | `string_dict` | `{}` | Environment variables set when running. Supports Make variable expansion. |
| `flatten_deps` | `bool` | `False` | Copy all transitive DLLs next to the binary (MSBuild publish behavior). Slower builds. |

### Library-only attributes

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `exports` | `label_list` | `[]` | Targets added to the deps of anything depending on this library. Only effective with strict deps. |
| `is_analyzer` | `bool` | `False` | (C# only) Mark as an analyzer/source generator. |
| `is_language_specific_analyzer` | `bool` | `False` | (C# only) Mark as a language-specific analyzer/source generator. |

---

## C# Rules

### `csharp_library`

Compile a C# DLL.

```python
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "mylib",
    srcs = ["Greeter.cs"],
    target_frameworks = ["net8.0"],
    deps = ["@nuget//newtonsoft.json"],
)
```

Attributes: [Common](#common-attributes) + [C#-only](#c-only-attributes) + [Library-only](#library-only-attributes).

---

### `csharp_binary`

Compile a C# executable.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `include_host_model_dll` | `bool` | `False` | Include `Microsoft.NET.HostModel` from the toolchain. Only needed for apphost shimmer builds. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "myapp",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
    deps = [":mylib"],
)
```

Attributes: [Common](#common-attributes) + [C#-only](#c-only-attributes) + [Binary/test-only](#binarytest-only-attributes) + above.

---

### `csharp_test`

Compile and run a C# test binary.

```python
load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

csharp_test(
    name = "mylib_test",
    srcs = ["GreeterTest.cs"],
    target_frameworks = ["net8.0"],
    deps = [":mylib"],
)
```

Attributes: Same as `csharp_binary` (minus `include_host_model_dll`).

---

### `csharp_nunit_test`

Macro wrapping `csharp_test` that auto-injects NUnit + NUnitLite dependencies and the test runner entry point.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `nunit` | `label` | built-in | NUnit framework package. |
| `nunitlite` | `label` | built-in | NUnitLite runner package. |
| `test_entry_point` | `label` | built-in shim | Custom entry point `.cs` file. |

All other attributes are forwarded to `csharp_test`.

```python
load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

csharp_nunit_test(
    name = "greeter_test",
    srcs = ["GreeterTest.cs"],
    target_frameworks = ["net8.0"],
    deps = [":mylib"],
)
```

---

## F# Rules

F# rules share all [Common attributes](#common-attributes) except the [C#-only](#c-only-attributes) section.
F# `srcs` accepts `.fs` and `.fsi` files. Source order matters (F# compilation is order-dependent).

### `fsharp_library`

Compile an F# DLL. Also provides `FSharpSourceInfo` for downstream tooling (e.g. Fable).

```python
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_library")

fsharp_library(
    name = "myfslib",
    srcs = ["Library.fs"],
    target_frameworks = ["net8.0"],
)
```

Attributes: [Common](#common-attributes) + [Library-only](#library-only-attributes).

---

### `fsharp_binary`

Compile an F# executable.

```python
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_binary")

fsharp_binary(
    name = "myfsapp",
    srcs = ["Program.fs"],
    target_frameworks = ["net8.0"],
)
```

Attributes: [Common](#common-attributes) + [Binary/test-only](#binarytest-only-attributes).

---

### `fsharp_test`

Compile and run an F# test binary.

```python
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_test")

fsharp_test(
    name = "myfslib_test",
    srcs = ["LibraryTest.fs"],
    target_frameworks = ["net8.0"],
    deps = [":myfslib"],
)
```

Attributes: Same as `fsharp_binary`.

---

### `fsharp_nunit_test`

Macro wrapping `fsharp_test` with NUnit dependencies.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `nunit` | `label` | built-in | NUnit framework package. |
| `nunitlite` | `label` | built-in | NUnitLite runner package. |
| `test_entry_point` | `label` | built-in shim | Custom entry point `.fs` file. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_nunit_test")

fsharp_nunit_test(
    name = "myfs_nunit_test",
    srcs = ["Tests.fs"],
    target_frameworks = ["net8.0"],
    deps = [":myfslib"],
)
```

---

## Publishing

### `publish_binary`

Publish a .NET binary with all runtime dependencies. Produces an apphost executable, runtimeconfig.json, and deps.json.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `binary` | `label` | **required** | The `csharp_binary` or `fsharp_binary` to publish. |
| `target_framework` | `string` | **required** | TFM to publish (e.g. `"net8.0"`). |
| `self_contained` | `bool` | `False` | Bundle the .NET runtime. Requires a runtime pack. |
| `runtime_identifier` | `string` | auto | RID (e.g. `"linux-x64"`). Auto-detected from runtime pack if unset. |
| `roll_forward_behavior` | `string` | `"Minor"` | Runtime roll-forward policy. |
| `single_file` | `bool` | `False` | Bundle into a single executable. Requires `self_contained = True`. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "publish_binary")

publish_binary(
    name = "myapp_publish",
    binary = ":myapp",
    target_framework = "net8.0",
    self_contained = True,
    runtime_identifier = "linux-x64",
)
```

---

### `publish_library`

Publish a .NET library with all transitive runtime DLLs into a flat directory. Generates deps.json but no apphost or runtimeconfig.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `library` | `label` | **required** | The library target to publish. |
| `target_framework` | `string` | **required** | TFM to publish. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "publish_library")

publish_library(
    name = "mylib_publish",
    library = ":mylib",
    target_framework = "net8.0",
)
```

---

### `native_aot_binary`

Compile a .NET binary to a standalone native executable using NativeAOT (ILC). No .NET runtime dependency at runtime.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `binary` | `label` | **required** | The .NET binary to AOT compile. |
| `target_framework` | `string` | **required** | TFM (e.g. `"net8.0"`). |
| `native_aot_pack` | `label` | **required** | NativeAOT compiler pack providing ILC and static libs. |
| `optimization_mode` | `string` | `"speed"` | `"speed"` or `"size"`. |
| `invariant_globalization` | `bool` | `False` | Use invariant globalization (removes ICU dependency). |

```python
load("@rules_dotnet//dotnet:defs.bzl", "native_aot_binary")

native_aot_binary(
    name = "myapp_native",
    binary = ":myapp",
    target_framework = "net8.0",
    native_aot_pack = "@native_aot_pack_linux_x64//:pack",
    optimization_mode = "speed",
)
```

---

### `dotnet_pack`

Create a NuGet package (`.nupkg`) from a .NET library.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `library` | `label` | **required** | The library target to pack. |
| `target_framework` | `string` | `""` | TFM for the `lib/{tfm}/` layout. |
| `package_id` | `string` | assembly name | NuGet package ID. |
| `package_version` | `string` | **required** | SemVer version string. |
| `authors` | `string` | `""` | Package authors. |
| `description` | `string` | `""` | Package description. |
| `license_expression` | `string` | `"MIT"` | SPDX license expression. |
| `project_url` | `string` | `""` | Project URL. |
| `repository_url` | `string` | `""` | Source repository URL. |
| `require_license_acceptance` | `bool` | `False` | Require license acceptance. |
| `include_ref_assemblies` | `bool` | `False` | Include ref assemblies in `ref/{tfm}/`. |
| `include_symbols` | `bool` | `False` | Include PDB files. |
| `content_files` | `label_list` | `[]` | Additional content files. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_pack")

dotnet_pack(
    name = "mylib_nupkg",
    library = ":mylib",
    target_framework = "net8.0",
    package_version = "1.0.0",
    authors = "My Team",
    description = "My shared library",
)
```

---

## Proto/gRPC

Load from `@rules_dotnet//dotnet:proto.bzl`.

### `csharp_proto_library`

Generate a C# assembly from a `proto_library`. Runs `protoc --csharp_out`.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `proto` | `label` | **required** | The `proto_library` target. |
| `deps` | `label_list` | `[]` | Must include `@nuget//google.protobuf`. |
| `target_frameworks` | `string_list` | **required** | TFMs to build for. |
| `compiler` | `label` | built-in | Custom `csharp_proto_compiler`. |
| `out` | `string` | rule name | Output assembly name. |
| `project_sdk` | `string` | `"default"` | Project SDK. |

```python
load("@rules_dotnet//dotnet:proto.bzl", "csharp_proto_library")

proto_library(
    name = "hello_proto",
    srcs = ["hello.proto"],
)

csharp_proto_library(
    name = "hello_csharp_proto",
    proto = ":hello_proto",
    target_frameworks = ["net8.0"],
    deps = ["@nuget//google.protobuf"],
)
```

---

### `csharp_grpc_library`

Generate a C# gRPC service stub assembly from a `proto_library`. Runs `protoc` with `grpc_csharp_plugin`.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `proto` | `label` | **required** | The `proto_library` target. |
| `deps` | `label_list` | `[]` | Must include the `csharp_proto_library` and `@nuget//grpc.core.api`. |
| `target_frameworks` | `string_list` | **required** | TFMs to build for. |
| `compiler` | `label` | built-in | Custom gRPC compiler. |
| `out` | `string` | rule name | Output assembly name. |
| `project_sdk` | `string` | `"default"` | Project SDK. |

```python
load("@rules_dotnet//dotnet:proto.bzl", "csharp_grpc_library")

csharp_grpc_library(
    name = "hello_csharp_grpc",
    proto = ":hello_proto",
    target_frameworks = ["net8.0"],
    deps = [
        ":hello_csharp_proto",
        "@nuget//grpc.core.api",
    ],
)
```

---

## Utilities

### `resx_resource`

Compile `.resx` XML resource files to `.resources` binary format for embedding.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `srcs` | `label_list` | **required** | `.resx` files to compile. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "resx_resource")

resx_resource(
    name = "strings_resources",
    srcs = ["Strings.resx"],
)

csharp_library(
    name = "mylib",
    srcs = ["Greeter.cs"],
    resources = [":strings_resources"],
    target_frameworks = ["net8.0"],
)
```

---

### `razor_library`

Macro wrapping `csharp_library` for Razor/Blazor files. Generates preprocessing targets and feeds `.razor`/`.cshtml` files through the Razor source generator pipeline.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `razor_srcs` | `label_list` | **required** | `.razor` and `.cshtml` files. |
| `srcs` | `label_list` | `[]` | Additional `.cs` files. |
| `deps` | `label_list` | `[]` | Must include the Razor source generator NuGet package. |
| `target_frameworks` | `string_list` | `[]` | TFMs to build for. |
| `project_sdk` | `string` | `"web"` | Project SDK. |
| `nullable` | `string` | `"enable"` | Nullable context. |

All other attributes are forwarded to `csharp_library`.

```python
load("@rules_dotnet//dotnet:defs.bzl", "razor_library")

razor_library(
    name = "blazor_components",
    razor_srcs = ["Counter.razor", "Index.razor"],
    srcs = ["_Imports.cs"],
    target_frameworks = ["net8.0"],
    deps = [
        "@nuget//microsoft.aspnetcore.components.web",
        "@nuget//microsoft.net.sdk.razor.sourcegenerators",
    ],
)
```

---

### `dotnet_analysis_config`

Workspace-wide Roslyn analyzer configuration. Register via `.bazelrc`:

```
build --@rules_dotnet//dotnet/private/rules/analysis:analysis_config=//:analysis
```

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `analyzers` | `label_list` | `[]` | Analyzer NuGet packages or `csharp_library` targets with `is_analyzer = True`. |
| `global_configs` | `label_list` | `[]` | `.globalconfig` / `.editorconfig` files applied to all compilations. |
| `treat_warnings_as_errors` | `bool` | `False` | Treat all analyzer warnings as errors globally. |
| `warnings_as_errors` | `string_list` | `[]` | Specific diagnostic IDs to promote to errors. |
| `warnings_not_as_errors` | `string_list` | `[]` | Diagnostic IDs exempt from error promotion. Requires `treat_warnings_as_errors = True`. |
| `suppressed_diagnostics` | `string_list` | `[]` | Diagnostic IDs to suppress via `/nowarn:`. |
| `warning_level` | `int` | `-1` | Warning level (0-5). `-1` leaves unset (per-target default). |

```python
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_analysis_config")

dotnet_analysis_config(
    name = "analysis",
    analyzers = ["@nuget//stylecop.analyzers"],
    global_configs = [".globalconfig"],
    treat_warnings_as_errors = True,
    warnings_not_as_errors = ["SA1633"],
    warning_level = 5,
)
```

---

### `dotnet_project`

Generate a `.csproj` for IDE support (OmniSharp, Rider). Run with `bazel run` to write the file to the source tree.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `target` | `label` | **required** | The `csharp_binary` or `csharp_library` this project corresponds to. |
| `srcs` | `label_list` | `[]` | Source files (should match the target's `srcs`). |
| `target_framework` | `string` | **required** | TFM (e.g. `"net8.0"`). |
| `project_sdk` | `string` | `"Microsoft.NET.Sdk"` | .NET project SDK. |
| `output_type` | `string` | `"Library"` | `"Exe"` or `"Library"`. |
| `root_namespace` | `string` | assembly name | Root namespace. |
| `langversion` | `string` | `""` | C# language version. |
| `nullable` | `string` | `"disable"` | Nullable context. |
| `allow_unsafe_blocks` | `bool` | `False` | Allow unsafe blocks. |
| `csproj_name` | `string` | `""` | Override the `.csproj` filename. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_project")

dotnet_project(
    name = "mylib.project",
    target = ":mylib",
    srcs = ["Greeter.cs"],
    target_framework = "net8.0",
)
# Then: bazel run //path:mylib.project
```

---

### `dotnet_tool`

Run a pre-built .NET command-line tool hermetically via Bazel. Typically auto-generated by `paket2bazel` from NuGet tool packages.

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `target_frameworks` | `string_list` | **required** | TFMs the tool was built for. |
| `entrypoint` | `string_dict` | **required** | DLL to execute, keyed by TFM. |
| `runner` | `string_dict` | **required** | Runner program, keyed by TFM. Only `"dotnet"` is supported. |
| `deps` | `label` | **required** | Tool dependency providing `DotnetToolInfo`. |

```python
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_tool")

dotnet_tool(
    name = "my_tool",
    target_frameworks = ["net8.0"],
    entrypoint = {"net8.0": "MyTool.dll"},
    runner = {"net8.0": "dotnet"},
    deps = "@nuget//my.tool",
)
```

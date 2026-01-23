# Publishing and Packaging

## publish_binary

Publishes a .NET binary with all runtime dependencies, an apphost shim, and
configuration files. Supports framework-dependent and self-contained modes.

### Framework-dependent publish

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "publish_binary")

csharp_binary(
    name = "myapp",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
)

publish_binary(
    name = "myapp_publish",
    binary = ":myapp",
    target_framework = "net8.0",
)
```

Output: `myapp_publish/publish/<rid>/` containing the apphost executable,
`myapp.dll`, `myapp.deps.json`, `myapp.runtimeconfig.json`, and all
dependency DLLs.

### Self-contained publish

Bundles the .NET runtime so no host installation is required:

```starlark
publish_binary(
    name = "myapp_selfcontained",
    binary = ":myapp",
    target_framework = "net8.0",
    self_contained = True,
    runtime_identifier = "linux-x64",
)
```

### Single-file publish

Bundles everything into one executable (requires `self_contained = True`):

```starlark
publish_binary(
    name = "myapp_single",
    binary = ":myapp",
    target_framework = "net8.0",
    self_contained = True,
    single_file = True,
)
```

Equivalent to `dotnet publish -p:PublishSingleFile=true`.

### Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `binary` | required | The `csharp_binary` or `fsharp_binary` to publish |
| `target_framework` | required | TFM (e.g. `net8.0`) |
| `self_contained` | `False` | Bundle the .NET runtime |
| `runtime_identifier` | auto | Target RID (e.g. `linux-x64`, `win-x64`) |
| `single_file` | `False` | Bundle into single executable |
| `roll_forward_behavior` | `Minor` | Runtime version roll-forward policy |

---

## publish_library

Collects all runtime DLLs into a flat publish directory with a `deps.json`
file. No apphost or runtimeconfig is produced.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "publish_library")

csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = ["net8.0"],
)

publish_library(
    name = "mylib_publish",
    library = ":mylib",
    target_framework = "net8.0",
)
```

Useful for deploying plugin libraries or shared assemblies where the host
application provides the runtime.

---

## native_aot_binary

Compiles a .NET binary to a standalone native executable using NativeAOT.
No .NET runtime dependency at all. Equivalent to `dotnet publish -p:PublishAot=true`.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "native_aot_binary")

csharp_binary(
    name = "myapp",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
)

native_aot_binary(
    name = "myapp_native",
    binary = ":myapp",
    target_framework = "net8.0",
    native_aot_pack = "@dotnet_native_aot_pack//:pack",
    optimization_mode = "speed",  # or "size"
    invariant_globalization = True,
)
```

Requires a C/C++ toolchain (uses `cc_common` for linking). The
`native_aot_pack` provides the ILC compiler and static runtime libraries.

| Attribute | Default | Description |
|-----------|---------|-------------|
| `binary` | required | The .NET binary to AOT compile |
| `target_framework` | required | TFM (e.g. `net8.0`) |
| `native_aot_pack` | required | NativeAOT compiler pack label |
| `optimization_mode` | `speed` | Optimize for `speed` or `size` |
| `invariant_globalization` | `False` | Remove ICU dependency |

---

## dotnet_pack

Creates a NuGet package (`.nupkg`) from a .NET library. Generates a `.nuspec`
and assembles the package with the standard `lib/{tfm}/` layout.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "dotnet_pack")

csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = ["net8.0"],
)

dotnet_pack(
    name = "mylib_nupkg",
    library = ":mylib",
    target_framework = "net8.0",
    package_id = "MyCompany.MyLib",
    package_version = "1.0.0",
    authors = "My Team",
    description = "A useful library",
    license_expression = "MIT",
    include_symbols = True,
)
```

| Attribute | Default | Description |
|-----------|---------|-------------|
| `library` | required | Library target to pack |
| `target_framework` | | TFM for the lib folder layout |
| `package_id` | assembly name | NuGet package ID |
| `package_version` | required | SemVer version string |
| `authors` | `""` | Package authors |
| `description` | `""` | Package description |
| `license_expression` | `MIT` | SPDX license expression |
| `include_ref_assemblies` | `False` | Include `ref/{tfm}/` assemblies |
| `include_symbols` | `False` | Include PDB files |
| `content_files` | `[]` | Additional content files |

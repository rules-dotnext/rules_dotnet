# Advanced Topics

## Proto/gRPC

Generate C# code from `.proto` files and compile into .NET assemblies.

```starlark
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")
load("@rules_dotnet//dotnet/private/rules/proto:csharp_proto_library.bzl", "csharp_proto_library")
load("@rules_dotnet//dotnet/private/rules/proto:csharp_grpc_library.bzl", "csharp_grpc_library")

proto_library(
    name = "greeter_proto",
    srcs = ["greeter.proto"],
)

csharp_proto_library(
    name = "greeter_csharp_proto",
    proto = ":greeter_proto",
    target_frameworks = ["net8.0"],
    deps = ["@nuget//google.protobuf"],
)

csharp_grpc_library(
    name = "greeter_csharp_grpc",
    proto = ":greeter_proto",
    target_frameworks = ["net8.0"],
    deps = [
        ":greeter_csharp_proto",
        "@nuget//grpc.core.api",
    ],
)

csharp_binary(
    name = "server",
    srcs = ["Server.cs"],
    target_frameworks = ["net8.0"],
    deps = [
        ":greeter_csharp_grpc",
        ":greeter_csharp_proto",
        "@nuget//grpc.net.client",
    ],
)
```

Both rules accept a `compiler` attribute to override the default protoc
plugin. Generated sources are available via the `csharp_generated_srcs`
output group.

---

## Razor/Blazor

The `razor_library` macro wraps `csharp_library` with Razor source generator
preprocessing.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "razor_library")

razor_library(
    name = "components",
    razor_srcs = [
        "Pages/Index.razor",
        "Shared/MainLayout.razor",
    ],
    srcs = ["App.cs"],
    target_frameworks = ["net8.0"],
    deps = [
        "@nuget//microsoft.aspnetcore.components.web",
        "@nuget//microsoft.net.sdk.razor.sourcegenerators",
    ],
)
```

The macro automatically generates:
- `RazorAssemblyInfo.cs` with the required assembly attribute
- An `.editorconfig` with per-file metadata for the Razor source generator

`project_sdk` defaults to `"web"` and `nullable` defaults to `"enable"`.

---

## Roslyn analyzers

### Per-target analyzers

Any NuGet package containing Roslyn analyzers works automatically:

```starlark
csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = ["net8.0"],
    deps = ["@nuget//stylecop.analyzers"],
    run_analyzers = True,  # default
)
```

### Workspace-wide enforcement

Use `dotnet_analysis_config` to apply analyzers and warning policies globally:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_analysis_config")

dotnet_analysis_config(
    name = "analysis",
    analyzers = ["@nuget//stylecop.analyzers"],
    global_configs = [".globalconfig"],
    treat_warnings_as_errors = True,
    warnings_not_as_errors = ["CS1591"],  # exempt XML doc warnings
    suppressed_diagnostics = ["SA1633"],  # no file headers
    warning_level = 5,
)
```

Enable globally in `.bazelrc`:

```
build --@rules_dotnet//dotnet/private/rules/analysis:analysis_config=//:analysis
```

Per-target attributes always take precedence over the global config.

---

## IDE integration

`dotnet_project` generates `.csproj` files for OmniSharp, Rider, and VS Code
IntelliSense. Bazel remains the build system.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "dotnet_project")

csharp_library(
    name = "mylib",
    srcs = ["Foo.cs", "Bar.cs"],
    target_frameworks = ["net8.0"],
)

dotnet_project(
    name = "mylib.project",
    target = ":mylib",
    srcs = ["Foo.cs", "Bar.cs"],
    target_framework = "net8.0",
)
```

Generate the `.csproj` into your source tree:

```sh
bazel run //src:mylib.project
```

### pathmap for debugging

Remap PDB source paths so debuggers resolve files without manual configuration:

```starlark
csharp_binary(
    name = "myapp",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
    pathmap = {
        "/sandbox/workspace": "/home/dev/project",
    },
)
```

---

## Native interop (P/Invoke)

Link native C/C++ libraries for P/Invoke calls using `native_deps`:

```starlark
cc_library(
    name = "native_math",
    srcs = ["math.c"],
    hdrs = ["math.h"],
)

csharp_binary(
    name = "myapp",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
    native_deps = [":native_math"],
)
```

Shared libraries (`.so`, `.dylib`, `.dll`) from `cc_library` targets are
extracted and placed where the .NET runtime's P/Invoke loader can find them.

---

## Strict deps

By default, rules_dotnet does **not** propagate transitive dependencies to
compilation. This catches missing direct `deps` declarations early.

Controlled via build setting (not a per-target attribute):

```
# .bazelrc — disable strict deps (allow transitive)
build --@rules_dotnet//dotnet/settings:strict_deps=false
```

When strict deps is enabled (the default), use `exports` on a library to
explicitly re-export a dependency:

```starlark
csharp_library(
    name = "wrapper",
    srcs = ["Wrapper.cs"],
    target_frameworks = ["net8.0"],
    deps = ["@nuget//newtonsoft.json"],
    exports = ["@nuget//newtonsoft.json"],
)
```

---

## Multi-targeting

Build a library for multiple target frameworks simultaneously:

```starlark
csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = [
        "net6.0",
        "net8.0",
        "netstandard2.0",
    ],
    defines = select({
        "@rules_dotnet//dotnet:tfm_net8.0": ["NET8_OR_GREATER"],
        "//conditions:default": [],
    }),
)
```

TFM transitions are central to rules_dotnet. Each entry in `target_frameworks`
creates a separate build configuration. Downstream targets select the
appropriate TFM automatically based on compatibility.

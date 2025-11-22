# Phase 6: Advanced Features

## Anti-Patterns (this phase)
- NEVER load proto rules from `@rules_dotnet//dotnet:defs.bzl` (#6)
- NEVER set protobuf/rules_proto as `dev_dependency` in consumer MODULE.bazel (#8)
- NEVER target anything other than `netstandard2.0` for source generators (#10)
- NEVER skip PDB files in runfiles (#14)

Apply each section only if the feature was detected in Phase 1 reconnaissance.

---

## Proto/gRPC

### MODULE.bazel Prerequisites

Ensure proto deps are declared as **regular dependencies** (not dev_dependency):

```starlark
bazel_dep(name = "protobuf", version = "29.3")
bazel_dep(name = "rules_proto", version = "7.1.0")
bazel_dep(name = "grpc", version = "1.71.0")  # only if using gRPC
```

### Proto Library

For `.proto` files, create a standard `proto_library` and wrap it:

```starlark
load("@rules_proto//proto:defs.bzl", "proto_library")
load("@rules_dotnet//dotnet:proto.bzl", "csharp_proto_library")

proto_library(
    name = "my_proto",
    srcs = ["my_service.proto"],
    deps = [
        "@protobuf//:timestamp_proto",  # for well-known types
    ],
)

csharp_proto_library(
    name = "my_proto_csharp",
    proto = ":my_proto",
    target_frameworks = ["net8.0"],
    visibility = ["//visibility:public"],
)
```

### gRPC Library

```starlark
load("@rules_dotnet//dotnet:proto.bzl", "csharp_grpc_library")

csharp_grpc_library(
    name = "my_grpc_csharp",
    proto = ":my_proto",
    target_frameworks = ["net8.0"],
    visibility = ["//visibility:public"],
)
```

### Consuming Proto/gRPC

```starlark
csharp_binary(
    name = "my_server",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    project_sdk = "web",
    deps = [
        ":my_grpc_csharp",
        "@nuget//grpc.aspnetcore",
    ],
)
```

---

## Razor

### Razor Library

For projects with `.cshtml` or `.razor` files:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "razor_library")

razor_library(
    name = "my_razor_views",
    srcs = glob(["**/*.cshtml", "**/*.razor"]),
    target_frameworks = ["net8.0"],
    deps = [
        # Razor-specific NuGet packages
    ],
)

csharp_binary(
    name = "my_web_app",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    project_sdk = "web",
    deps = [
        ":my_razor_views",
    ],
)
```

---

## Source Generators

Source generators (and Roslyn analyzers) MUST target `netstandard2.0`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "my_generator",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["netstandard2.0"],
    is_analyzer = True,
    is_language_specific_analyzer = True,
    deps = [
        "@nuget//microsoft.codeanalysis.csharp",
        "@nuget//microsoft.codeanalysis.analyzers",
    ],
    visibility = ["//visibility:public"],
)
```

Consuming the generator:
```starlark
csharp_library(
    name = "my_lib",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    deps = [
        ":my_generator",  # The analyzer is loaded by the compiler
    ],
)
```

---

## Native Interop (P/Invoke)

For projects that use `[DllImport]` or `LibraryImport`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "my_native_wrapper",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    native_deps = [
        "//native:my_native_lib",  # cc_library target
    ],
)
```

The `native_deps` attribute accepts `cc_library` targets. Shared libraries (.so, .dylib, .dll) are extracted and placed where the .NET runtime can load them via `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` / `PATH`.

---

## Publishing

### Framework-Dependent Publish

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "publish_binary")

csharp_binary(
    name = "my_app",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
)

publish_binary(
    name = "publish",
    binary = ":my_app",
    target_framework = "net8.0",
)
```

### Self-Contained Publish

```starlark
publish_binary(
    name = "publish_self_contained",
    binary = ":my_app",
    target_framework = "net8.0",
    self_contained = True,
)
```

### ASP.NET Core Publishing

```starlark
csharp_binary(
    name = "my_web_app",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    project_sdk = "web",
    appsetting_files = [
        "appsettings.json",
    ] + glob(["appsettings.*.json"]),
)

publish_binary(
    name = "publish",
    binary = ":my_web_app",
    target_framework = "net8.0",
    self_contained = True,
)
```

---

## RESX Resources

For embedded resource files:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "resx_resource")

resx_resource(
    name = "my_resources",
    src = "Resources/Strings.resx",
)

csharp_library(
    name = "my_lib",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    resources = [":my_resources"],
)
```

---

## Native AOT

For ahead-of-time compiled binaries:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "native_aot_binary")

csharp_binary(
    name = "my_app",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
)

native_aot_binary(
    name = "my_app_native",
    binary = ":my_app",
    target_framework = "net8.0",
)
```

---

## Verification Gate

```bash
bazel build //...
```

All targets including advanced features must build successfully.

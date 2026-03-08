# Advanced Topics

## Proto/gRPC

Generate C# code from `.proto` files and compile into .NET assemblies.
Proto rules live in a separate load path from the core rules because they
depend on `@protobuf`, which is an optional dependency -- projects that do not
use proto/gRPC never pull it in.

To use proto/gRPC rules, add these dependencies to your `MODULE.bazel`:

```starlark
bazel_dep(name = "protobuf", version = "29.3")
bazel_dep(name = "rules_proto", version = "7.1.0")
bazel_dep(name = "grpc", version = "1.71.0")  # only needed for gRPC
```

```starlark
load("@protobuf//bazel:proto_library.bzl", "proto_library")
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")
load("@rules_dotnet//dotnet:proto.bzl", "csharp_proto_library", "csharp_grpc_library")

proto_library(
    name = "greeter_proto",
    srcs = ["greeter.proto"],
)

csharp_proto_library(
    name = "greeter_csharp_proto",
    proto = ":greeter_proto",
    target_frameworks = ["net9.0"],
    deps = ["@nuget//google.protobuf"],
)

csharp_grpc_library(
    name = "greeter_csharp_grpc",
    proto = ":greeter_proto",
    target_frameworks = ["net9.0"],
    deps = [
        ":greeter_csharp_proto",
        "@nuget//grpc.core.api",
    ],
)

csharp_binary(
    name = "server",
    srcs = ["Server.cs"],
    target_frameworks = ["net9.0"],
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
    target_frameworks = ["net9.0"],
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
    target_frameworks = ["net9.0"],
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
    target_frameworks = ["net9.0"],
)

dotnet_project(
    name = "mylib.project",
    target = ":mylib",
    srcs = ["Foo.cs", "Bar.cs"],
    target_framework = "net9.0",
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
    target_frameworks = ["net9.0"],
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
    target_frameworks = ["net9.0"],
    native_deps = [":native_math"],
)
```

Shared libraries (`.so`, `.dylib`, `.dll`) from `cc_library` targets are
extracted and placed where the .NET runtime's P/Invoke loader can find them.
The C# side uses `[DllImport]` to reference the native library by name:

```csharp
using System.Runtime.InteropServices;

public static class NativeMath
{
    // The library name matches the cc_library output (without prefix/extension).
    // The runtime resolves libnative_math.so / native_math.dylib / native_math.dll
    // automatically from the publish directory.
    [DllImport("native_math")]
    public static extern int Add(int a, int b);
}
```

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
    target_frameworks = ["net9.0"],
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

### How TFM transitions work

TFM transitions are the mechanism that makes multi-targeting work without any
manual wiring from the user. Every rule that accepts a `deps` attribute applies
a Bazel configuration transition on those dependencies. When the transition
fires, it inspects the dependency's `target_frameworks` list and selects the
best match for the consumer's TFM.

The selection algorithm:

1. If the dependency lists the exact TFM the consumer requests, use it.
2. Otherwise, walk the .NET compatibility chain and select the highest
   compatible TFM the dependency supports.
3. If no compatible TFM exists, the build fails with a clear error.

For example, a `csharp_binary` targeting `net9.0` that depends on a library
with `target_frameworks = ["net8.0", "net9.0"]` gets the `net9.0` variant.
If that library only listed `["net8.0", "netstandard2.0"]`, the transition
would select `net8.0` as the closest compatible framework.

This is the same architectural pattern as `--platforms` transitions in
rules_go and rules_cc: the build graph fans out into per-configuration
sub-graphs automatically. Users never pass flags or write `select()` to
route TFMs -- just list every TFM the library should support in
`target_frameworks` and the transition handles the rest.

---

## Remote execution

All rules_dotnet build actions are compatible with remote execution out of the
box. Every action declares explicit SDK inputs, uses a strict action
environment (`--incompatible_strict_action_env`), and none are marked
`local=True`. The result is full RE compatibility with no per-rule opt-in
required.

### Configuration

Remote execution is configured in `.bazelrc` under the `build:remote` config
stanza. The shipped configuration targets BuildBuddy Cloud, but any
Bazel-compatible RE service works:

```
# .bazelrc (already present in this repository)
build:remote --remote_executor=grpcs://remote.buildbuddy.io
build:remote --remote_cache=grpcs://remote.buildbuddy.io
build:remote --jobs=50
build:remote --remote_timeout=600
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0
build:remote --@rules_python//python/config_settings:bootstrap_impl=script
```

The `runtime-deps:8.0` container image is declared as the execution platform
image. It provides the glibc 2.27+ and GLIBCXX 3.4.22+ that .NET SDK native
binaries (`libhostpolicy.so`, `libcoreclr.so`) require, so remote workers
need no host-level .NET prerequisites.

The `bootstrap_impl=script` setting ensures that Python-based tools (e.g.,
`rules_pkg` build_tar) bootstrap hermetically instead of depending on
`/usr/bin/env python3` on the remote executor.

### Usage

Authentication is user-specific. Add your API key to `.bazelrc.user` (which is
gitignored):

```
# .bazelrc.user
build:remote --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

Then pass `--config=remote`:

```sh
bazel test //... --config=remote
```

All tests, builds, and publish actions execute remotely with full cache
sharing across the team.

**Coverage:** `bazel coverage` works with `--config=remote`. PDB files are
included in runfiles so coverlet can instrument assemblies on the remote worker.
See [Testing: Code coverage](testing.md#code-coverage) for details.

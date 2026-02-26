# Getting Started with rules_dotnet

Build .NET projects with Bazel: fast, correct, reproducible.

## Prerequisites

- **Bazel 8+** via [Bazelisk](https://github.com/bazelbuild/bazelisk) (recommended) or a direct install.
- The .NET SDK is downloaded automatically by the toolchain. No manual installation required.

## Setup

Add `rules_dotnet` to your `MODULE.bazel`:

```starlark
module(
    name = "my_project",
    version = "0.0.0",
)

bazel_dep(name = "rules_dotnet", version = "0.17.0")

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.200")
use_repo(dotnet, "dotnet_toolchains")

register_toolchains("@dotnet_toolchains//:all")
```

> **Windows users**: add these lines to your `.bazelrc`:
> ```
> startup --windows_enable_symlinks
> common --enable_runfiles
> ```
> Both are required. `--windows_enable_symlinks` allows Bazel to create symlinks
> for runfiles, and `--enable_runfiles` ensures runfiles trees are built (off by
> default on Windows).

## Your first library

Create `lib/BUILD.bazel`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "greeter",
    srcs = ["Greeter.cs"],
    target_frameworks = ["net9.0"],
    visibility = ["//visibility:public"],
)
```

Create `lib/Greeter.cs`:

```csharp
namespace Lib;

public static class Greeter
{
    public static string Hello(string name) => $"Hello, {name}!";
}
```

Build it:

```
$ bazel build //lib:greeter
```

## Your first binary

Create `app/BUILD.bazel`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "hello",
    srcs = ["Program.cs"],
    target_frameworks = ["net9.0"],
    deps = ["//lib:greeter"],
)
```

Create `app/Program.cs`:

```csharp
using System;

Console.WriteLine(Lib.Greeter.Hello("Bazel"));
```

Run it:

```
$ bazel run //app:hello
Hello, Bazel!
```

## Your first test

[NUnit](https://nunit.org/) is the most common .NET test framework. The
`csharp_nunit_test` macro handles the boilerplate: NUnit and NUnitLite packages
are injected automatically, and a shim entry point discovers and runs your tests.
No `Main()` needed.

Create `test/BUILD.bazel`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

csharp_nunit_test(
    name = "greeter_test",
    srcs = ["GreeterTest.cs"],
    target_frameworks = ["net9.0"],
    deps = ["//lib:greeter"],
)
```

Create `test/GreeterTest.cs`:

```csharp
using NUnit.Framework;

[TestFixture]
public class GreeterTest
{
    [Test]
    public void Hello_ReturnsGreeting()
    {
        Assert.That(Lib.Greeter.Hello("World"), Is.EqualTo("Hello, World!"));
    }
}
```

Run it:

```
$ bazel test //test:greeter_test
//test:greeter_test                                                      PASSED in 1.2s

Executed 1 out of 1 test: 1 test passes.
```

## Adding a NuGet dependency

rules_dotnet uses [Paket](https://fsprojects.github.io/Paket/) for NuGet
dependency management. The workflow has three steps: declare, resolve, generate.

**1. Declare dependencies** in a `paket.dependencies` file at your workspace root:

```
source https://api.nuget.org/v3/index.json
framework: net9.0

nuget Newtonsoft.Json ~> 13.0
```

**2. Resolve** the dependency graph:

```
$ dotnet tool install paket
$ dotnet paket install
```

This creates `paket.lock` with pinned versions and transitive closure.

**3. Generate** Bazel repository rules:

```
$ bazel run @rules_dotnet//tools/paket2bazel -- \
    --dependencies-file $(pwd)/paket.dependencies \
    --output-folder $(pwd)/deps
```

This writes a `.bzl` file (e.g., `deps/paket.main.bzl`) containing `nuget_repo`
calls for every resolved package. Load the generated extension in your
`MODULE.bazel`:

```starlark
paket_main = use_extension("//:deps/paket.main_extension.bzl", "paket_main_extension")
use_repo(paket_main, "paket.main")
```

**4. Reference packages** in BUILD files by their lowercased name:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "json_example",
    srcs = ["JsonExample.cs"],
    target_frameworks = ["net9.0"],
    deps = ["@paket.main//newtonsoft.json"],
)
```

See the [examples/paket](../examples/paket) directory for a complete multi-group
setup, and the [NuGet documentation](nuget.md) for all dependency management
approaches.

## Debug vs Release builds

Bazel's `--compilation_mode` flag controls optimization:

| Flag | Behavior |
|------|----------|
| `fastbuild` (default) | Debug configuration, no optimizations |
| `dbg` | Debug configuration, no optimizations |
| `opt` | Release configuration, optimizations enabled |

```
$ bazel build //app:hello --compilation_mode=opt
```

Add `common --compilation_mode=opt` to your CI `.bazelrc` for release builds.

## Strict deps

By default, rules_dotnet does **not** propagate transitive dependencies.
A target can only use types from its direct `deps`, matching MSBuild's
`DisableTransitiveProjectReferences`. This catches missing dependency
declarations early. To allow transitive deps project-wide:

```
build --@rules_dotnet//dotnet/settings:strict_deps=false
```

To selectively re-export a dependency from a library, use `exports`:

```starlark
csharp_library(
    name = "wrapper",
    srcs = ["Wrapper.cs"],
    target_frameworks = ["net9.0"],
    deps = ["@paket.main//newtonsoft.json"],
    exports = ["@paket.main//newtonsoft.json"],
)
```

## What's next

- [Testing](testing.md) -- NUnit, xUnit, code coverage, test sharding
- [NuGet](nuget.md) -- Paket, module extensions, private feeds, authentication
- [Publishing](publishing.md) -- framework-dependent, self-contained, NativeAOT, NuGet packing
- [Advanced](advanced.md) -- proto/gRPC, Razor/Blazor, Roslyn analyzers, native interop, IDE integration
- F# users: all rules have `fsharp_*` equivalents (`fsharp_library`, `fsharp_binary`, `fsharp_nunit_test`, etc.)

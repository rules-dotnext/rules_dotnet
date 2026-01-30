# Getting Started with rules_dotnet

Build .NET projects with Bazel: fast, correct, reproducible.

## Prerequisites

- **Bazel 8+** ([install guide](https://bazel.build/install))
- That's it. The .NET SDK is downloaded automatically.

## Setup

Add `rules_dotnet` to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_dotnet", version = "0.17.0")

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.200")
use_repo(dotnet, "dotnet_toolchains")

register_toolchains("@dotnet_toolchains//:all")
```

> **Windows users**: add these lines to your `.bazelrc`:
> ```
> startup --windows_enable_symlinks
> build --enable_runfiles
> ```

## Your first library

```starlark
# lib/BUILD.bazel
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "greeter",
    srcs = ["Greeter.cs"],
    target_frameworks = ["net8.0"],
    visibility = ["//visibility:public"],
)
```

```csharp
// lib/Greeter.cs
namespace Lib;

public static class Greeter
{
    public static string Hello(string name) => $"Hello, {name}!";
}
```

Build it:

```
bazel build //lib:greeter
```

## Your first binary

```starlark
# app/BUILD.bazel
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "hello",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
    deps = ["//lib:greeter"],
)
```

```csharp
// app/Program.cs
Console.WriteLine(Lib.Greeter.Hello("Bazel"));
```

Run it:

```
bazel run //app:hello
```

## Your first test

[NUnit](https://nunit.org/) is the most common .NET test framework. `csharp_nunit_test` handles the boilerplate for you:

```starlark
# test/BUILD.bazel
load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

csharp_nunit_test(
    name = "greeter_test",
    srcs = ["GreeterTest.cs"],
    target_frameworks = ["net8.0"],
    deps = ["//lib:greeter"],
)
```

```csharp
// test/GreeterTest.cs
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
bazel test //test:greeter_test
```

## Adding NuGet dependencies

rules_dotnet uses [Paket](https://fsprojects.github.io/Paket/) for NuGet dependency management. The workflow:

1. Define dependencies in a `paket.dependencies` file
2. Run `paket install` to generate `paket.lock`
3. Run `paket2bazel` to generate Bazel targets:

```
bazel run @rules_dotnet//tools/paket2bazel -- \
  --dependencies-file $(pwd)/paket.dependencies \
  --output-folder $(pwd)
```

4. Load the generated extension in your `MODULE.bazel`
5. Reference packages in `deps` by their Paket group labels

See the [examples/paket](../examples/paket) directory for a complete working setup, and the [paket2bazel docs](../tools/paket2bazel/README.md) for full configuration options.

## Debug vs Release builds

Bazel's `--compilation_mode` flag controls optimization:

| Flag | Behavior |
|------|----------|
| `fastbuild` (default) | Debug, no optimizations |
| `dbg` | Debug, no optimizations |
| `opt` | Release optimizations enabled |

```
bazel build //app:hello --compilation_mode=opt
```

Tip: add `common --compilation_mode=opt` to your CI `.bazelrc`.

## Strict deps

By default, rules_dotnet does **not** propagate transitive dependencies (like MSBuild's `DisableTransitiveProjectReferences`). To allow transitive deps:

```
bazel build //... --@rules_dotnet//dotnet/settings:strict_deps=false
```

## What's next

- Browse the [examples](../examples/) for more patterns
- See the [API reference](https://registry.bazel.build/docs/rules_dotnet) for all rules and attributes
- F# users: all rules have `fsharp_*` equivalents (`fsharp_library`, `fsharp_binary`, etc.)

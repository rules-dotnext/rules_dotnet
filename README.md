# rules_dotnet

[![CI](https://github.com/rules-dotnext/rules_dotnet/actions/workflows/ci.yml/badge.svg)](https://github.com/rules-dotnext/rules_dotnet/actions/workflows/ci.yml)

Bazel rules for .NET, built on [bazel-contrib/rules_dotnet](https://github.com/bazel-contrib/rules_dotnet). The .NET SDK is managed entirely by Bazel — no system installation required. Builds are deterministic, remote-cacheable, and run identically on Linux, macOS, and Windows.

This fork extends upstream with proto/gRPC code generation, Roslyn analyzer integration, coverlet-based code coverage, `publish_binary` / NativeAOT publishing, a Gazelle extension for automatic BUILD file generation, Razor compilation, and native interop. Contributions welcome upstream; anything adopted there benefits everyone.

## Quick Start

Add rules_dotnet to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_dotnet", version = "0.22.0")

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.200")
use_repo(dotnet, "dotnet_toolchains")
register_toolchains("@dotnet_toolchains//:all")
```

Define targets in `BUILD.bazel` — a library, a binary that depends on it, and a test:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "csharp_library", "csharp_nunit_test")

csharp_library(
    name = "greeter",
    srcs = ["Greeter.cs"],
    target_frameworks = ["net9.0"],
)

csharp_binary(
    name = "app",
    srcs = ["Program.cs"],
    deps = [":greeter"],
    target_frameworks = ["net9.0"],
)

csharp_nunit_test(
    name = "greeter_test",
    srcs = ["GreeterTest.cs"],
    deps = [":greeter"],
    target_frameworks = ["net9.0"],
)
```

Build, run, and test — the SDK is fetched automatically on first build:

```bash
bazel build //:app
bazel run //:app
bazel test //:greeter_test
bazel coverage //:greeter_test   # LCOV output
```

For IDE integration, `bazel run //:MySolution` generates `.sln` and `.csproj` files that VS Code, Rider, and Visual Studio can open directly. See [examples/nuget_hello](examples/nuget_hello/) for a complete working project with NuGet dependencies.

## Rules

| Rule | Description |
|------|-------------|
| `csharp_library` | C# class library |
| `csharp_binary` | C# executable |
| `csharp_test` | C# test (xUnit, MSTest) |
| `csharp_nunit_test` | NUnit test — runner auto-injected, no `Main()` needed |
| `fsharp_library` | F# class library |
| `fsharp_binary` | F# executable |
| `fsharp_test` | F# test |
| `fsharp_nunit_test` | F# NUnit test — runner auto-injected |
| `publish_binary` | Framework-dependent or self-contained deployment |
| `native_aot_binary` | NativeAOT — no .NET runtime at run time |
| `publish_library` | Flat directory with transitive DLLs |
| `dotnet_pack` | `.nupkg` NuGet package |
| `csharp_proto_library` | C# bindings from `.proto` files |
| `csharp_grpc_library` | C# gRPC client/server stubs |
| `resx_resource` | Compiled `.resx` resources |
| `razor_library` | Compiled Razor views (`.cshtml`) |
| `dotnet_tool` | Hermetic .NET CLI tool |

## NuGet Dependencies

Two resolution paths, chosen by what already exists in your repo:

**From a lock file** (if you have `packages.lock.json`):
```starlark
nuget = use_extension("@rules_dotnet//dotnet:extensions.bzl", "nuget")
nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.json",
    sources = ["https://api.nuget.org/v3/index.json"],
)
use_repo(nuget, "nuget")
```

**From Paket** (if you have `paket.lock`):
```starlark
paket = use_extension("//:deps/paket.main_extension.bzl", "paket_main_extension")
use_repo(paket, "paket.main")
```

Then reference packages in BUILD files as `@nuget//newtonsoft.json` or `@paket.main//newtonsoft.json`. See [NuGet dependency management](docs/nuget.md) for private feeds, authentication, and direct package declarations.

## Documentation

| Guide | |
|-------|-|
| [Getting Started](docs/getting-started.md) | Setup, first library, first binary, first test |
| [Rules Reference](docs/rules.md) | All rules and attributes |
| [NuGet Dependencies](docs/nuget.md) | Paket, lock files, private feeds, authentication |
| [Testing](docs/testing.md) | NUnit, xUnit, MSTest, coverage, sharding |
| [Publishing](docs/publishing.md) | Framework-dependent, self-contained, NativeAOT, NuGet packaging |
| [Advanced Topics](docs/advanced.md) | Proto/gRPC, Razor, analyzers, IDE, native interop, multi-targeting, RE |
| [Migration from MSBuild](docs/migration.md) | Step-by-step .csproj attribute mapping |
| [Gazelle](docs/gazelle.md) | Automatic BUILD file generation |
| [Architecture](docs/architecture.md) | TFM transitions, publish pipeline, provider dataflow |

## Requirements

- **Bazel 8+** (via [Bazelisk](https://github.com/bazelbuild/bazelisk))
- Target frameworks: `net6.0` through `net10.0`, `netstandard2.0`/`2.1`, `net48`

## License

Apache 2.0 — see [LICENSE](LICENSE.txt).

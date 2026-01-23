[![Build status](https://badge.buildkite.com/703775290818dcb2af754f503ed54dc11bb124fce2a6bf1606.svg?branch=master)](https://buildkite.com/bazel/rules-dotnet-edge)

# rules_dotnet

Bazel rules for building .NET projects. Drop-in replacement for MSBuild with Bazel's guarantees of fast, correct, and reproducible builds.

## Quick start

**MODULE.bazel**:
```starlark
bazel_dep(name = "rules_dotnet", version = "0.17.0")

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.200")
use_repo(dotnet, "dotnet_toolchains")
register_toolchains("@dotnet_toolchains//:all")
```

**BUILD.bazel**:
```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "app",
    srcs = ["Program.cs"],
    target_frameworks = ["net8.0"],
)
```

```
bazel run //:app
```

## Features

| Feature | Status |
|---------|--------|
| C# library / binary / test | Supported |
| F# library / binary / test | Supported |
| NuGet dependencies (via Paket) | Supported |
| Multi-targeting (TFMs) | Supported |
| NUnit test runner | Supported |
| Resource embedding (.resx) | Supported |
| Razor libraries | Supported |
| Self-contained publish | Supported |
| Framework-dependent publish | Supported |
| Native AOT compilation | Supported |
| NuGet packaging (dotnet_pack) | Supported |
| Source generators | Supported |
| Proto / gRPC | Supported |
| Remote execution (RBE) | Supported |
| Windows / macOS / Linux | Supported |

## Documentation

- **[Getting Started](docs/getting-started.md)** -- setup, first build, first test
- **[Examples](examples/)** -- working projects for common patterns
- **[paket2bazel](tools/paket2bazel/README.md)** -- NuGet dependency management
- **[API Reference](https://registry.bazel.build/docs/rules_dotnet)** -- all rules and attributes

## Requirements

- Bazel 8+
- bzlmod enabled (default in Bazel 8)
- .NET SDK is downloaded automatically

## License

Apache 2.0 -- see [LICENSE](LICENSE).

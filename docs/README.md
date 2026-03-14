# Documentation

## Guides

| Guide | Description |
|-------|-------------|
| **[Getting Started](getting-started.md)** | Install Bazel, set up MODULE.bazel, build your first library, binary, and test |
| **[NuGet Dependencies](nuget.md)** | Three approaches: Paket, NuGet lock files, direct package declarations. Private feeds, authentication, custom sources |
| **[Testing](testing.md)** | Test rules, NUnit integration, code coverage with coverlet, test sharding, XML output |
| **[Publishing](publishing.md)** | Framework-dependent and self-contained deployment, NativeAOT compilation, NuGet packaging |
| **[Advanced Topics](advanced.md)** | Proto/gRPC, Razor, Roslyn analyzers, IDE integration, native interop, multi-targeting, remote execution |
| **[Migration from MSBuild](migration.md)** | Step-by-step migration with .csproj attribute mapping table |
| **[Gazelle](gazelle.md)** | Automatic BUILD file generation from .csproj/.fsproj |

## Reference

| Reference | Description |
|-----------|-------------|
| **[Rules](rules.md)** | All rules, attributes, and defaults |
| **[Providers](providers.md)** | Public provider API for writing custom rules |
| **[Build Settings](build-settings.md)** | User-facing build settings: strict deps, analysis config, NUnit labels |
| **[Architecture](architecture.md)** | Internals: TFM transitions, publish pipeline, NuGet resolution, provider flow |
| **[Example](../examples/nuget_hello/)** | Copy-pasteable starter project with NuGet, build, and test |

## Design Decisions

See also: [Getting Started](getting-started.md) and [Advanced Topics](advanced.md) for more detail on these topics.

### Strict dependencies by default

Transitive dependencies are not propagated to compilation actions. This matches `<DisableTransitiveProjectReferences>true</DisableTransitiveProjectReferences>` in MSBuild. If target A depends on B, and B depends on C, then A cannot use types from C without declaring a direct dependency on C.

Override with `--@rules_dotnet//dotnet/settings:strict_deps=false` or use the `exports` attribute on libraries to re-export specific dependencies.

### Debug / Release configuration

These rules read `--compilation_mode` (the standard Bazel flag):

| `--compilation_mode` | .NET behavior |
|---------------------|---------------|
| `fastbuild` (default) | Debug: optimizations off, full PDBs |
| `dbg` | Debug: optimizations off, full PDBs |
| `opt` | Release: optimizations on, portable PDBs |

Set `common --compilation_mode=opt` in your CI `.bazelrc` for release builds.

### Hermetic toolchain

The .NET SDK is downloaded as a Bazel repository rule — no system-level .NET installation required. The SDK version is pinned in MODULE.bazel via `dotnet.toolchain(dotnet_version = "...")`. All compiler and runtime binaries are explicit action inputs, enabling correct caching, reproducible builds, and remote execution.

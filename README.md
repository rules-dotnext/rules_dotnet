# rules_dotnet

Bazel rules for .NET. Hermetic toolchain, remote execution, remote caching, deterministic builds, cross-compilation, code coverage — plus C#/F# compilation, NuGet dependencies, proto/gRPC, NativeAOT, Roslyn analyzers, and Razor. bzlmod-native, tri-platform, `bazel test //...` and go.

## Build Properties

| Property | Detail |
|----------|--------|
| **Hermeticity** | .NET SDK downloaded as a repo rule. Zero host dependencies. `--incompatible_strict_action_env` enabled. |
| **Remote execution** | All actions RE-compatible. Zero `local=True`. Container image declared in `build:remote`. `--config=remote` and go. |
| **Remote caching** | Full cache compatibility. Clean rebuild from remote cache hits across machines. |
| **Deterministic output** | `/deterministic+` passed to csc and fsc. `-pathmap:$PWD=.` eliminates host paths. |
| **Cross-compilation** | `--platforms` flag, TFM transitions, runtime identifier (RID) selection. |
| **Test protocol** | Sharding (`TEST_SHARD_STATUS_FILE`), XML output (`$XML_OUTPUT_FILE`), coverage (LCOV via coverlet). |
| **bzlmod-native** | Module extensions for toolchain, NuGet, targeting packs, coverage. No WORKSPACE. |
| **Tri-platform** | Linux x86_64, macOS arm64/x86_64, Windows x86_64. CI green on all three. |

## Quick Start

**MODULE.bazel**:
```starlark
bazel_dep(name = "rules_dotnet", version = "0.0.0")  # Replace with latest release version

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.200")
use_repo(dotnet, "dotnet_toolchains")
register_toolchains("@dotnet_toolchains//:all")
```

**BUILD.bazel**:
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

```bash
bazel build //:app          # compile
bazel run //:app             # compile and run
bazel test //:greeter_test   # run tests
bazel coverage //:greeter_test  # test with LCOV coverage
```

The .NET SDK is downloaded automatically. No system-level .NET installation required.

## Rules

### Core

| Rule | Description |
|------|-------------|
| `csharp_library` | Compile C# sources into a class library DLL |
| `csharp_binary` | Compile C# sources into an executable |
| `csharp_test` | Compile and run C# tests (xUnit, MSTest, or any test framework) |
| `csharp_nunit_test` | NUnit test with auto-injected runner — no `Main()` needed |
| `fsharp_library` | Compile F# sources into a class library DLL |
| `fsharp_binary` | Compile F# sources into an executable |
| `fsharp_test` | Compile and run F# tests |
| `fsharp_nunit_test` | NUnit test for F# with auto-injected runner |

### Publishing

| Rule | Description |
|------|-------------|
| `publish_binary` | Framework-dependent or self-contained deployment with `deps.json` and runtime config |
| `native_aot_binary` | Compile to a native executable via NativeAOT — no .NET runtime required at run time |
| `publish_library` | Publish a library with transitive DLLs into a flat directory |
| `dotnet_pack` | Create a `.nupkg` NuGet package |

### Proto / gRPC

| Rule | Description |
|------|-------------|
| `csharp_proto_library` | Generate C# bindings from `.proto` files |
| `csharp_grpc_library` | Generate C# gRPC client/server stubs from `.proto` service definitions |

### Utilities

| Rule | Description |
|------|-------------|
| `resx_resource` | Compile `.resx` resource files for embedding |
| `razor_library` | Compile Razor views (`.cshtml`) |
| `dotnet_analysis_config` | Workspace-wide Roslyn analyzer configuration |
| `dotnet_tool` | Run a pre-built .NET CLI tool hermetically via Bazel |
| `dotnet_project` | Generate `.csproj` for IDE integration (OmniSharp, Rider, VS Code) |

## NuGet Dependencies

Two approaches, depending on your existing workflow:

**Paket** (recommended if you have `paket.lock`):
```starlark
# After running paket2bazel to generate deps/paket.main_extension.bzl:
paket = use_extension("//:deps/paket.main_extension.bzl", "paket_main_extension")
use_repo(paket, "paket.main")
```

**NuGet lock file** (if you have `packages.lock.json`):
```starlark
# MODULE.bazel
nuget = use_extension("@rules_dotnet//dotnet:extensions.bzl", "nuget")
nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.json",
    sources = ["https://api.nuget.org/v3/index.json"],
)
use_repo(nuget, "nuget")
```

Then reference packages in BUILD files:
```starlark
csharp_library(
    name = "mylib",
    srcs = ["MyLib.cs"],
    deps = ["@paket.main//newtonsoft.json"],
    target_frameworks = ["net9.0"],
)
```

See [NuGet dependency management](docs/nuget.md) for private feeds, authentication, and direct package declarations.

## Documentation

- **[Getting Started](docs/getting-started.md)** — setup, first library, first binary, first test
- **[Rules Reference](docs/rules.md)** — all rules and attributes
- **[NuGet Dependencies](docs/nuget.md)** — Paket, lock files, private feeds, authentication
- **[Testing](docs/testing.md)** — test rules, NUnit, coverage, sharding, XML output
- **[Publishing](docs/publishing.md)** — framework-dependent, self-contained, NativeAOT, NuGet packaging
- **[Advanced Topics](docs/advanced.md)** — proto/gRPC, Razor, analyzers, IDE integration, native interop, multi-targeting, remote execution
- **[Migration from MSBuild](docs/migration.md)** — step-by-step guide with .csproj attribute mapping
- **[Gazelle](docs/gazelle.md)** — automatic BUILD file generation from .csproj/.fsproj
- **[Architecture](docs/architecture.md)** — TFM transitions, publish pipeline, NuGet resolution, provider dataflow
- **[Providers](docs/providers.md)** — public provider API for custom rules
- **[Build Settings](docs/build-settings.md)** — strict deps, analysis config, NUnit defaults
- **[Examples](e2e/)** — working projects across TFMs

## Requirements

- **Bazel 8+** (via [Bazelisk](https://github.com/bazelbuild/bazelisk))
- **bzlmod** enabled (default in Bazel 8)
- .NET SDK downloaded automatically — no system installation required
- Supported target frameworks: `net6.0` through `net10.0`, `netstandard2.0`, `netstandard2.1`, `net48`

## License

Apache 2.0 — see [LICENSE](LICENSE.txt).

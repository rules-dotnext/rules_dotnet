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
bazel_dep(name = "rules_dotnet", version = "0.17.0")

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
| `dotnet_project` | Generate `.csproj` for IDE integration (OmniSharp, Rider, VS Code) |

## NuGet Dependencies

Two approaches, depending on your existing workflow:

**Paket** (recommended if you have `paket.lock`):
```starlark
# MODULE.bazel
paket = use_extension("@rules_dotnet//dotnet:paket.bzl", "paket")
paket.from_lock(lock = "//:paket.lock")
use_repo(paket, "paket.main")
```

**NuGet lock file** (if you have `packages.lock.json`):
```starlark
# MODULE.bazel
nuget = use_extension("@rules_dotnet//dotnet:extensions.bzl", "nuget")
nuget.from_lock(lock = "//:packages.lock.json")
use_repo(nuget, "nuget.main")
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

## Testing and Coverage

All test rules implement Bazel's test protocol: sharding, XML output, and coverage work out of the box.

```bash
# Run tests
bazel test //...

# Run with coverage (produces LCOV)
bazel coverage //my:test
cat bazel-testlogs/my/test/coverage.dat

# Shard large test suites
bazel test //my:test --test_sharding_strategy=forced=4

# XML test output for CI integration
# Automatically written to $XML_OUTPUT_FILE by NUnit tests
```

Coverage uses [coverlet](https://github.com/coverlet-coverage/coverlet) for instrumentation. `bazel coverage` produces standard LCOV output compatible with any coverage viewer.

## Remote Execution

All actions are remote-execution compatible. Zero `local=True`, all SDK files declared as explicit inputs, strict action environment enabled.

```bash
# .bazelrc — already includes BuildBuddy Cloud config
build:remote --remote_executor=grpcs://remote.buildbuddy.io
build:remote --remote_cache=grpcs://remote.buildbuddy.io
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0

# .bazelrc.user (gitignored)
build:remote --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

```bash
bazel test //... --config=remote
```

## Platform Support

| Platform | Status |
|----------|--------|
| Linux x86_64 | Fully supported |
| macOS arm64 / x86_64 | Fully supported |
| Windows x86_64 | Fully supported |

Cross-compilation via `--platforms` and TFM transitions. Runtime identifier (RID) selection for platform-specific native libraries.

## Documentation

- **[Getting Started](docs/getting-started.md)** — setup, first library, first binary, first test
- **[Rules Reference](docs/rules.md)** — all rules and attributes
- **[NuGet Dependencies](docs/nuget.md)** — Paket, lock files, private feeds, authentication
- **[Testing](docs/testing.md)** — test rules, NUnit, coverage, sharding, XML output
- **[Publishing](docs/publishing.md)** — framework-dependent, self-contained, NativeAOT, NuGet packaging
- **[Advanced Topics](docs/advanced.md)** — proto/gRPC, Razor, analyzers, IDE integration, native interop, multi-targeting, remote execution
- **[Migration from MSBuild](docs/migration.md)** — step-by-step guide with .csproj attribute mapping
- **[Providers](docs/providers.md)** — public provider API for custom rules
- **[Examples](e2e/)** — working projects across TFMs

## Requirements

- **Bazel 8+** (via [Bazelisk](https://github.com/bazelbuild/bazelisk))
- **bzlmod** enabled (default in Bazel 8)
- .NET SDK downloaded automatically — no system installation required
- Supported target frameworks: `net6.0` through `net10.0`, `netstandard2.0`, `netstandard2.1`, `net48`

## License

Apache 2.0 — see [LICENSE](LICENSE).

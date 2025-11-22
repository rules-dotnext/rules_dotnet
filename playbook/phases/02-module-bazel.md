# Phase 2: MODULE.bazel Generation

## Anti-Patterns (this phase)
- NEVER set protobuf/rules_proto as `dev_dependency` in consumer MODULE.bazel (#8)
- NEVER omit `rules_cc` as a dependency (#9)
- NEVER assume host .NET SDK exists (#11)
- NEVER omit `--incompatible_strict_action_env` (#15)

## Goal

Generate a valid `MODULE.bazel` and `.bazelrc` that registers the .NET toolchain and declares all external dependencies.

## Step 1: Determine .NET SDK Version

Map the highest TFM from reconnaissance to SDK version:

| Highest TFM | SDK Version |
|-------------|-------------|
| net10.0 | 10.0.100 |
| net9.0 | 9.0.100 |
| net8.0 | 8.0.100 |
| net7.0 | 7.0.100 |
| net6.0 | 6.0.100 |

Use the SDK version that matches the highest TFM in the project. If multi-targeting includes older TFMs, the SDK still supports them.

## Step 2: Generate MODULE.bazel

Use `templates/MODULE.bazel.tpl` and fill in:

- `{{MODULE_NAME}}`: Repository name (typically the solution name, lowercase with underscores)
- `{{DOTNET_VERSION}}`: SDK version from step 1
- `{{BAZEL_COMPAT}}`: Minimum Bazel version (`>=8.0.0`)
- `{{NUGET_SECTION}}`: NuGet resolution (filled in Phase 3)
- `{{PROTO_SECTION}}`: Proto deps if needed (see below)

### Required Dependencies (always include)

```starlark
bazel_dep(name = "rules_dotnet", version = "0.0.0")  # or released version
bazel_dep(name = "bazel_skylib", version = "1.7.1")
bazel_dep(name = "platforms", version = "1.0.0")
bazel_dep(name = "rules_cc", version = "0.1.2")      # REQUIRED for Bazel 9 CcInfo
bazel_dep(name = "rules_shell", version = "0.5.0")
```

### Proto/gRPC Dependencies (conditional)

If ANY project uses proto/gRPC (detected in Phase 1):

```starlark
# These are NOT dev_dependency in consumer repos!
bazel_dep(name = "protobuf", version = "29.3")
bazel_dep(name = "rules_proto", version = "7.1.0")
bazel_dep(name = "grpc", version = "1.71.0")  # only if gRPC is used
```

### Toolchain Registration

```starlark
dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "{{DOTNET_VERSION}}")
use_repo(dotnet, "dotnet_toolchains")
register_toolchains("@dotnet_toolchains//:all")
```

**IMPORTANT**: Only the root module should register the default toolchain. If this repo is used as a dependency of another Bazel module, the root module's registration takes priority (breadth-first processing).

## Step 3: Generate .bazelrc

Minimum required flags:

```
startup --windows_enable_symlinks
common --enable_runfiles
common --incompatible_strict_action_env
common --test_output=errors
common --incompatible_disallow_empty_glob

# Verbose failure output
common --verbose_failures
```

For remote execution support:
```
# Remote execution — activate with --config=remote
build:remote --jobs=50
build:remote --remote_timeout=600
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0
```

The `runtime-deps:8.0` container image provides glibc 2.27+ and GLIBCXX_3.4.22+ which .NET SDK native binaries require. Using a different container will likely cause `GLIBCXX not found` errors.

## Step 4: Create Root BUILD.bazel

The root `BUILD.bazel` is usually empty or contains only visibility declarations:

```starlark
# Root BUILD.bazel
```

If the repo uses Gazelle, add the gazelle target here.

## Verification Gate

Run:
```bash
bazel build @dotnet_toolchains//:all
```

This verifies:
- MODULE.bazel parses correctly
- .NET SDK downloads successfully
- Toolchain registration works
- All required deps resolve

If this fails, check `reference/error-recovery.md` for common MODULE.bazel errors.

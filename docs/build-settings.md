# Build Settings

User-facing build settings that control rules_dotnet behavior. Set these in
your `.bazelrc` or on the command line.

## Strict Dependencies

Controls whether transitive dependencies are visible during compilation.

```
# .bazelrc — disable strict deps (allow transitive, like MSBuild default)
build --@rules_dotnet//dotnet/settings:strict_deps=false
```

| Value | Behavior |
|-------|----------|
| `true` (default) | Only direct `deps` are visible. Catches missing dependency declarations. |
| `false` | Transitive `deps` are also visible. Matches MSBuild default behavior. |

When strict deps is enabled, use `exports` on a library to re-export a
dependency without disabling strict deps globally.

## Analysis Config

Workspace-wide Roslyn analyzer enforcement. Point this at a
`dotnet_analysis_config` target.

```
# .bazelrc — enable workspace-wide analysis
build --@rules_dotnet//dotnet/private/rules/analysis:analysis_config=//:analysis
```

The target must be created in your BUILD file:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "dotnet_analysis_config")

dotnet_analysis_config(
    name = "analysis",
    analyzers = ["@nuget//stylecop.analyzers"],
    global_configs = [".globalconfig"],
    treat_warnings_as_errors = True,
    warning_level = 5,
)
```

When unset (default), no workspace-wide analyzers are applied. Per-target
analyzer attributes still work independently.

## NUnit Package Labels

Override the default NUnit and NUnitLite packages used by `csharp_nunit_test`
and `fsharp_nunit_test`.

```
# .bazelrc — use custom NUnit packages
build --@rules_dotnet//dotnet/private/rules/csharp:nunit=//my:nunit_package
build --@rules_dotnet//dotnet/private/rules/csharp:nunitlite=//my:nunitlite_package
```

This is useful if you vendor NUnit or use a different version than the
one pinned in the rules_dotnet repository.

## Compilation Mode

Standard Bazel flag, not rules_dotnet-specific, but directly affects .NET
compilation:

```
# .bazelrc — release builds in CI
common --compilation_mode=opt
```

| `--compilation_mode` | .NET behavior |
|---------------------|---------------|
| `fastbuild` (default) | Debug: no optimizations, full PDBs |
| `dbg` | Debug: no optimizations, full PDBs |
| `opt` | Release: optimizations enabled, portable PDBs |

## Remote Execution

```
# .bazelrc — BuildBuddy Cloud RE
build:remote --remote_executor=grpcs://remote.buildbuddy.io
build:remote --remote_cache=grpcs://remote.buildbuddy.io
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0

# .bazelrc.user (gitignored)
build:remote --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

Then: `bazel test //... --config=remote`

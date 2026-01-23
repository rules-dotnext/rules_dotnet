# Testing

## csharp_test / fsharp_test

The base test rules compile a C# or F# executable and run it as a Bazel test.
They accept the same attributes as their binary counterparts.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

csharp_test(
    name = "unit_tests",
    srcs = ["Tests.cs", "Program.cs"],
    target_frameworks = ["net8.0"],
    deps = [
        "@nuget//xunit",
        "@nuget//xunit.runner.utility",
    ],
)
```

The test executable must have its own entry point. For frameworks like xUnit
or MSTest, you provide the test runner entry point in `srcs`.

## csharp_nunit_test / fsharp_nunit_test

Convenience macros that wrap `csharp_test`/`fsharp_test` with NUnit framework
and runner dependencies pre-configured. No entry point needed.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

csharp_nunit_test(
    name = "my_nunit_tests",
    srcs = ["MathTests.cs"],
    target_frameworks = ["net8.0"],
    deps = [
        "//src:math_lib",
    ],
)
```

The macro automatically adds:
- `NUnit` framework package
- `NUnitLite` runner package
- A shim entry point (`shim.cs`) that discovers and runs tests

### Custom NUnit versions

Override the defaults via the macro parameters:

```starlark
csharp_nunit_test(
    name = "tests",
    srcs = ["Tests.cs"],
    target_frameworks = ["net8.0"],
    nunit = "@nuget//nunit",
    nunitlite = "@nuget//nunitlite",
    test_entry_point = ":custom_shim.cs",
)
```

## flatten_deps

When `flatten_deps = True`, all transitive dependency DLLs are copied into
the output directory alongside the main assembly. This matches MSBuild publish
behavior and is required for test runners that load assemblies from relative
paths.

```starlark
csharp_test(
    name = "integration_tests",
    srcs = ["Tests.cs"],
    target_frameworks = ["net8.0"],
    flatten_deps = True,
    deps = ["//src:myapp"],
)
```

**Warning**: This disables the probing-path optimization and increases build
times for targets with many transitive dependencies. Only use when needed.

## Coverage

`bazel coverage` is supported via `InstrumentedFilesInfo`. Run coverage the
standard Bazel way:

```sh
bazel coverage //tests:unit_tests --combined_report=lcov
```

Coverage data is collected and merged using Bazel's built-in LCOV merger. The
`_lcov_merger` attribute is automatically configured on all test rules.

## Test attributes reference

Key attributes shared by all test rules (from `BINARY_COMMON_ATTRS`):

| Attribute | Description |
|-----------|-------------|
| `srcs` | Source files (`.cs` or `.fs`) |
| `deps` | Library and NuGet dependencies |
| `target_frameworks` | TFMs to build (e.g. `["net8.0"]`) |
| `data` | Runtime files (use runfiles library to access) |
| `flatten_deps` | Copy all DLLs to output directory |
| `defines` | Preprocessor symbols |
| `resources` | Embedded resources |
| `appsetting_files` | appsettings.json files to include |
| `envs` | Environment variables for test execution |
| `roll_forward_behavior` | .NET runtime roll-forward policy |

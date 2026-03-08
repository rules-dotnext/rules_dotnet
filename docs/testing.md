# Testing

## csharp_test / fsharp_test

The base test rules compile a C# or F# executable and run it as a Bazel test.
They accept the same attributes as `csharp_binary` / `fsharp_binary`. The test
executable must have its own entry point -- you supply the runner and `Main()`
yourself. Use these rules when you need full control over the test framework, or
when using xUnit, MSTest, or another framework that ships its own runner.

xUnit example:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

csharp_test(
    name = "unit_tests",
    srcs = [
        "MathTests.cs",
        "Program.cs",
    ],
    target_frameworks = ["net9.0"],
    deps = [
        "//src:math_lib",
        "@paket.main//xunit",
        "@paket.main//xunit.runner.visualstudio",
        "@paket.main//microsoft.net.test.sdk",
    ],
)
```

```csharp
// Program.cs -- xUnit console entry point
public class Program
{
    public static int Main(string[] args) =>
        Xunit.Runner.InProc.SystemConsole.ConsoleRunner.Run(
            typeof(Program).Assembly, args);
}
```

```csharp
// MathTests.cs
using Xunit;

public class MathTests
{
    [Fact]
    public void Add_ReturnsSum()
    {
        Assert.Equal(4, 2 + 2);
    }
}
```

## csharp_nunit_test / fsharp_nunit_test

Convenience macros that wrap `csharp_test` / `fsharp_test` with NUnit
pre-configured. Three things are injected automatically:

- **NUnit** framework package
- **NUnitLite** runner package
- A **shim entry point** (`shim.cs` / `shim.fs`) that discovers and runs all
  `[Test]` methods in the assembly

No `Main()` needed. Write your test class and go:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

csharp_nunit_test(
    name = "math_tests",
    srcs = ["MathTests.cs"],
    target_frameworks = ["net9.0"],
    deps = ["//src:math_lib"],
)
```

```csharp
// MathTests.cs
using NUnit.Framework;

[TestFixture]
public class MathTests
{
    [Test]
    public void Add_ReturnsSum()
    {
        Assert.That(2 + 2, Is.EqualTo(4));
    }

    [TestCase(0, 0, 0)]
    [TestCase(1, 2, 3)]
    [TestCase(-1, 1, 0)]
    public void Add_WithCases(int a, int b, int expected)
    {
        Assert.That(a + b, Is.EqualTo(expected));
    }
}
```

### Custom NUnit versions

Override the default NUnit and NUnitLite packages via macro parameters:

```starlark
csharp_nunit_test(
    name = "tests",
    srcs = ["Tests.cs"],
    target_frameworks = ["net9.0"],
    nunit = "@paket.main//nunit",
    nunitlite = "@paket.main//nunitlite",
)
```

To replace the shim entry point entirely (e.g., to add custom setup logic),
pass `test_entry_point`:

```starlark
csharp_nunit_test(
    name = "tests",
    srcs = ["Tests.cs"],
    target_frameworks = ["net9.0"],
    test_entry_point = ":custom_shim.cs",
)
```

## flatten_deps

When `flatten_deps = True`, all transitive dependency DLLs are copied into the
output directory alongside the main assembly. This matches MSBuild publish
behavior and is required for test runners that load assemblies via relative
paths rather than the deps.json probing mechanism.

```starlark
csharp_test(
    name = "integration_tests",
    srcs = ["Tests.cs"],
    target_frameworks = ["net9.0"],
    flatten_deps = True,
    deps = ["//src:myapp"],
)
```

This disables the probing-path optimization and increases output size for
targets with deep dependency graphs. Only use it when a test runner or framework
requires it.

## Code coverage

`bazel coverage` produces LCOV output using [coverlet](https://github.com/coverlet-coverage/coverlet)
8.0.0. Coverlet is fetched automatically -- no user configuration required.

Run coverage on a test target:

```
$ bazel coverage //test:math_tests
```

The LCOV report is written to:

```
bazel-testlogs/test/math_tests/coverage.dat
```

**How it works.** When Bazel runs a test under `bazel coverage`, it sets the
`COVERAGE_DIR` and `COVERAGE_OUTPUT_FILE` environment variables. The launcher
detects these, copies the assembly into a writable temp directory (Bazel outputs
are read-only), and invokes coverlet to instrument the assembly, run the test,
and write LCOV to `$COVERAGE_OUTPUT_FILE`. Bazel's built-in LCOV merger then
aggregates results across shards and targets.

To produce a combined HTML report across multiple targets:

```
$ bazel coverage //test/... --combined_report=lcov
$ genhtml bazel-out/_coverage/_coverage_report.dat -o coverage_html
```

The output is standard LCOV and works with any tool that consumes it: `genhtml`,
VS Code Coverage Gutters, Codecov, Coveralls, and others.

**Remote execution:** `bazel coverage` works with `--config=remote`. Coverlet
instruments the assembly, runs the test on the remote worker, and writes LCOV
to `$COVERAGE_OUTPUT_FILE`. Bazel transports the coverage data back to the
client automatically.

## Test sharding

Bazel's test sharding splits test execution across parallel processes. The
rules_dotnet launcher supports sharding out of the box. To force a target to
run across N shards:

```
$ bazel test //test:math_tests --test_sharding_strategy=forced=4
```

Or set `shard_count` directly on the target:

```starlark
csharp_nunit_test(
    name = "math_tests",
    srcs = ["MathTests.cs"],
    target_frameworks = ["net9.0"],
    shard_count = 4,
)
```

The launcher touches `TEST_SHARD_STATUS_FILE` to signal shard awareness to
Bazel. Each shard runs in its own output directory and receives `TEST_SHARD_INDEX`
and `TEST_TOTAL_SHARDS` environment variables from Bazel.

## XML test output

NUnit tests automatically write NUnit3-format XML results to the path specified
by Bazel's `$XML_OUTPUT_FILE` environment variable. The built-in shim entry
point handles this:

```csharp
var xmlOutputFile = Environment.GetEnvironmentVariable("XML_OUTPUT_FILE");
if (xmlOutputFile != null)
    argsList.Add("--result=" + xmlOutputFile + ";format=nunit3");
```

No user configuration is needed. CI systems that parse Bazel test XML --
BuildBuddy, Buildkite, GitHub Actions, Jenkins -- automatically pick up
individual test case results, timings, and failure messages from this output.

## Test attributes reference

Key attributes shared by all test rules (from `BINARY_COMMON_ATTRS`):

| Attribute | Description |
|-----------|-------------|
| `srcs` | Source files (`.cs` or `.fs`) |
| `deps` | Library and NuGet dependencies |
| `target_frameworks` | TFMs to build (e.g. `["net9.0"]`) |
| `data` | Runtime files (use runfiles library to access) |
| `flatten_deps` | Copy all transitive DLLs to output directory |
| `defines` | Preprocessor symbols |
| `resources` | Embedded resources |
| `appsetting_files` | appsettings.json files included in runfiles |
| `envs` | Environment variables for test execution |
| `roll_forward_behavior` | .NET runtime roll-forward policy |
| `shard_count` | Number of parallel test shards |
| `size` | Test size (`small`, `medium`, `large`, `enormous`) -- controls default timeout |
| `timeout` | Override the default timeout (`short`, `moderate`, `long`, `eternal`) |
| `tags` | Bazel tags (e.g. `["requires-network"]`) |

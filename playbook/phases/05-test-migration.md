# Phase 5: Test Migration

## Anti-Patterns (this phase)
- NEVER include NUnit/NUnitLite in `deps` when using `csharp_nunit_test` (#2)
- NEVER include Program.cs in `srcs` for `csharp_nunit_test` (#3)
- NEVER use `glob()` for F# sources (#4)

## Goal

Migrate all test projects to the correct Bazel test rules with proper framework integration.

## Test Framework Mapping

### NUnit → `csharp_nunit_test`

`csharp_nunit_test` is a **macro** that wraps `csharp_test`. It automatically:
- Adds NUnit and NUnitLite to `deps`
- Adds `shim.cs` to `srcs` (provides the entry point)

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

csharp_nunit_test(
    name = "my_test",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**", "Program.cs"]),
    target_frameworks = ["net8.0"],
    deps = [
        "//src/MyLib:MyLib",
        # Do NOT add @nuget//nunit or @nuget//nunitlite here!
    ],
)
```

**Critical**: Exclude `Program.cs` from srcs. The macro injects its own entry point.

### xUnit → `csharp_test`

xUnit requires an explicit entry point. Create a `Program.cs`:

```csharp
// Program.cs for xUnit
public class Program
{
    public static int Main(string[] args)
    {
        return Xunit.ConsoleClient.Program.Main(args);
    }
}
```

Or use the simpler top-level approach:
```csharp
return await Xunit.ConsoleClient.Program.Main(args);
```

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

csharp_test(
    name = "my_test",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    deps = [
        "//src/MyLib:MyLib",
        "@nuget//xunit",
        "@nuget//xunit.runner.visualstudio",
        "@nuget//microsoft.net.test.sdk",
    ],
)
```

### MSTest → `csharp_test`

MSTest also requires an explicit entry point:

```csharp
// Program.cs for MSTest
public class Program
{
    public static int Main(string[] args)
    {
        return Microsoft.VisualStudio.TestPlatform.TestFramework.Main(args);
    }
}
```

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

csharp_test(
    name = "my_test",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    deps = [
        "//src/MyLib:MyLib",
        "@nuget//mstest.testframework",
        "@nuget//mstest.testadapter",
        "@nuget//microsoft.net.test.sdk",
    ],
)
```

### F# NUnit → `fsharp_nunit_test`

Same behavior as the C# version — auto-injects NUnit deps and shim.

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_nunit_test")

fsharp_nunit_test(
    name = "my_test",
    srcs = [
        "TestHelpers.fs",
        "Tests.fs",
        # Explicit order, NEVER glob
        # Do NOT include Program.fs
    ],
    target_frameworks = ["net8.0"],
    deps = [
        "//src/MyLib:MyLib",
    ],
)
```

### F# Expecto → `fsharp_test`

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "fsharp_test")

fsharp_test(
    name = "my_test",
    srcs = [
        "Tests.fs",
        "Program.fs",  # Expecto needs explicit entry point
    ],
    target_frameworks = ["net8.0"],
    deps = [
        "//src/MyLib:MyLib",
        "@nuget//expecto",
    ],
)
```

## Test Data Files

For tests that read data files at runtime:

```starlark
csharp_nunit_test(
    name = "my_test",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**", "Program.cs"]),
    data = [
        "testdata/input.json",
        "testdata/expected.xml",
    ],
    target_frameworks = ["net8.0"],
    deps = [":mylib"],
)
```

Use the `@rules_dotnet//tools/runfiles` library to resolve data file paths at runtime:
```csharp
var runfiles = Runfiles.Create();
var path = runfiles.Rlocation("myrepo/path/to/testdata/input.json");
```

## Test Sharding

Bazel test sharding is supported. The launcher template signals shard awareness by touching `$TEST_SHARD_STATUS_FILE`. Configure in BUILD:

```starlark
csharp_nunit_test(
    name = "my_test",
    shard_count = 4,
    # ...
)
```

## Coverage

Coverage works automatically with `bazel coverage //...` when:
- PDB files are in runfiles (default behavior)
- coverlet is available (registered via coverlet extension)
- `--incompatible_strict_action_env` is set

## Verification Gate

```bash
bazel test //...
```

All tests must pass. If tests fail:
1. Check for duplicate Main() entry points (NUnit + Program.cs)
2. Check for missing NuGet test framework deps (xUnit/MSTest)
3. Check for F# source ordering issues
4. See `reference/error-recovery.md` for more patterns

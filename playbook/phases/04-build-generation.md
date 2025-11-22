# Phase 4: BUILD File Generation

## Anti-Patterns (this phase)
- NEVER use `glob()` for F# sources (#4)
- NEVER batch BUILD file generation before building (#12)
- NEVER use `//conditions:default` in TFM selects without understanding the fallback (#13)

## Goal

Generate a BUILD.bazel file for each .NET project. Process in topological order (leaves first). Build after EACH file.

## Step 1: Determine Rule Kind

From the .csproj attributes parsed in Phase 1:

| Language | OutputType | SDK | Rule |
|----------|-----------|-----|------|
| C# | Library (default) | any | `csharp_library` |
| C# | Exe | default | `csharp_binary` |
| C# | Exe | web | `csharp_binary` with `project_sdk = "web"` |
| C# | test (NUnit) | any | `csharp_nunit_test` |
| C# | test (xUnit/MSTest) | any | `csharp_test` |
| F# | Library (default) | any | `fsharp_library` |
| F# | Exe | any | `fsharp_binary` |
| F# | test (NUnit) | any | `fsharp_nunit_test` |
| F# | test (xUnit/Expecto) | any | `fsharp_test` |

## Step 2: Map Source Files

### C# Projects

```starlark
srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"])
```

Additional exclusions may be needed:
- `exclude = ["obj/**", "bin/**", "Program.cs"]` for NUnit test projects (shim.cs provides the entry point)
- Generated files from source generators should NOT be in srcs (the generator runs at build time)

### F# Projects

**NEVER use glob.** F# compilation is order-sensitive. Extract the ordered list from the `.fsproj`:

```xml
<ItemGroup>
  <Compile Include="Types.fs" />
  <Compile Include="Helpers.fs" />
  <Compile Include="Library.fs" />
</ItemGroup>
```

Maps to:
```starlark
srcs = [
    "Types.fs",
    "Helpers.fs",
    "Library.fs",
]
```

## Step 3: Map Dependencies

### ProjectReference → Bazel Label

Convert relative .csproj paths to Bazel labels:

```
../MyLib/MyLib.csproj → //path/to/MyLib:MyLib
./SubProject/Sub.csproj → //path/to/current/SubProject:Sub
```

The target name is typically the project directory name (not the assembly name, unless they differ).

### PackageReference → NuGet Label

```
PackageReference Include="Newtonsoft.Json" → @nuget//newtonsoft.json
```

Package names in the NuGet hub are **lowercase**.

For Paket: `@paket.main//newtonsoft.json`

## Step 4: Map Attributes

See `reference/csproj-to-bazel-mapping.md` for the exhaustive table. Key mappings:

| .csproj | Bazel Attribute | Notes |
|---------|----------------|-------|
| `<TargetFramework>` | `target_frameworks` | Always a list, even for single TFM |
| `<Nullable>enable</Nullable>` | `nullable = "enable"` | Values: disable, enable, warnings, annotations |
| `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>` | `allow_unsafe_blocks = True` | |
| `<LangVersion>12</LangVersion>` | `langversion = "12"` | |
| `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` | `treat_warnings_as_errors = True` | |
| `<NoWarn>CS1591</NoWarn>` | `nowarn = ["CS1591"]` | Semicolon-separated in .csproj |
| `<DefineConstants>MY_CONST</DefineConstants>` | `defines = ["MY_CONST"]` | Semicolon-separated |
| `<InternalsVisibleTo>` | `internals_visible_to = [...]` | Use Bazel attr, not assembly attribute |
| `<EmbeddedResource>` | `resources = [...]` | |
| `<Content>` (appsettings) | `appsetting_files = [...]` | Binary/test rules only |
| `<AssemblyVersion>` | `version = "..."` | |
| `<RootNamespace>` | (no direct mapping) | Affects resource naming |

## Step 5: Write BUILD.bazel

For each project directory, create `BUILD.bazel`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "MyLib",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0"],
    deps = [
        "//path/to/OtherLib:OtherLib",
        "@nuget//newtonsoft.json",
    ],
    nullable = "enable",
    visibility = ["//visibility:public"],
)
```

### Visibility

- Libraries: `["//visibility:public"]` (or scope to consuming packages)
- Tests: no visibility needed (tests are terminal nodes)
- Binaries: `["//visibility:public"]` if used by other targets (e.g., publish_binary)

### Load Statements

Always load from `@rules_dotnet//dotnet:defs.bzl`:
```starlark
load("@rules_dotnet//dotnet:defs.bzl",
    "csharp_binary",
    "csharp_library",
    "csharp_nunit_test",
    "csharp_test",
    "fsharp_binary",
    "fsharp_library",
    "fsharp_nunit_test",
    "fsharp_test",
    "publish_binary",
    "razor_library",
    "resx_resource",
)
```

Only load what you use.

## Step 6: Build Immediately

After writing EACH BUILD.bazel file:

```bash
bazel build //path/to/target:target_name
```

Fix errors before moving to the next project. Common errors and fixes are in `reference/error-recovery.md`.

## Step 7: Build Equivalence Check (per target, mandatory)

After each target builds successfully, prove it produces the same assembly as `dotnet build`. This is not optional. Every target gets compared. Every divergence gets fixed before the next target is attempted.

```bash
# Build with native tooling
dotnet build path/to/Project.csproj -c Release --no-restore

# Find outputs
DOTNET_DLL="path/to/bin/Release/net8.0/Project.dll"
BAZEL_DLL=$(bazel cquery --output=files //path/to:Project 2>/dev/null | grep '\.dll$' | head -1)

# Compare — MUST report IDENTICAL or EQUIVALENT
./playbook/verify/build-equivalence.sh "$DOTNET_DLL" "$BAZEL_DLL"
```

The result MUST be IDENTICAL or EQUIVALENT. DIVERGENT is a hard failure — do not proceed to the next target. Fix the BUILD file until equivalence is achieved. See `reference/binary-comparison.md` for diagnosis.

This is not a batch check deferred to Phase 7. It runs after every single target. The cost of fixing divergence grows exponentially with distance from the source — catching it at the leaf node costs minutes; catching it at the root binary after 200 BUILD files costs hours.

## Multi-Targeting

For projects targeting multiple TFMs:

```starlark
csharp_library(
    name = "MyLib",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["net8.0", "net6.0", "netstandard2.0"],
    deps = [
        "@nuget//newtonsoft.json",
    ],
)
```

The TFM transition handles selecting the right framework version for each consumer.

## Verification Gate

Every condition must be met. There are no partial passes.

- [ ] Every target: `bazel build //path/to/target` succeeds immediately after its BUILD file is written
- [ ] Every target: `build-equivalence.sh` reports IDENTICAL or EQUIVALENT — zero DIVERGENT
- [ ] Aggregate: `bazel build //...` succeeds
- [ ] Aggregate: `build-equivalence.sh --all-targets` reports zero DIVERGENT
- [ ] Every BUILD file is canonical: minimal deps, correct visibility, all .csproj attributes mapped, no dead code

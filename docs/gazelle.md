# Gazelle: Automatic BUILD File Generation

Generate and update BUILD files for .NET projects from existing `.csproj` and `.fsproj` files.

## Setup

Add Gazelle to your `MODULE.bazel`:

```starlark
bazel_dep(name = "gazelle", version = "0.44.0", repo_name = "bazel_gazelle")
bazel_dep(name = "rules_go", version = "0.51.0")  # required by Gazelle
```

Add the Gazelle binary and run target to your root `BUILD.bazel`:

```starlark
load("@bazel_gazelle//:def.bzl", "gazelle", "gazelle_binary")

gazelle_binary(
    name = "gazelle_bin",
    languages = ["@rules_dotnet//gazelle/dotnet"],
)

gazelle(
    name = "gazelle",
    gazelle = ":gazelle_bin",
)
```

Run it:

```bash
bazel run //:gazelle
```

Gazelle scans every directory for `.csproj`/`.fsproj` files, parses them, and writes or updates BUILD files with the corresponding rules.

## What It Generates

| .csproj property | Bazel rule |
|-----------------|------------|
| `OutputType=Library` (or unset) | `csharp_library` / `fsharp_library` |
| `OutputType=Exe` or `WinExe` | `csharp_binary` / `fsharp_binary` |
| NUnit `PackageReference` detected | `csharp_nunit_test` / `fsharp_nunit_test` |
| xUnit or MSTest detected | `csharp_test` / `fsharp_test` |

Attributes populated from the project file: `srcs`, `target_frameworks`, `deps` (from `PackageReference` and `ProjectReference`), `nullable`, `allow_unsafe_blocks`, `langversion`, `resources`, `project_sdk`.

## Directives

Control Gazelle behavior with `# gazelle:` comments in BUILD files. Directives inherit to subdirectories.

**`dotnet_extension`** (default: `enabled`)

Enable or disable the dotnet Gazelle extension for a directory tree.

```python
# gazelle:dotnet_extension disabled
```

**`dotnet_default_target_framework`** (default: `net9.0`)

Target framework used when a `.csproj` does not specify `<TargetFramework>`.

```python
# gazelle:dotnet_default_target_framework net8.0
```

**`dotnet_nuget_repo_name`** (default: `paket.rules_dotnet_nuget_packages`)

The Bazel repository name that NuGet `PackageReference` entries resolve against. Set this to match your NuGet workspace — `nuget` if using the nuget module extension, or `paket.main` for paket2bazel.

```python
# gazelle:dotnet_nuget_repo_name nuget
```

**`dotnet_generation_mode`** (default: `project`)

How rules are generated. Currently only `project` mode is supported (one rule per `.csproj`/`.fsproj`).

**`gazelle:resolve`** — Override NuGet package resolution

Override automatic NuGet→label resolution for specific packages. Useful when a
package is vendored, provided by a local target, or needs a non-standard label:

```python
# gazelle:resolve dotnet Newtonsoft.Json //third_party:newtonsoft
# gazelle:resolve dotnet Grpc.Core.Api @my_grpc//grpc_core_api
```

Overrides are checked before the default `@<nuget_repo>//<package>` resolution.

## Dependency Resolution

- **NuGet packages:** `<PackageReference Include="Newtonsoft.Json">` becomes `@<nuget_repo>//newtonsoft.json`
- **Project references:** `<ProjectReference Include="..\Lib\Lib.csproj">` becomes a Bazel label resolved by relative path
- **NUnit auto-detection:** When NUnit is detected, `csharp_nunit_test` is generated and NUnit/NUnit3TestAdapter packages are excluded from `deps` (they're auto-injected by the macro)

## Limitations

The extension parses SDK-style `.csproj`/`.fsproj` files only. It does not handle:

- `<Condition>` attributes (platform-conditional items are ignored)
- `Directory.Build.props` or `Directory.Build.targets` (MSBuild property inheritance)
- Wildcard patterns in `<Compile Include="**/*.cs" />` (explicit item lists only)
- Solution files (`.sln`)
- Non-compilation rules (`publish_binary`, `razor_library`, `dotnet_pack`, proto rules) — these must be hand-written
- Multiple test frameworks in the same project (detection priority: NUnit > xUnit > MSTest; first match wins deterministically)

## What's Next

- [Migration from MSBuild](migration.md) — step-by-step migration workflow
- [Rules Reference](rules.md) — all rules and attributes
- [Getting Started](getting-started.md) — manual BUILD file setup

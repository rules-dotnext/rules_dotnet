# Migrating from MSBuild to Bazel

## Step-by-step checklist

1. **Install Bazel 8.0+** and create a `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_dotnet", version = "0.0.0")  # Replace with latest release version

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "9.0.200")
use_repo(dotnet, "dotnet_toolchains")
register_toolchains("@dotnet_toolchains//:all")
```

2. **Windows users** -- add to `.bazelrc`:

```
startup --windows_enable_symlinks
common --enable_runfiles
```

3. **Migrate NuGet dependencies** (see below).

4. **Create BUILD files** for each project. Consider using the Gazelle
   extension for automation.

5. **Verify builds**: `bazel build //...`

6. **Verify tests**: `bazel test //...`

---

## .csproj attribute mapping

| MSBuild Property | Bazel Attribute | Notes |
|-----------------|-----------------|-------|
| `<TargetFramework>` | `target_frameworks` | List of TFMs |
| `<TargetFrameworks>` | `target_frameworks` | Already multi-target |
| `<OutputType>Exe</OutputType>` | Use `csharp_binary` | |
| `<OutputType>Library</OutputType>` | Use `csharp_library` | |
| `<AssemblyName>` | `out` | Output assembly name |
| `<RootNamespace>` | Not needed | Bazel uses file-based compilation |
| `<LangVersion>` | `langversion` | e.g. `"12.0"` |
| `<Nullable>` | `nullable` | `"enable"`, `"disable"`, etc. |
| `<AllowUnsafeBlocks>` | `allow_unsafe_blocks` | Boolean |
| `<DefineConstants>` | `defines` | List of strings |
| `<TreatWarningsAsErrors>` | `treat_warnings_as_errors` | Boolean |
| `<WarningLevel>` | `warning_level` | 0-5 |
| `<NoWarn>` | `nowarn` | List of warning codes |
| `<Version>` | `version` | Assembly version string |
| `<GenerateDocumentationFile>` | `generate_documentation_file` | Boolean |
| `<InternalsVisibleTo>` | `internals_visible_to` | List of assembly names |
| `<Sdk>Microsoft.NET.Sdk.Web` | `project_sdk = "web"` | |
| `<PackageReference>` | `deps` | See NuGet migration |
| `<ProjectReference>` | `deps` | Use Bazel labels |
| `<EmbeddedResource>` | `resources` | List of files |
| `<Content>` (appsettings) | `appsetting_files` | Copied to output |
| `<PublishSingleFile>` | `single_file` on `publish_binary` | |
| `<SelfContained>` | `self_contained` on `publish_binary` | |
| `<ImplicitUsings>` | `implicit_usings` | Boolean, default True |

---

## NuGet migration

### From packages.lock.json (fastest path)

If your projects already use NuGet lock files:

```sh
# 1. Generate lock file if you don't have one
dotnet restore --use-lock-file

# 2. Augment with .nupkg hashes
./tools/nuget2bazel/augment_lock.sh packages.lock.json > packages.lock.augmented.json

# 3. Add to MODULE.bazel
```

```starlark
nuget = use_extension("@rules_dotnet//dotnet:extensions.bzl", "nuget")
nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.augmented.json",
)
use_repo(nuget, "nuget")
```

### From PackageReference (manual)

For each `<PackageReference>` in your `.csproj`:

```xml
<PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
```

Add to your Bazel `deps`:

```starlark
deps = ["@nuget//newtonsoft.json"]
```

Package IDs are lowercased and dots are preserved in the label.

### From Paket

If you already use Paket, follow the [paket2bazel docs](../tools/paket2bazel/README.md).
This is the most mature NuGet integration path.

---

## Gazelle

The [Gazelle extension](../gazelle/) can automatically generate BUILD files
from your existing .NET project structure:

```sh
bazel run //:gazelle
```

Gazelle reads `.csproj` files and generates corresponding `csharp_library`,
`csharp_binary`, and `csharp_test` targets. It is the fastest way to bootstrap
a migration.

---

## Common gotchas

### TFM transitions

Every `target_frameworks` entry creates a separate Bazel configuration. If you
see "no matching TFM" errors, ensure your dependency graph has compatible
TFMs. A `netstandard2.0` library can be consumed by `net6.0`+ targets, but
not vice versa.

### Strict deps

rules_dotnet disables transitive dependency propagation by default. If you get
"type not found" errors after migration, either:
- Add missing direct `deps` (preferred), or
- Disable strict deps: `build --@rules_dotnet//dotnet/settings:strict_deps=false`

### Launcher behavior

Bazel-built .NET binaries use a shell launcher script (Linux/macOS) or batch
file (Windows) that sets up the runfiles environment and invokes `dotnet exec`.
This differs from MSBuild's direct apphost execution. Key implications:
- `Assembly.GetEntryAssembly()` returns the DLL, not an EXE
- Working directory is the runfiles tree, not the project root
- Use the `@rules_dotnet//tools/runfiles` library to locate data files

### Debug vs Release

Bazel uses `--compilation_mode` instead of MSBuild's Configuration property:

| MSBuild | Bazel |
|---------|-------|
| `-c Debug` | `--compilation_mode=dbg` (default: `fastbuild`) |
| `-c Release` | `--compilation_mode=opt` |

### Resource files (.resx)

Use `resx_resource` to compile `.resx` files:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "resx_resource")

resx_resource(
    name = "strings",
    srcs = ["Strings.resx"],
)

csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    resources = [":strings"],
    target_frameworks = ["net8.0"],
)
```

### InternalsVisibleTo

Use the `internals_visible_to` attribute instead of the assembly attribute.
This improves build caching because Bazel can track the dependency:

```starlark
csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = ["net8.0"],
    internals_visible_to = ["mylib_tests"],
)
```

### Runfiles and file access

In MSBuild, `File.ReadAllText("data.json")` resolves relative to the executable
directory. In Bazel, data files live in the runfiles tree. Use `data = ["data.json"]`
in your BUILD rule, then access files via the `RUNFILES_DIR` environment variable
or the runfiles library at `@rules_dotnet//tools/runfiles`.

```csharp
// Bazel sets RUNFILES_DIR; files declared in `data` are available there
var runfilesDir = Environment.GetEnvironmentVariable("RUNFILES_DIR");
var path = Path.Combine(runfilesDir, "my_workspace", "path", "to", "data.json");
```

### Remote execution

Supported out of the box. The `build:remote` config in `.bazelrc` specifies a
`container-image` that provides all system dependencies -- including `libicu` --
hermetically. No manual installation on remote workers is required.

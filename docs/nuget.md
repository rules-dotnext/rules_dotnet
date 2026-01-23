# NuGet Package Management

rules_dotnet provides three approaches for managing NuGet dependencies, from
simplest to most flexible.

## Approach 1: Paket (recommended for most projects)

[Paket](https://fsprojects.github.io/Paket/) generates a deterministic lock
file that `paket2bazel` converts into Bazel repository rules.

### Setup

1. Create `paket.dependencies` in your workspace root:

```
source https://api.nuget.org/v3/index.json
framework: net8.0

nuget Newtonsoft.Json ~> 13.0
nuget NUnit ~> 3.14
```

2. Run `paket install` to generate `paket.lock`.

3. Generate Bazel targets:

```sh
bazel run @rules_dotnet//tools/paket2bazel -- \
  --dependencies-file $(pwd)/paket.dependencies \
  --output-folder $(pwd)/deps
```

4. Load the generated file in `MODULE.bazel` (or `WORKSPACE`):

```starlark
# WORKSPACE approach
load("//deps:paket.bzl", "paket")
paket()
```

5. Reference packages in BUILD files:

```starlark
csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = ["net8.0"],
    deps = [
        "@nuget//newtonsoft.json",
    ],
)
```

Package labels follow the format `@<group>.<package.name>//:lib` (lowercased).
If you only have the default `main` group, it is `@nuget//package.name`.

---

## Approach 2: NuGet module extension (bzlmod-native)

The `nuget` module extension reads standard `packages.lock.json` files or
accepts individual package declarations directly in `MODULE.bazel`.

### From a lock file

1. Generate a NuGet lock file in your .NET project:

```sh
dotnet restore --use-lock-file
```

2. Augment the lock file with `.nupkg` file hashes (required for Bazel
   integrity checking):

```sh
./tools/nuget2bazel/augment_lock.sh packages.lock.json > packages.lock.augmented.json
```

The standard NuGet `contentHash` is a hash of package *contents*, not the
`.nupkg` file. The augmentation tool downloads each package, computes the
SHA-512 of the `.nupkg`, and adds `nupkgSha512` fields. Without this,
downloads proceed without integrity verification.

3. Declare in `MODULE.bazel`:

```starlark
nuget = use_extension("@rules_dotnet//dotnet:extensions.bzl", "nuget")

nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.augmented.json",
    sources = ["https://api.nuget.org/v3/index.json"],
)

use_repo(nuget, "nuget")
```

4. Reference packages the same way:

```starlark
deps = ["@nuget//newtonsoft.json"]
```

### Individual packages

For fine-grained control, declare packages individually:

```starlark
nuget.package(
    name = "nuget",
    id = "Newtonsoft.Json",
    version = "13.0.3",
    sha512 = "sha512-HhRXKLzEjLFmSJcSALOJfK...",
    sources = ["https://api.nuget.org/v3/index.json"],
    tfms = ["net8.0"],
    deps = {
        "net8.0": [],
    },
)
```

---

## Approach 3: Direct nuget_repo (low-level)

For full control, use `nuget_repo` directly with `parse_nuget_lock_file`:

```starlark
load("@rules_dotnet//dotnet:defs.bzl", "nuget_repo", "parse_nuget_lock_file")

nuget_repo(
    name = "nuget",
    packages = parse_nuget_lock_file(
        lock_file_content = ...,
        sources = ["https://api.nuget.org/v3/index.json"],
    ),
)
```

---

## Custom feeds and authentication

### Private NuGet feeds

Pass custom source URLs to any of the approaches above:

```starlark
nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.json",
    sources = [
        "https://api.nuget.org/v3/index.json",
        "https://pkgs.dev.azure.com/myorg/_packaging/myfeed/nuget/v3/index.json",
    ],
)
```

Both V2 and V3 NuGet feed protocols are supported. V3 feeds use `index.json`
endpoints; V2 feeds use the `package/{id}/{version}` pattern.

### netrc authentication

For feeds requiring credentials, create a `.netrc` file:

```
machine pkgs.dev.azure.com
login myuser
password mytoken
```

Reference it in your package declarations:

```starlark
nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.json",
    sources = ["https://pkgs.dev.azure.com/myorg/..."],
    netrc = "//:.netrc",
)
```

### Insecure HTTP feeds

By default, Bazel rejects plain HTTP downloads without integrity hashes. For
internal feeds on trusted networks:

```starlark
nuget_archive(
    name = "some.package",
    id = "Some.Package",
    version = "1.0.0",
    sources = ["http://internal-nuget.corp/v3/index.json"],
    allow_insecure = True,
)
```

### Direct URL downloads

For Artifactory or other non-standard feeds, bypass source resolution entirely:

```starlark
nuget_archive(
    name = "some.package",
    id = "Some.Package",
    version = "1.0.0",
    url = "https://artifactory.corp/nuget/packages/Some.Package.1.0.0.nupkg",
    sha512 = "sha512-abc123...",
)
```

### Local file sources

Mount a local NuGet feed directory (useful for air-gapped builds):

```starlark
nuget.from_lock(
    name = "nuget",
    lock_file = "//:packages.lock.json",
    sources = ["file:///opt/nuget-cache"],
)
```

Supports both hierarchical layout (`{path}/{id}/{version}/{id}.{version}.nupkg`)
and flat layout (`{path}/{id}.{version}.nupkg`).

---

## nuget2bazel hash augmentation

The `tools/nuget2bazel/augment_lock.sh` script bridges the gap between NuGet's
`contentHash` and Bazel's download integrity checking.

```sh
# Augment and overwrite in place:
./tools/nuget2bazel/augment_lock.sh packages.lock.json > /tmp/augmented.json
mv /tmp/augmented.json packages.lock.json

# Use a custom source:
./tools/nuget2bazel/augment_lock.sh packages.lock.json https://pkgs.dev.azure.com/myorg/.../index.json
```

Requirements: `curl`, `jq`, `sha512sum`, `base64`.

---

## Package reference format

All NuGet packages are referenced by their lowercased ID:

| NuGet ID | Bazel label |
|----------|-------------|
| `Newtonsoft.Json` | `@nuget//newtonsoft.json` |
| `Microsoft.Extensions.Logging` | `@nuget//microsoft.extensions.logging` |
| `Google.Protobuf` | `@nuget//google.protobuf` |

Packages expose these targets: `:lib` (runtime), `:refs` (compile-time),
`:analyzers` (Roslyn analyzers), `:native` (platform-specific native libraries).

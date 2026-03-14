# NuGet Package Management

rules_dotnet provides three approaches for managing NuGet dependencies, from
simplest to most flexible.

## Choosing an approach

- **Paket** (Approach 1): Best if you already use Paket, or want a mature lock file format with SHA-512 integrity verification built in. This is the most battle-tested path.
- **NuGet module extension** (Approach 2): Best for new projects starting with `packages.lock.json` from `dotnet restore --use-lock-file`. Native bzlmod integration without external tools.
- **Direct nuget_repo** (Approach 3): For advanced users who need programmatic control over package resolution. Typically used by rule authors, not end users.

Most users should start with Approach 1 (Paket) or Approach 2 (NuGet lock file).

## Approach 1: Paket (recommended for most projects)

[Paket](https://fsprojects.github.io/Paket/) generates a deterministic lock
file that `paket2bazel` converts into Bazel repository rules.

### Setup

1. Create `paket.dependencies` in your workspace root:

```
source https://api.nuget.org/v3/index.json
framework: net9.0

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

4. Load the generated extension in `MODULE.bazel`:

```starlark
paket = use_extension("//:deps/paket.main_extension.bzl", "paket_main_extension")
use_repo(paket, "paket.main")
```

5. Reference packages in BUILD files:

```starlark
csharp_library(
    name = "mylib",
    srcs = ["Lib.cs"],
    target_frameworks = ["net9.0"],
    deps = [
        "@paket.main//newtonsoft.json",
    ],
)
```

Package labels follow the format `@paket.<group>//package.name` (lowercased).
If you only have the default `main` group, it is `@paket.main//package.name`.

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
    tfms = ["net9.0"],
    deps = {
        "net9.0": [],
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

## Which approach should I use?

| Situation | Recommended approach |
|-----------|---------------------|
| **Getting started / small projects** | `nuget.package()` tags directly in `MODULE.bazel`. Use `bazel run //tools/nuget_sha` to get SHA-512 hashes. See [examples/nuget_hello](../examples/nuget_hello/). |
| **Migrating from MSBuild / large projects** | `nuget.from_lock()` with your existing `packages.lock.json` (from `dotnet restore --use-lock-file`). Same pattern as rules\_python's `requirements_lock.txt`. |
| **Existing Paket users** | Keep using Paket + `paket2bazel`. Zero workflow change. |

For projects with fewer than ~10 NuGet dependencies, `nuget.package()` tags are
the simplest path — no lock file, no external tools, no `dotnet restore`. For
larger dependency graphs where managing transitive deps by hand isn't practical,
`from_lock` or Paket handle the closure automatically.

---

## Package reference format

All NuGet packages are referenced by their lowercased ID. The label prefix
depends on which approach you use:

- **Paket** (Approach 1): `@paket.main//package.name` (the `paket.main` prefix comes from the `use_repo` name)
- **NuGet module extension** (Approach 2): `@nuget//package.name` (the `nuget` prefix comes from the `name` parameter in `from_lock`)

| NuGet ID | Paket label | NuGet extension label |
|----------|-------------|----------------------|
| `Newtonsoft.Json` | `@paket.main//newtonsoft.json` | `@nuget//newtonsoft.json` |
| `Microsoft.Extensions.Logging` | `@paket.main//microsoft.extensions.logging` | `@nuget//microsoft.extensions.logging` |
| `Google.Protobuf` | `@paket.main//google.protobuf` | `@nuget//google.protobuf` |

Packages expose these targets: `:lib` (runtime), `:refs` (compile-time),
`:analyzers` (Roslyn analyzers), `:native` (platform-specific native libraries).

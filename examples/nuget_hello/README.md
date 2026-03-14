# NuGet Hello — minimal rules_dotnet example

A copy-pasteable starting point: C# library with a NuGet dependency (Newtonsoft.Json),
a binary that uses it, and an NUnit test.

## Run it

```sh
bazel test //...                          # build + test everything
bazel run //:hello                        # run the binary
```

## How it works

- `MODULE.bazel` declares `Newtonsoft.Json` via `nuget.package()` with an SRI SHA-512 hash.
- `BUILD.bazel` loads `csharp_library`, `csharp_binary`, and `csharp_nunit_test` from rules_dotnet.
- NUnit dependencies are injected automatically by the `csharp_nunit_test` macro.

## Getting the SHA-512 hash for a NuGet package

**Option 1** — use the helper tool (preferred):
```sh
bazel run //tools/nuget_sha -- Newtonsoft.Json 13.0.3
# prints: sha512-mbJSvHfR...
```

**Option 2** — curl + shasum:
```sh
curl -sL "https://api.nuget.org/v3-flatcontainer/newtonsoft.json/13.0.3/newtonsoft.json.13.0.3.nupkg" \
  | sha512sum | awk '{print $1}' | xxd -r -p | base64 -w0 | sed 's/^/sha512-/'
```

## Adapt for your project

1. Copy this directory and update `local_path_override` (or replace with a versioned `bazel_dep`).
2. Add your own `nuget.package()` tags for each dependency.
3. Reference packages in BUILD files as `@nuget//package.id` (lowercased).

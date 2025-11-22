# The 15 Cardinal Anti-Patterns

These are the most common mistakes when using rules_dotnet. Violating any of these will cause build failures, test failures, or non-hermetic builds that break remote execution.

Every phase document repeats the relevant subset at the top. This is the canonical list.

---

## 1. NEVER use `cd` in launcher templates

**What happens**: `cd` breaks deps.json probing paths and relative output paths. The shell launcher never changes working directory; the bat launcher must match.

**Where this matters**: `launcher.sh.tpl`, `launcher.bat.tpl`, any custom wrapper scripts.

**The fix**: Use `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH` / `PATH` for native library discovery. Use `rlocation` for file resolution.

---

## 2. NEVER include NUnit/NUnitLite in `deps` when using `csharp_nunit_test`

**What happens**: Duplicate assembly references. The `csharp_nunit_test` macro auto-injects both NUnit and NUnitLite into deps.

**The fix**: Only list your project deps in `deps`. The macro handles test framework deps.

```starlark
# WRONG
csharp_nunit_test(
    deps = ["@paket.main//nunit", "@paket.main//nunitlite", ":mylib"],
)

# RIGHT
csharp_nunit_test(
    deps = [":mylib"],
)
```

---

## 3. NEVER include Program.cs in `srcs` for `csharp_nunit_test`

**What happens**: Duplicate `Main()` entry point. The macro auto-injects `shim.cs` which contains the NUnit entry point.

**Error**: `CS0017: Program has more than one entry point defined`

**The fix**: Exclude Program.cs from srcs. If using glob: `glob(["**/*.cs"], exclude = ["obj/**", "bin/**", "Program.cs"])`.

---

## 4. NEVER use `glob()` for F# sources

**What happens**: F# compilation is order-sensitive. The compiler processes files in the order they appear in the `srcs` list. Glob returns files in an undefined order, causing compilation failures.

**The fix**: Use an explicit, ordered list matching the `<Compile>` order in the .fsproj file.

```starlark
# WRONG
fsharp_library(
    srcs = glob(["**/*.fs"]),
)

# RIGHT
fsharp_library(
    srcs = [
        "Types.fs",
        "Helpers.fs",
        "Library.fs",
    ],
)
```

---

## 5. NEVER set `target_compatible_with = ["@platforms//os:linux", "@platforms//os:macos"]`

**What happens**: `target_compatible_with` uses AND semantics — both constraints must match simultaneously. No platform is both Linux AND macOS.

**The fix**: Use `select()` on individual constraints, or use `compatible_with` (OR semantics is not available — instead, omit the attribute and use `--target_platform_fallback` or separate targets).

---

## 6. NEVER load proto rules from `@rules_dotnet//dotnet:defs.bzl`

**What happens**: Proto rules are in a separate file because they depend on `@protobuf` (for ProtoInfo), which is an optional dependency. Loading from defs.bzl will fail if protobuf isn't in the dependency graph.

**The fix**: Always load from `@rules_dotnet//dotnet:proto.bzl`.

```starlark
# WRONG
load("@rules_dotnet//dotnet:defs.bzl", "csharp_proto_library")

# RIGHT
load("@rules_dotnet//dotnet:proto.bzl", "csharp_proto_library")
```

---

## 7. NEVER use NuGet `contentHash` as Bazel integrity hash

**What happens**: NuGet's `contentHash` in packages.lock.json is a different hash algorithm/encoding than what Bazel expects for integrity verification. They are not interchangeable.

**The fix**: Use `nuget2bazel` to augment the lock file with proper `nupkgSha512` fields, or compute SHA-512 SRI hashes directly from `.nupkg` files.

---

## 8. NEVER set protobuf/rules_proto as `dev_dependency` in consumer MODULE.bazel

**What happens**: Dev dependencies are only visible to the declaring module. If your consumer repo marks protobuf as `dev_dependency`, the proto rules in rules_dotnet can't see it.

**Note**: rules_dotnet itself marks protobuf as dev_dependency because it only needs it for its own tests. Consumer repos that USE proto rules must declare it as a regular dependency.

**The fix**: In consumer MODULE.bazel:
```starlark
bazel_dep(name = "protobuf", version = "29.3")       # NOT dev_dependency
bazel_dep(name = "rules_proto", version = "7.1.0")    # NOT dev_dependency
bazel_dep(name = "grpc", version = "1.71.0")          # NOT dev_dependency, if using gRPC
```

---

## 9. NEVER omit `rules_cc` as a dependency

**What happens**: Bazel 9 requires CcInfo to be loaded from `@rules_cc//cc/common:cc_info.bzl`. Without `rules_cc` in your MODULE.bazel, builds fail on Bazel 9+.

**The fix**: Always include in MODULE.bazel:
```starlark
bazel_dep(name = "rules_cc", version = "0.1.2")
```

---

## 10. NEVER target anything other than `netstandard2.0` for source generators

**What happens**: The Roslyn compiler loads analyzers/source generators in its own process, which requires `netstandard2.0`. Any other TFM will fail to load.

**The fix**:
```starlark
csharp_library(
    name = "my_generator",
    target_frameworks = ["netstandard2.0"],
    is_analyzer = True,
    is_language_specific_analyzer = True,
)
```

---

## 11. NEVER assume host .NET SDK exists

**What happens**: rules_dotnet provides its own toolchain. Using host SDK tools breaks hermeticity and remote execution.

**The fix**: All .NET tools come from the Bazel-managed toolchain. Use `dotnet_tool` for NuGet tools. Never shell out to `dotnet` directly.

---

## 12. NEVER batch BUILD file generation before building

**What happens**: Generating all BUILD files at once then building creates an enormous error surface. A single typo in a leaf dependency cascades errors to every dependent target.

**The fix**: Build after EACH BUILD file is written. Fix errors immediately. This keeps the error surface to one target at a time.

---

## 13. NEVER use `//conditions:default` in TFM selects without understanding the fallback

**What happens**: TFM transitions select the highest compatible framework. If your `select()` default doesn't match what the transition produces, you get silent wrong behavior or build failures.

**The fix**: Enumerate all supported TFMs explicitly in select(), or ensure the default is genuinely correct for all possible incoming TFMs.

---

## 14. NEVER skip PDB files in runfiles

**What happens**: Code coverage requires PDB (Program Database) files. Without PDBs in runfiles, `bazel coverage` produces empty LCOV output.

**The fix**: Ensure `import_library` includes PDBs. The default rules already handle this — don't strip PDBs from custom rules or configurations.

---

## 15. NEVER omit `--incompatible_strict_action_env`

**What happens**: Without strict action environment, host environment variables leak into actions. This breaks remote execution because the RE worker has a different environment than the local host.

**The fix**: Always set in `.bazelrc`:
```
common --incompatible_strict_action_env
```

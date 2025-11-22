# Error Recovery Map — Top 25 Failure Patterns

Each entry: **Error Pattern** → **Root Cause** → **Fix**

---

## 1. "does not support target framework: netX.0"

**Root cause**: A dependency's `target_frameworks` list doesn't include the TFM that the consumer is building for. The TFM transition tries to find the highest compatible framework but fails.

**Fix**: Add the required TFM to the dependency's `target_frameworks` list, or add a compatible TFM (e.g., `netstandard2.0` is compatible with all `net5.0+` TFMs).

---

## 2. "CS0246: The type or namespace name '...' could not be found"

**Root cause**: Missing dependency. `rules_dotnet` uses strict deps by default — only direct dependencies are visible at compile time.

**Fix**: Add the missing assembly to `deps`. If the type comes from a transitive dependency, either:
- Add it as a direct dep, OR
- Add it to `exports` on the intermediate library

---

## 3. Integrity mismatch / SHA-512 hash mismatch

**Root cause**: The SHA-512 SRI hash in the NuGet package declaration doesn't match the downloaded `.nupkg` file.

**Fix**: Re-download the .nupkg and recompute the hash:
```bash
curl -sL "https://api.nuget.org/v3-flatcontainer/{id}/{version}/{id}.{version}.nupkg" \
  | openssl dgst -sha512 -binary | openssl base64 -A | sed 's/^/sha512-/'
```

---

## 4. "Multiple conflicting toolchains declared for name dotnet"

**Root cause**: Two modules register a default toolchain with different versions. The root module's registration takes priority.

**Fix**: Only the root module should register the default toolchain. Remove duplicate `dotnet.toolchain()` calls, or give non-root registrations unique names.

---

## 5. "GLIBCXX_3.4.22 not found" on remote execution

**Root cause**: The RE container image doesn't have the required C++ standard library version. .NET SDK native binaries (libhostpolicy.so, libcoreclr.so) need it.

**Fix**: Use `runtime-deps:8.0` container image:
```
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0
```

---

## 6. "CS0017: Program has more than one entry point defined" (NUnit)

**Root cause**: `csharp_nunit_test` auto-injects `shim.cs` which contains a `Main()`. If the test project also has `Program.cs`, there are two entry points.

**Fix**: Exclude Program.cs from srcs:
```starlark
srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**", "Program.cs"])
```

---

## 7. F# compilation order errors

**Root cause**: `glob()` was used for F# sources. F# requires files in a specific order — types must be defined before use, and the compiler processes files sequentially.

**Fix**: Use an explicit, ordered `srcs` list matching the `.fsproj` `<Compile>` order.

---

## 8. "ProtoInfo not found" / proto rules fail to load

**Root cause**: `protobuf` is not declared as a dependency in the consumer's MODULE.bazel, or it's declared as `dev_dependency`.

**Fix**: Add as a regular dependency:
```starlark
bazel_dep(name = "protobuf", version = "29.3")
bazel_dep(name = "rules_proto", version = "7.1.0")
```

---

## 9. Diamond dependency / assembly version conflict

**Root cause**: Two paths in the dependency graph require different versions of the same assembly.

**Fix**: rules_dotnet's depset ordering resolves this — the most direct dependency wins. If this causes runtime issues, pin the desired version by adding it as a direct dep to the target that needs it.

---

## 10. Coverage fails / empty LCOV output

**Root cause**: PDB files are not in runfiles, or coverlet is not configured.

**Fix**:
1. Ensure `import_library` includes PDBs (default behavior — check custom rules)
2. Verify coverlet extension is registered in MODULE.bazel
3. Ensure `--incompatible_strict_action_env` is set

---

## 11. "No matching toolchains found for types //dotnet:toolchain_type"

**Root cause**: Toolchains not registered, or registered with wrong name.

**Fix**: Ensure MODULE.bazel has:
```starlark
register_toolchains("@dotnet_toolchains//:all")
```

---

## 12. "duplicate label" in NuGet deps

**Root cause**: Same NuGet package declared twice in the hub (from multiple `from_lock` or `package` tags).

**Fix**: Deduplicate. If using multiple lock files, ensure they don't overlap, or merge into a single hub with unique packages.

---

## 13. Source generator fails to load / "Analyzer assembly ... has no analyzers in it"

**Root cause**: Source generator doesn't target `netstandard2.0`, or `is_analyzer`/`is_language_specific_analyzer` flags are not set.

**Fix**:
```starlark
csharp_library(
    target_frameworks = ["netstandard2.0"],
    is_analyzer = True,
    is_language_specific_analyzer = True,
)
```

---

## 14. "Could not load file or assembly" at runtime

**Root cause**: Runtime dependency not in runfiles. Usually a transitive NuGet package that was missed.

**Fix**: Add the missing package to deps. Check the deps.json file to understand what the runtime expects.

---

## 15. "System.DllNotFoundException" (P/Invoke)

**Root cause**: Native library not found at runtime. The launcher sets `LD_LIBRARY_PATH` but the library isn't in the expected location.

**Fix**: Use `native_deps` attribute with `cc_library` targets:
```starlark
native_deps = ["//native:mylib"]
```

---

## 16. Build works locally but fails on RE

**Root cause**: Non-hermetic dependency. Common culprits:
- Host SDK leaking via PATH
- Environment variables not scrubbed
- Implicit system library dependency

**Fix**: Set `--incompatible_strict_action_env`. Remove any host SDK references. Declare all system deps.

---

## 17. "ERROR: cannot find bazel_tools/tools/bash/runfiles/runfiles.bash"

**Root cause**: Runfiles not enabled.

**Fix**: Ensure `.bazelrc` has:
```
common --enable_runfiles
```

---

## 18. "The target framework 'netstandard2.0' is not supported by this SDK"

**Root cause**: Using a very old .NET SDK that predates the target framework, or misconfigured toolchain.

**Fix**: Ensure the SDK version supports the target TFM. SDK 8.0+ supports all modern TFMs including netstandard2.0.

---

## 19. Empty glob warning / "glob pattern matched no files"

**Root cause**: The glob pattern doesn't match any files, usually because the project has no source files in the expected location.

**Fix**: Check the project directory for source files. May need to adjust the glob pattern or use explicit srcs list. If using `--incompatible_disallow_empty_glob`, add `allow_empty = True` if intentional.

---

## 20. "external/... is not visible from target //"

**Root cause**: NuGet package target isn't visible to the consuming target.

**Fix**: NuGet hub repos typically set default visibility. If not, check the hub configuration.

---

## 21. Appsettings files not found at runtime

**Root cause**: Appsettings files not included in `appsetting_files` attribute.

**Fix**:
```starlark
csharp_binary(
    appsetting_files = [
        "appsettings.json",
    ] + glob(["appsettings.*.json"]),
)
```

---

## 22. "error CS8032: An instance of analyzer ... cannot be created"

**Root cause**: Analyzer/source generator version mismatch with the compiler, or wrong TFM.

**Fix**: Ensure the analyzer targets `netstandard2.0` and that the `Microsoft.CodeAnalysis` package version is compatible with the compiler version.

---

## 23. Windows bat launcher fails with "not found in runfiles manifest"

**Root cause**: Runfiles manifest doesn't contain the expected path. Often caused by `cd` in a wrapper script breaking rlocation paths.

**Fix**: NEVER use `cd` in launcher scripts. Use rlocation for all file access.

---

## 24. "Xunit.Sdk.TestPipelineException: No test cases were found"

**Root cause**: xUnit test project missing entry point, or test discovery doesn't work because of missing adapter package.

**Fix**: Ensure `Program.cs` exists with xUnit entry point, and `xunit.runner.visualstudio` is in deps.

---

## 25. Cache miss on warm RE build (non-hermetic action)

**Root cause**: Some action produces non-deterministic output. Common sources:
- Timestamps in generated files
- Non-deterministic iteration over maps/sets
- Host entropy leaking into build (PID, random)
- `--incompatible_strict_action_env` not set

**Fix**:
1. Set `--incompatible_strict_action_env`
2. Use `bazel aquery //target` to inspect action inputs/outputs
3. Compare outputs from two clean builds to find the divergent action
4. Fix the non-deterministic action or add `--noenable_runfiles_symlink_map` if symlink order is the issue

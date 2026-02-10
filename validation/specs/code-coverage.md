---
priority: P2
category: testing
discovered_in: Parity audit (Phase 4)
status: implemented
---

# Code Coverage Integration

## Description

The test rule declares `_lcov_merger` but the launcher doesn't invoke coverlet
or dotnet-coverage to produce LCOV data. `bazel coverage` will run tests but
produce empty coverage reports.

## Impact

No code coverage metrics available via `bazel coverage`. rules_go, rules_cc,
and rules_py all provide real coverage data.

## Implementation

Resolved via a module extension that provides `coverlet.console` as a hermetic
NuGet tool, following the same pattern as `apphost_packs`, `runtime_packs`, and
`targeting_packs`.

### Architecture

1. **Module extension** (`dotnet/private/sdk/coverlet/`) calls `nuget_repo()`
   with the `coverlet.console` 6.0.4 NuGet package, including a `tools` dict
   that triggers `dotnet_tool()` target generation.

2. **Test rule attrs** (`csharp_test`, `fsharp_test`) declare `_coverlet_console`
   pointing at `@dotnet.coverlet//coverlet.console/tools:coverlet`.

3. **`_create_launcher()`** templates the coverlet tool's rlocation path into
   `launcher.sh.tpl` via `TEMPLATED_coverlet_console`. For binary rules (no
   coverlet attr), it substitutes `"NONE"`.

4. **Launcher** checks `COVERAGE_DIR` (set by `bazel coverage`) and
   `TEMPLATED_coverlet_console != "NONE"`, then invokes the coverlet tool to
   instrument and collect LCOV data.

### Why This Is Idiomatic

- Follows the existing packs module extension pattern exactly
- Uses existing `nuget_repo` + `nuget_archive` + `dotnet_tool` pipeline
- SHA512-pinned NuGet package (hermetic)
- bzlmod-native module extension
- TFM-aware via `get_highest_compatible_target_framework()`

### Files Changed

- `dotnet/private/sdk/coverlet/` — new module extension (3 files)
- `MODULE.bazel` — extension registration
- `dotnet/private/rules/csharp/test.bzl` — `_coverlet_console` attr
- `dotnet/private/rules/fsharp/test.bzl` — `_coverlet_console` attr
- `dotnet/private/rules/common/binary.bzl` — `_create_launcher()` coverlet substitution
- `dotnet/private/launcher.sh.tpl` — coverage invocation with proper guard

# Feature Parity Matrix: rules_dotnet vs rules_go / rules_cc / rules_py

**Date:** 2026-03-12
**Branch:** `release/parity`

## Legend

- ✅ Full parity
- ⚠️ Partial (functional but incomplete)

## Core Build Infrastructure

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Hermetic toolchain | ✅ | ✅ | ✅ | ✅ | **Parity** | .NET 8/9/10; SDK hashes for linux/macOS/Windows × x64/arm64 |
| bzlmod | ✅ | ✅ | ✅ | ✅ | **Parity** | bzlmod-only (no WORKSPACE); 6 module extensions |
| Remote execution | ✅ | ✅ | ✅ | ✅ | **Parity** | 167/167 pass on BuildBuddy RE (516 remote actions, 0 local); hermetic container, Python toolchain, POSIX binary detection |
| Cross-compilation | ✅ | ✅ | partial | ✅ | **Parity** | `--platforms`, TFM transitions, RID selection |
| Deterministic output | ✅ | ✅ | N/A | ✅ | **Parity** | `/deterministic+` passed to csc and fsc |

## Dependency Management

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Dependency lockfile | ✅ (go.sum) | N/A | ✅ (requirements.txt) | ✅ | **Parity** | paket (SHA512) + NuGet `from_lock` + `package` tags |
| Transitive dep resolution | ✅ (auto) | manual | ✅ (pip) | ✅ | **Parity** | `nuget_repo.bzl` generates TFM-aware `deps = select({})` from lock file; full transitive closure auto-wired |
| Source-only packages | N/A | N/A | N/A | ✅ | **Parity** | `nuget_archive.bzl` processes `contentFiles/cs/{tfm}/` → `content_srcs` → injected into compilation |

## Testing

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Test rules | ✅ | ✅ | ✅ | ✅ | **Parity** | csharp_test, fsharp_test, csharp_nunit_test (macro) |
| Test sharding | ✅ | ✅ | ✅ | ✅ | **Parity** | Launcher touches `TEST_SHARD_STATUS_FILE`; `shard_count` attr supported |
| XML test output | ✅ | ✅ | ✅ | ✅ | **Parity** | NUnit shim writes `$XML_OUTPUT_FILE` in NUnit3 format; BES tools parse natively |
| Code coverage | ✅ | ✅ | ✅ | ✅ | **Parity** | coverlet 8.0.0 module extension; `bazel coverage` produces LCOV via writable-copy instrumentation |

## Tooling & IDE

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| IDE integration | gazelle | compile_commands.json | limited | ✅ | **Parity** | `dotnet_project` generates .csproj for OmniSharp/Rider |
| Static analysis | nogo | built-in | flake8/pylint | ✅ | **Parity** | `dotnet_analysis_config` (Roslyn analyzers, editorconfig) |
| stardoc | ✅ | ✅ | ✅ | ✅ | **Parity** | rules_api target in docs/BUILD.bazel |
| Examples | ✅ | ✅ | ✅ | ✅ | **Parity** | 12 examples covering major use cases |
| Documentation | ✅ | ✅ | ✅ | ✅ | **Parity** | 8 docs (getting-started, rules, providers, nuget, testing, publishing, advanced, migration) |

## Language Features

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Native interop | cgo | built-in | ctypes/cffi | ✅ | **Parity** | `native_deps` + CcInfo from @rules_cc |
| Proto/gRPC | ✅ | ✅ | ✅ | ✅ | **Parity** | `csharp_proto_library`, `csharp_grpc_library` |
| Source generators | N/A | N/A | N/A | ✅ | **Parity** | `is_analyzer` + `is_language_specific_analyzer` attrs |
| AdditionalFiles for generators | N/A | N/A | N/A | ✅ | **Parity** | `additionalfiles` attr → `/additionalfile:%s` compiler flag; analysis test validates |
| Packaging | go_binary | cc_shared_library | py_wheel | ✅ | **Parity** | `publish_binary`, `dotnet_pack` |
| Razor (web views) | N/A | N/A | N/A | ✅ | N/A | .NET-specific: `razor_library` |
| NativeAOT | N/A | N/A | N/A | ✅ | N/A | .NET-specific: `native_aot_binary` |

## CI & Infrastructure

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Multi-platform CI | ✅ | ✅ | ✅ | ✅ | **Parity** | ci.yml: Linux + macOS + Windows matrix; all 3 platforms fully green |
| CI workflows | ✅ | ✅ | ✅ | ✅ | **Parity** | 4 workflows: ci.yml, validation.yml, release.yml, publish.yml |

## Parity Score

- **Full parity:** 24/24 capabilities (100%)
- **Gaps:** 0/24

## Assessment

rules_dotnet achieves **full parity** with rules_go, rules_cc, and rules_py across
all measured capabilities. This includes:

- **Core build infrastructure:** hermetic toolchains, bzlmod, remote execution,
  cross-compilation, deterministic output
- **Dependency management:** lockfiles, transitive resolution, source-only packages
- **Testing:** test rules, sharding, XML output, code coverage
- **Tooling:** IDE integration, static analysis, documentation
- **Language features:** native interop, proto/gRPC, source generators, packaging
- **CI:** multi-platform workflows (Linux, macOS, Windows)

### Gap Closure Summary

| Former Gap | Resolution |
|-----------|-----------|
| Test sharding | Launcher now touches `TEST_SHARD_STATUS_FILE` |
| XML test output | NUnit shim writes `$XML_OUTPUT_FILE` in NUnit3 format |
| Multi-platform CI | ci.yml expanded to 3-platform matrix; all 3 platforms green |
| Windows runtime | Removed `cd` from `launcher.bat.tpl` to match sh launcher — fixes deps.json resolution |
| NuGet transitive deps | Already implemented (`nuget_repo.bzl` generates deps) — reclassified |
| Source-only NuGet | Already implemented (`nuget_archive.bzl` processes contentFiles) — reclassified |
| AdditionalFiles | Already implemented (`additionalfiles` attr exists) — reclassified; analysis test added |
| Code coverage | Upgraded coverlet 6.0.4→8.0.0 (Mono.Cecil 0.11.6); writable-copy instrumentation; `--exclude-assemblies-without-sources None` for sandboxed builds |

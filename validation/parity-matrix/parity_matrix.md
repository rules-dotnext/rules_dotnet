# Feature Parity Matrix: rules_dotnet vs rules_go / rules_cc / rules_py

**Date:** 2026-03-12
**Branch:** `release/parity`
**Commit:** `582660cff6934c9c25da45efa31a408faa7547e3`

## Legend

- ✅ Full parity
- ⚠️ Partial (functional but incomplete)
- ❌ Gap (not implemented)

## Core Build Infrastructure

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Hermetic toolchain | ✅ | ✅ | ✅ | ✅ | **Parity** | .NET 8/9/10, linux/macOS/Windows × x64/arm64 |
| bzlmod | ✅ | ✅ | ✅ | ✅ | **Parity** | bzlmod-only (no WORKSPACE); 4 module extensions |
| Remote execution | ✅ | ✅ | ✅ | ✅ | **Parity** | No `local=True`, `--incompatible_strict_action_env`, explicit inputs |
| Cross-compilation | ✅ | ✅ | partial | ✅ | **Parity** | `--platforms`, TFM transitions, RID selection |
| Deterministic output | ✅ | ✅ | N/A | ✅ | **Parity** | `/deterministic+` passed to csc and fsc |

## Dependency Management

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Dependency lockfile | ✅ (go.sum) | N/A | ✅ (requirements.txt) | ✅ | **Parity** | paket (SHA512) + NuGet `from_lock` + `package` tags |
| Transitive dep resolution | ✅ (auto) | manual | ✅ (pip) | ⚠️ | **Gap** | Lock file has graph but deps not auto-wired in BUILD |
| Source-only packages | N/A | N/A | N/A | ❌ | **Gap** | .NET-specific: contentFiles/cs/ packages not handled |

## Testing

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Test rules | ✅ | ✅ | ✅ | ✅ | **Parity** | csharp_test, fsharp_test, csharp_nunit_test (macro) |
| Test sharding | ✅ | ✅ | ✅ | ❌ | **Gap** | `shard_count`, `TEST_SHARD_INDEX` not in launcher |
| XML test output | ✅ | ✅ | ✅ | ❌ | **Gap** | `XML_OUTPUT_FILE` not handled in launcher |
| Code coverage | ✅ | ✅ | ✅ | ⚠️ | **Gap** | `_lcov_merger` declared but no coverlet/LCOV integration in launcher |

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
| Packaging | go_binary | cc_shared_library | py_wheel | ✅ | **Parity** | `publish_binary`, `dotnet_pack` |
| Razor (web views) | N/A | N/A | N/A | ✅ | N/A | .NET-specific: `razor_library` |
| NativeAOT | N/A | N/A | N/A | ✅ | N/A | .NET-specific: `native_aot_binary` |

## CI & Infrastructure

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status | Notes |
|-----------|---------|---------|---------|-------------|--------|-------|
| Multi-platform CI | ✅ | ✅ | ✅ | ❌ | **Gap** | Linux only; macOS/Windows workflows needed |
| CI workflows | ✅ | ✅ | ✅ | ✅ | **Parity** | 3 workflows: ci.yml, e2e.yml, release.yml |

## Gap Summary

| Gap | Priority | Estimated Effort | Spec |
|-----|----------|-----------------|------|
| Test sharding | P1 | Easy | `validation/specs/test-sharding.md` |
| XML test output | P1 | Medium | `validation/specs/xml-test-output.md` |
| Code coverage (real) | P2 | Hard | `validation/specs/code-coverage.md` |
| Multi-platform CI | P1 | Easy | `validation/specs/multi-platform-ci.md` |
| NuGet transitive deps | P1 | Easy | `validation/specs/nuget-transitive-deps.md` |
| Source-only NuGet packages | P0 | Medium | `validation/specs/source-only-nuget-packages.md` |
| AdditionalFiles for generators | P1 | Easy | `validation/specs/additional-files.md` |

## Parity Score

- **Full parity:** 17/24 capabilities (71%)
- **Partial/Gap:** 7/24 capabilities (29%)
- **Blocking gaps for real-world adoption:** 2 (source-only NuGet, NuGet transitive deps)
- **Blocking gaps for CI maturity:** 1 (multi-platform CI)

## Assessment

rules_dotnet achieves full parity with rules_go/rules_cc/rules_py on the core
build infrastructure: hermetic toolchains, bzlmod, remote execution, cross-compilation,
and deterministic output. The gaps are concentrated in two areas:

1. **Testing infrastructure** (sharding, XML output, coverage) — these affect CI
   integration quality but not build correctness.
2. **NuGet ecosystem support** (transitive deps, source-only packages) — these
   are the primary blockers for adopting rules_dotnet on real-world projects.

The NuGet gaps are unique to .NET and don't have direct analogues in other
language rulesets. Fixing them would bring the parity score to ~90%.

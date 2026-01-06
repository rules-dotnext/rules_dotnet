# Parity App — Target Map

Every BUILD target in this workspace exercises one or more gaps from the
rules_dotnet maturity plan. When `bazel test //...` passes, all gaps are closed.

## Per-Spec Isolation

Targets are split into per-spec sub-packages so each spec can be tested
independently. A spec's package only loads if its attributes/rules exist.
Other specs' failures don't block your package.

## Target → Spec Map

| Target | Spec | Issues | What it proves |
|--------|------|--------|----------------|
| `//quick_wins:versioned_lib` | spec-quick-wins | #423 | `version` attr propagates to assembly metadata |
| `//quick_wins:location_expansion` | spec-quick-wins | #524 | `$(location)` works in `compiler_options` |
| `//fsharp:fsharp_with_signatures` | spec-fsharp-enhancements | #500 | `.fsi` files accepted in `fsharp_library.srcs` |
| `//fsharp:fsharp_consumer` | spec-fsharp-enhancements | #315 | `FSharpSourceInfo` provider propagation |
| `//correctness:implicit_usings` | spec-correctness | #436 | `implicit_usings = True` injects global usings |
| `//platform:greeter_resources` | spec-platform-features | #466 | `resx_resource` compiles `.resx` to `.resources` |
| `//native:native_interop_lib` | spec-native-interop | #349 | `native_deps` attr propagates native libs |
| `//testing:greeter_test` | spec-testing-infra | #207, #359, #450 | NUnit runner, coverage, `flatten_deps` |
| `//publishing:app_single_file` | spec-publishing | #358 | `publish_binary` with `single_file = True` |
| `//publishing:lib_published` | spec-publishing | #391 | `publish_library` rule exists and works |
| `//publishing:app_aot` | spec-publishing | #484 | `native_aot_binary` produces native executable |
| `//publishing:lib_nupkg` | spec-publishing | #527 | `dotnet_pack` produces `.nupkg` |
| `//proto:greeting_csharp_proto` | spec-proto-grpc | parity | `csharp_proto_library` generates + compiles C# |
| `//proto:greeting_csharp_grpc` | spec-proto-grpc | parity | `csharp_grpc_library` generates gRPC service stubs |
| `//proto:proto_consumer` | spec-proto-grpc | parity | Generated proto types are usable from C# |
| `//razor:razor_components` | spec-razor-blazor | #249 | `razor_library` compiles `.razor` components |
| `//analysis:analysis_config` | spec-static-analysis | parity | `dotnet_analysis_config` rule exists |
| `//analysis:analyzed_lib` | spec-static-analysis | parity | Roslyn analyzers enforced at build time |
| `//ide:debuggable_lib` | spec-ide-integration | #228 | `pathmap` attr on `csharp_library` |
| `//ide:debuggable_csproj` | spec-ide-integration | #228 | `dotnet_project` generates `.csproj` |
| `//integration:app` | quick-wins + native + fsharp | #490, #526 | appsettings + cross-spec binary |
| `//integration:versioned_lib_with_resources` | quick-wins + platform | #423, #466 | version + .resx combined |
| `//integration:app_runtime_test` | quick-wins | #490, #526 | appsettings files exist at runtime |

## Specs not directly exercised by build targets

| Spec | Issues | Verification method |
|------|--------|---------------------|
| spec-quick-wins | #525 | Windows-only — CI validates |
| spec-nuget-fixes | #379, #388, #401, #431 | `tests/gap-proofs/` |
| spec-paket-fixes | #446, #468 | `bazel build //tools/paket2bazel` |
| spec-bazel-compat | #457, #476 | `tests/gap-proofs/` |
| spec-correctness | #413, #467, #477, #508 | `tests/gap-proofs/` |
| spec-nuget-resolver | #124, #444, #530 | `tests/gap-proofs/` |
| spec-gazelle-extension | #258 | `tests/gap-proofs/` |
| spec-quick-wins | #442 | Docs-only |

## Running

```bash
cd tests/parity-app

# All targets (the full parity gate)
bazel test //...

# Just one spec's targets
bazel build //quick_wins/...
bazel build //fsharp/...

# Coverage (spec-testing-infra #359)
bazel coverage //testing:greeter_test
```

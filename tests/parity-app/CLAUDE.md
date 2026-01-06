# Parity App — Agent Guide

This is a hermetic Bazel workspace that exercises every user-facing gap in rules_dotnet.
See `TARGETS.md` for the complete target-to-spec-to-issue map.

## Per-Spec Isolation

Targets are split into sub-packages by spec. Each sub-package only uses
attributes/rules from its own spec, so it loads independently of other specs.

```
quick_wins/    — spec-quick-wins (#423, #524)
fsharp/        — spec-fsharp-enhancements (#500, #315)
correctness/   — spec-correctness (#436)
platform/      — spec-platform-features (#466)
native/        — spec-native-interop (#349)
testing/       — spec-testing-infra (#207, #359, #450)
publishing/    — spec-publishing (#358, #391, #484, #527)
proto/         — spec-proto-grpc
razor/         — spec-razor-blazor (#249)
analysis/      — spec-static-analysis
ide/           — spec-ide-integration (#228)
integration/   — cross-spec targets (app binary, combined features)
```

## Verifying Your Spec

```bash
# Point the parity app at your clone
cd /home/colin/agent-<your-spec>/tests/parity-app
sed -i 's|path = "../..",|path = "/home/colin/agent-<your-spec>",|' MODULE.bazel

# Build your spec's package
bazel build //quick_wins/...    # example for spec-quick-wins
```

Your package loads independently — other specs' broken packages don't affect you.

## Stub Rules Pattern

Root `stubs.bzl` provides macros for rules not yet in upstream. They create
failing genrules with clear error messages. When you implement a spec:

1. Add your real rule to `@rules_dotnet//dotnet:defs.bzl` in your upstream clone
2. In your sub-package's BUILD.bazel, change the load from `//:stubs.bzl` to `@rules_dotnet//dotnet:defs.bzl`
3. The stub disappears; the real rule validates attributes and compiles

## Cross-Package Dependencies

Some targets depend on other specs' outputs (e.g., `//integration:app` depends
on `//quick_wins:versioned_lib`). These are in `//integration/` and only build
when all dependency specs are implemented. They are NOT required for per-spec
verification — they're the final integration gate.

## NuGet Packages

Declared in `paket.parity.bzl` with verified SHA-512 hashes. The module
extension in `paket.parity_extension.bzl` wraps the declarations.

## .bazelrc.agent

Agent-optimized settings in `.bazelrc.agent` (auto-imported via `try-import`).
Enables `--keep_going`, `--verbose_failures`, `--color=yes`, `--show_timestamps`.

## Running

```bash
cd tests/parity-app

# One spec's targets (per-spec isolation)
bazel build //quick_wins/...
bazel build //fsharp/...

# All targets (full parity gate — only passes when ALL specs done)
bazel test //...

# Coverage
bazel coverage //testing:greeter_test
```

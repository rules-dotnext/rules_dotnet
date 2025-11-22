# Phase 7: Verification

## Anti-Patterns (this phase)
- NEVER omit `--incompatible_strict_action_env` (#15)
- NEVER skip PDB files in runfiles (#14)
- NEVER assume host .NET SDK exists (#11)
- NEVER use `cd` in launcher templates (#1)

## Goal

Two independent proofs that close the adoption argument:

1. **Build equivalence**: Bazel produces the same assemblies as `dotnet build` (proves correctness)
2. **RE cache convergence**: Cold→warm remote build achieves 100% cache hits (proves hermiticity)

## Prerequisites

1. All targets build and test successfully locally (Phases 4-6 complete)
2. `dotnet` CLI available for equivalence comparison (the only time host SDK is used)
3. Remote execution endpoint configured for convergence test (BuildBuddy, EngFlow, or similar)

## Step 1: Build Equivalence Proof

This is the most powerful evidence for adoption. Run it first — it doesn't need RE.

### 1a. Build everything with both toolchains

```bash
# Restore NuGet packages for dotnet build
dotnet restore

# Build all projects with dotnet
dotnet build -c Release --no-restore

# Build all targets with Bazel
bazel build //...
```

### 1b. Run equivalence comparison

```bash
./playbook/verify/build-equivalence.sh --all-targets .
```

This disassembles every DLL from both builds, strips non-deterministic metadata (MVID, PDB checksums), and diffs the IL. The output is a report:

```
Build Equivalence Summary
═══════════════════════════════════════
Total assemblies: 247
  IDENTICAL:  241
  EQUIVALENT:   6 (IL matches, metadata differs — safe)
  DIVERGENT:    0
═══════════════════════════════════════
RESULT: PASS — all assemblies are functionally identical
```

### 1c. Diagnose divergence

If any assemblies are DIVERGENT, see `reference/binary-comparison.md` for the diagnosis table. Common causes:

| Divergence | Cause | Fix |
|-----------|-------|-----|
| Missing type | Missing dep in BUILD | Add to `deps` |
| Extra type | Extra .cs file in glob | Tighten `exclude` |
| Different method body | `#if` conditional compilation | Align `defines` |
| Different references | Wrong NuGet version | Pin in NuGet hub |

Fix divergences and re-run until 0 DIVERGENT.

### 1d. Save the report

The equivalence report is the adoption artifact. Save it:

```bash
cp /tmp/build-equivalence/report.csv evidence/build-equivalence-report.csv
```

**GATE**: 0 DIVERGENT assemblies.

## Step 2: Verify Local Build

```bash
bazel build //...
bazel test //...
```

Both must succeed before attempting RE verification.

## Step 3: Configure RE in .bazelrc

Ensure `.bazelrc` contains:

```
# Remote execution
build:remote --jobs=50
build:remote --remote_timeout=600
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0
```

And `.bazelrc.user` (gitignored) contains the endpoint:

```
build:remote --remote_executor=grpcs://your-remote-executor:port
build:remote --remote_cache=grpcs://your-remote-cache:port
build:remote --remote_header=x-buildbuddy-api-key=YOUR_KEY
```

### Container Image

The `runtime-deps:8.0` image provides:
- glibc 2.27+ (required by .NET SDK native binaries)
- GLIBCXX_3.4.22+ (required by libhostpolicy.so, libcoreclr.so)

Using a different container (e.g., `ubuntu:20.04`, `alpine`) will likely cause `GLIBCXX not found` errors.

### Python Bootstrap (if using rules_python)

If the project uses any Python tools (e.g., rules_pkg build_tar):

```
build:remote --@rules_python//python/config_settings:bootstrap_impl=script
```

This prevents the remote executor from needing `/usr/bin/env python3`.

## Step 4: Cold RE Build

```bash
bazel clean --expunge
bazel build //... --config=remote 2>&1 | tee /tmp/re-cold.log
```

Record the output. If using BuildBuddy, note the invocation URL.

Expected output: all actions execute remotely. No cache hits (first build).

## Step 5: Warm RE Build

```bash
bazel clean --expunge
bazel build //... --config=remote 2>&1 | tee /tmp/re-warm.log
```

Expected output: all actions hit remote cache. Zero remote executions.

## Step 6: Assert Convergence

Parse the Bazel build summary from the warm build:

```
INFO: X processes: Y remote cache hit, Z internal
```

If any actions show `remote` (not `remote cache hit`), the build is NOT hermetic.

### Automated Check

Use `verify/re-convergence.sh`:

```bash
./playbook/verify/re-convergence.sh /tmp/re-convergence
```

The script:
1. Runs cold build with `--config=remote`
2. Runs warm build with `--config=remote`
3. Parses build summary for cache misses
4. Exits 0 if 100% cache hits, exits 1 if any misses

## Step 7: Coverage Verification

```bash
bazel coverage //... 2>&1 | tee /tmp/coverage.log
```

Verify LCOV output exists:
```bash
find bazel-testlogs -name "coverage.dat" | head -5
```

If no coverage data:
- Check that PDB files are in runfiles
- Check that coverlet extension is registered
- Check that `--incompatible_strict_action_env` is set

## Step 8: Hermeticity Check (Optional)

Verify no host paths leak into outputs:

```bash
./playbook/verify/hermiticity-check.sh
```

This checks:
- No absolute host paths in generated files
- No references to host .NET SDK
- No implicit system dependencies

## Common RE Failures

### "GLIBCXX_3.4.22 not found"
Wrong container image. Use `runtime-deps:8.0`.

### Cache misses on warm build
Non-hermetic action. Check:
1. Is `--incompatible_strict_action_env` set?
2. Are timestamps embedded in outputs?
3. Does any action read from host filesystem?
4. Is a tool using host entropy (random, PID, etc.)?

### "Failed to fetch repository"
Network access issue on RE worker. Ensure all dependencies are fetched locally before remote build, or configure `--experimental_remote_download_regex`.

### Timeout errors
Increase `--remote_timeout` or `--jobs`. Large builds may need 900+ second timeouts.

## Verification Gate

- [ ] Build equivalence: 0 DIVERGENT assemblies (all IDENTICAL or EQUIVALENT)
- [ ] `bazel build //... --config=remote` succeeds (cold)
- [ ] `bazel build //... --config=remote` succeeds (warm)
- [ ] Warm build shows 100% remote cache hits, 0 remote executions
- [ ] `bazel coverage //...` produces LCOV output
- [ ] No host paths in build outputs

**When all assemblies are equivalent AND the warm build achieves 100% cache hits, the migration is complete: proven correct AND proven hermetic.**

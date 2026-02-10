---
priority: P1
category: CI
discovered_in: Parity audit (Phase 4)
status: implemented
implemented_in: feat/close-parity-gaps
---

# Multi-Platform CI

## Status: Implemented

### Implementation Details

**ci.yml:**
- Test job now runs on 3 platforms: ubuntu-latest, macos-latest, windows-latest
- E2E job matrix expanded to 3 OS × 5 TFM = 15 combinations
- Windows: `--output_user_root=C:/_b` to avoid MAX_PATH issues
- Stardoc generation remains Linux-only (platform-independent output)
- Bazelisk setup via `bazelbuild/setup-bazelisk@v3` on all platforms

**launcher.bat.tpl (Windows parity):**
- Added coverage support (COVERAGE_DIR + coverlet.console) matching launcher.sh.tpl
- Added TEST_SHARD_STATUS_FILE support matching launcher.sh.tpl

**validation.yml:**
- Already had multi-platform matrix (ubuntu-latest, macos-latest, windows-latest)

### Files Changed

- `.github/workflows/ci.yml` — 3-platform matrix for test + e2e jobs
- `dotnet/private/launcher.bat.tpl` — coverage + sharding support

### Verification

- CI workflow triggers on push/PR to release/parity
- All 3 platforms execute test suite independently
- Windows MAX_PATH handled via shortened output root

## Original Description

All CI workflows run on `ubuntu-latest` only. macOS and Windows are not tested.
The toolchain supports 6 platforms (linux/macOS/Windows × x64/arm64) but this
is unverified in CI.

## Original Impact

Platform-specific issues will not be caught until users report them. rules_go,
rules_cc, and rules_py all test on multiple platforms.

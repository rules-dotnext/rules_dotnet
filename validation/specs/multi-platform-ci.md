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
- Removed `cd /d "%%~dpF"` that changed working directory to assembly dir — this broke deps.json probing paths and relative output paths for tools. The sh launcher never changes working directory; the bat launcher now matches.
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
- [CI run](https://github.com/clolin/rules-dotnet-plus/actions/runs/23012231191): 18/18 jobs green — Linux 167/167, macOS 164/167, Windows 164/167, E2E 15/15

## Original Description

All CI workflows run on `ubuntu-latest` only. macOS and Windows are not tested.
The toolchain supports 6 platforms (linux/macOS/Windows × x64/arm64) but this
is unverified in CI.

## Original Impact

Platform-specific issues will not be caught until users report them. rules_go,
rules_cc, and rules_py all test on multiple platforms.

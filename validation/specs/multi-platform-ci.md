---
priority: P1
category: CI
discovered_in: Parity audit (Phase 4)
---

# Multi-Platform CI

## Description

All CI workflows run on `ubuntu-latest` only. macOS and Windows are not tested.
The toolchain supports 6 platforms (linux/macOS/Windows × x64/arm64) but this
is unverified in CI.

## Impact

Platform-specific issues (path handling, native library loading, launcher
differences) will not be caught until users report them. rules_go, rules_cc,
and rules_py all test on multiple platforms.

## Proposed Fix

Add `matrix.os: [ubuntu-latest, macos-latest, windows-latest]` to ci.yml and
e2e.yml workflows. Windows will require a `.bat` launcher equivalent or
PowerShell support in the existing launcher.

## Estimated Effort

Easy for Linux/macOS, Medium for Windows (launcher compatibility).

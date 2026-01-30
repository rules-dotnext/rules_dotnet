# Staged Visibility Plan

**Date:** 2026-03-12
**Status:** Draft — requires owner review

## Current Validation Status

| Phase | Status | Gate |
|-------|--------|------|
| Phase 0: BEP Tooling | ✅ Complete | Tools verified |
| Phase 1: Self-Test | ✅ Complete | 164/165 pass, 98.8% warm cache |
| Phase 2: Blind Integration | ⚠️ Partial | 1/5 projects attempted; 2 blocking NuGet gaps |
| Phase 3: Proof Sequence | ⚠️ Partial | 3/5 invocations complete; remote + cross-platform pending |
| Phase 4: Parity Matrix | ✅ Complete | 17/24 full parity |
| Phase 5: Doc Dry-Run | ✅ Complete | Hello World + NUnit pass; NuGet blocked |
| Phase 6: Staged Visibility | This document | |

## Readiness Assessment

### Ready for visibility
- Core build infrastructure: hermetic toolchains, bzlmod, deterministic output
- 22 functional rules covering C#/F# library/binary/test/proto/gRPC/publish/NativeAOT/Razor
- 164 passing tests + 45 analysis tests
- Comprehensive documentation (8 docs + stardoc + 12 examples)
- Proof of hermeticity via warm-rebuild cache rates

### Not yet ready
- NuGet `from_lock` has two gaps (source-only packages, transitive deps)
- Test infrastructure gaps (sharding, XML output, real coverage)
- Multi-platform CI not yet running
- Only 1/5 real-world projects attempted

## Stage 1: Owner-Only Review

**Timeline:** Immediate
**Scope:** All validation artifacts in private repo

### Checklist
- [ ] Review Phase 1 self-test summary + BEP files
- [ ] Review Phase 2 friction log + gap specs
- [ ] Review Phase 3 proof sequence (3 invocations)
- [ ] Review Phase 4 parity matrix
- [ ] Review Phase 5 onboarding report
- [ ] Decide priority order for gap fixes
- [ ] Decide whether to fix blocking NuGet gaps before Stage 2

### Artifacts to review
```
validation/self-test/summary.md
validation/projects/spectre-console/friction_log.md
validation/projects/friction_summary.md
validation/proof-sequence/summary.md
validation/parity-matrix/parity_matrix.md
validation/onboarding/onboarding_report.md
validation/specs/*.md
```

## Stage 2: Trusted Reviewers (2-3 people)

**Prerequisites:**
- Fix TFM normalization (already done)
- Fix augment_lock.sh xxd dependency (already done)
- Fix NuGet transitive dependency auto-resolution (P1 gap)
- Optionally fix source-only NuGet packages (P0 gap)
- Set up BuildBuddy for remote cache proof
- Run cross-platform CI at least once

**Scope:**
- Share BuildBuddy invocation links (proof of hermeticity)
- Share parity matrix + friction logs
- Share getting-started flow
- Request feedback on: API surface, documentation gaps, adoption blockers

**Selection criteria for reviewers:**
- Active Bazel community member with .NET experience
- rules_go or rules_py contributor (can validate parity claims)
- @purkhusid (upstream maintainer — most critical reviewer)

## Stage 3: Public Release

**Prerequisites:**
- All Stage 2 feedback addressed
- NuGet source-only package support implemented
- Multi-platform CI passing
- At least 2/5 real-world projects building successfully
- Test sharding and XML output implemented (P1 gaps)

**Actions:**
1. Tag release candidate (e.g., `v0.18.0-rc1`)
2. Publish parity matrix to repo README
3. Open PR against upstream rules_dotnet
4. Write announcement for Bazel Slack + GitHub Discussions
5. Include honest gap assessment in announcement

### Announcement template

```
## rules_dotnet parity update

rules_dotnet now achieves feature parity with rules_go/rules_cc/rules_py
on core build infrastructure:

- Hermetic .NET 8/9/10 toolchains (6 platforms)
- bzlmod-only, no WORKSPACE
- 22 rules: C#/F# library/binary/test, NUnit, proto/gRPC, publish, NativeAOT, Razor
- Hermetic NuGet with lockfile integrity
- Roslyn static analysis integration
- IDE project generation (.csproj)
- RBE-ready (--incompatible_strict_action_env, explicit inputs)
- 164 passing tests, proven hermeticity via BEP analysis

Known gaps vs other language rulesets:
- Test sharding (planned)
- XML test output (planned)
- Code coverage integration (planned)
- Multi-platform CI (in progress)

Validation artifacts (BEP streams, friction logs, parity matrix) available
in the repo under validation/.
```

## BuildBuddy Integration

When ready, add to `.bazelrc`:
```
build:buildbuddy --bes_results_url=https://app.buildbuddy.io/invocation/
build:buildbuddy --bes_backend=grpcs://remote.buildbuddy.io
build:buildbuddy --remote_header=x-buildbuddy-api-key=REDACTED
```

Keep the organization private until Stage 3.

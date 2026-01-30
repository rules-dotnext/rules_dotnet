---
priority: P2
category: testing
discovered_in: Parity audit (Phase 4)
---

# Code Coverage Integration

## Description

The test rule declares `_lcov_merger` but the launcher doesn't invoke coverlet
or dotnet-coverage to produce LCOV data. `bazel coverage` will run tests but
produce empty coverage reports.

## Impact

No code coverage metrics available via `bazel coverage`. rules_go, rules_cc,
and rules_py all provide real coverage data.

## Proposed Fix

1. Add coverlet.collector as a test dependency (via NuGet)
2. In launcher, when `COVERAGE_DIR` is set:
   - Run tests with `--collect:"XPlat Code Coverage"`
   - Convert Cobertura XML to LCOV format
   - Write to `$COVERAGE_OUTPUT_FILE`
3. The existing `_lcov_merger` attribute will handle aggregation

## Estimated Effort

Hard — requires coverlet integration, format conversion, and handling of the
instrumentation output across hermetic sandboxes.

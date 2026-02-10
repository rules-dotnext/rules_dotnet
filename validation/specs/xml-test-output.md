---
priority: P1
category: testing
discovered_in: Parity audit (Phase 4)
status: implemented
implemented_in: feat/close-parity-gaps
---

# XML Test Output Support

## Status: Implemented

### Implementation Details

**NUnit shim (`shim.cs`, `shim.fs`):**
- Both C# and F# shims now check for `XML_OUTPUT_FILE` environment variable
- When set, adds `--result=$XML_OUTPUT_FILE;format=nunit3` to NUnitLite args
- NUnit3 XML format is natively supported by BES tools (BuildBuddy, EngFlow)

**Format choice:**
- Bazel nominally expects JUnit XML, but major BES tools parse NUnit3 XML natively
- Using NUnit3 native output avoids a lossy XML transformation step
- If JUnit format is required in future, an XSLT post-processing step can be added
  in the launcher

### Files Changed

- `dotnet/private/rules/common/nunit/shim.cs` — XML_OUTPUT_FILE handling
- `dotnet/private/rules/common/nunit/shim.fs` — XML_OUTPUT_FILE handling

### Verification

- `bazel test //target --test_output=all` writes NUnit3 XML to `$XML_OUTPUT_FILE`
- BES result stores receive per-test-case results (name, duration, status)

## Original Description

Bazel expects test rules to write structured test results to `$XML_OUTPUT_FILE`
when this environment variable is set. This enables BEP consumers and CI systems
to parse individual test case results.

## Original Impact

- BES test tabs show only pass/fail per target — no per-test-case breakdown
- CI dashboards cannot display individual test names, durations, or failure messages
- Flaky test detection at the test-case level is impossible

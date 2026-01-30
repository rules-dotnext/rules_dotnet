---
priority: P1
category: testing
discovered_in: Parity audit (Phase 4)
---

# XML Test Output Support

## Description

Bazel expects test rules to write structured test results to `$XML_OUTPUT_FILE`
when this environment variable is set. This enables BEP consumers and CI systems
to parse individual test case results.

The .NET test launcher does not check for `XML_OUTPUT_FILE` or write any
structured output.

## Impact

CI systems (BuildBuddy, EngFlow, etc.) cannot display individual test case
results, only pass/fail at the target level. rules_go, rules_cc, and rules_py
all support XML test output.

## Proposed Fix

In `dotnet/private/launcher.sh.tpl`:
1. Check for `XML_OUTPUT_FILE` environment variable
2. For NUnit: use `--result=$XML_OUTPUT_FILE;format=nunit3` to write NUnit XML
3. Convert NUnit XML to JUnit XML format (Bazel's expected format) via a
   post-processing step or use `--result` with transform
4. For xUnit: use `--xml $XML_OUTPUT_FILE`

## Estimated Effort

Medium — requires NUnit→JUnit XML conversion or finding a compatible format.

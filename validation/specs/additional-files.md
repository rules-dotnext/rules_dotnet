---
priority: P1
category: missing-feature
discovered_in: Spectre.Console (Phase 2)
status: implemented
implementation_note: Already implemented; reclassified from gap to parity. Analysis test added.
---

# AdditionalFiles Support for Source Generators

## Status: Implemented (was already in codebase)

### Evidence

This feature was filed as a gap but is **already fully implemented**:

1. **`attrs.bzl:250-256`** — `additionalfiles` attribute defined in
   `CSHARP_COMMON_ATTRS` with `allow_files = True`
2. **`csharp_assembly.bzl:632`** — Files passed to compiler as
   `/additionalfile:%s` format flag
3. **`csharp_assembly.bzl:666`** — `additionalfiles` included in direct
   action inputs for dependency tracking

Available on: `csharp_library`, `csharp_binary`, `csharp_test`,
`csharp_nunit_test` (all rules using `CSHARP_COMMON_ATTRS`).

### Verification

Analysis test added: `//dotnet/private/tests/additionalfiles`
- `csharp_additionalfile_flag_test` — verifies `/additionalfile:` flag in
  CSharpCompile action args when `additionalfiles` attribute is set
- `csharp_no_additionalfile_flag_test` — verifies flag is absent when
  attribute is not set
- Both tests pass (167/167 total)

### Usage

```starlark
csharp_library(
    name = "my_lib",
    srcs = ["Lib.cs"],
    additionalfiles = [":config.json"],
    target_frameworks = ["net8.0"],
    deps = ["@nuget//some.source.generator"],
)
```

## Original Description

Roslyn source generators can receive input data via `AdditionalFiles`, which are
files passed to the compiler with `/additionalfile:path` flags.

## Why This Was Misclassified

The gap was filed based on Spectre.Console's source generators not producing
output. The `additionalfiles` attribute exists but the specific AdditionalFiles
for Spectre.Console were not configured in the BUILD file.

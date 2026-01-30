---
priority: P1
category: missing-feature
discovered_in: Spectre.Console (Phase 2)
---

# AdditionalFiles Support for Source Generators

## Description

Roslyn source generators can receive input data via `AdditionalFiles`, which are
files passed to the compiler with `/additionalfile:path` flags. MSBuild projects
use `<AdditionalFiles Include="Data/config.json" />` to configure this.

rules_dotnet has no equivalent. Source generators that depend on AdditionalFiles
(like Spectre.Console's color/emoji/spinner generators) will compile but produce
no output.

## Impact

Source generators that use AdditionalFiles are very common in the .NET ecosystem.
Without this, many real-world projects cannot use their source generators under
Bazel.

## Proposed Fix

Add an `additional_files` attribute to `csharp_library`, `csharp_binary`, and
`csharp_test` rules. Each file in the list gets passed to the compiler via
`/additionalfile:{path}`.

## Estimated Effort

Easy — single attribute addition and compiler flag wiring.

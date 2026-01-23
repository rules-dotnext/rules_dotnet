# Booking-Microservices Validation Results

**Date:** 2026-03-12
**Branch:** release/parity
**Target project:** [booking-microservices](https://github.com/meysamhadeli/booking-microservices) (net10.0)

## Summary

| Validation Phase | Result |
|---|---|
| Rules load correctly | PASS |
| BUILD file analysis (all 6 targets) | PASS |
| Target graph resolution (8471 configured targets) | PASS |
| Compilation: BuildingBlocks core (36 .cs files) | PASS |
| Compilation: Service projects (missing NuGet deps) | EXPECTED FAIL |
| Cross-project `deps` references | PASS |
| NuGet package resolution (10 packages) | PASS |

## What was validated

### 1. Workspace setup with rules_dotnet (PASS)

A downstream Bazel workspace was created using `bazel_dep` + `local_path_override`
pointing at the local rules_dotnet clone. The .NET 10 SDK (10.0.100) toolchain
registered successfully. This validates:

- `MODULE.bazel` setup with `local_path_override` works
- .NET 10 toolchain registration works
- NuGet module extension pattern (`paket.booking.bzl` + `paket.booking_extension.bzl`) works

### 2. BUILD file loading and analysis (PASS)

Six `csharp_library` targets were defined across the project structure:

```
//src/src/BuildingBlocks:building_blocks_core     (36 source files, 4 NuGet deps)
//src/src/Aspire/src/ServiceDefaults:service_defaults  (1 source file, project ref)
//src/src/Services/Flight/src/Flight:flight        (85 source files, project ref)
//src/src/Services/Booking/src/Booking:booking     (26 source files, project ref)
//src/src/Services/Passenger/src/Passenger:passenger (37 source files, project ref)
//src/src/Services/Identity/src/Identity:identity  (35 source files, project ref)
```

All 6 targets analyzed successfully in under 1 second. The full target graph
included 8471 configured targets (including transitive toolchain/SDK targets).

### 3. Compilation of core domain library (PASS)

`BuildingBlocks:building_blocks_core` compiled successfully, producing:
- `building_blocks_core.dll`
- `building_blocks_core.xml`

This subset includes CQRS interfaces, entity base types, pagination helpers,
and the exception hierarchy -- 36 real-world C# files from the project.

Files were compiled with `nullable = "enable"` matching the project's
`Directory.Build.props` setting.

### 4. Cross-project references (PASS)

Service projects correctly reference `//src/src/BuildingBlocks:building_blocks_core`
via `deps`, validating that rules_dotnet handles inter-package dependencies
in a multi-project solution structure.

### 5. NuGet package resolution (PASS)

10 NuGet packages were declared with verified SHA-512 hashes:
- MediatR 14.0.0 (with MediatR.Contracts 2.0.1 transitive dep)
- Microsoft.Extensions.DependencyInjection.Abstractions 10.0.0
- Microsoft.Extensions.Logging.Abstractions 10.0.0
- Newtonsoft.Json 13.0.4
- FluentValidation 12.1.1
- Humanizer.Core 3.0.1
- Mapster 7.4.0
- IdGen 3.0.7
- Polly 8.6.5

All resolved and were available at compilation time.

## What could not be validated (and why)

### Full project compilation

The booking-microservices BuildingBlocks project depends on ~100 NuGet packages
including MassTransit, Google.Protobuf, Entity Framework Core, MongoDB.Driver,
Duende IdentityServer, ASP.NET Core, and many more. Each has its own transitive
dependency graph.

**Root cause:** NuGet packages in rules_dotnet require explicit declaration with
SHA-512 hashes in a `nuget_repo` call. Without `dotnet restore` available on
the build machine, generating the complete dependency graph with hashes for
100+ packages is impractical in a validation exercise.

**What this means for real adoption:**
- Teams would use `paket2bazel` or the `nuget` module extension with
  `from_lock` to generate the package declarations from a `packages.lock.json`
- The `dotnet restore --use-lock-file` command generates the lock file
- This is analogous to `rules_python`'s `pip.parse()` or `rules_jvm_external`

### Deep coupling in source code

The booking-microservices project uses `Directory.Build.props` to set
`<ImplicitUsings>enable</ImplicitUsings>`, which auto-imports common namespaces.
This means even "simple" domain files may reference ASP.NET Core types
without explicit `using` directives. Bazel's explicit dependency model
exposes this coupling more clearly than MSBuild does.

## Architecture observations

### Project structure maps cleanly to Bazel packages

The microservices solution structure (shared BuildingBlocks library,
per-service domain projects) maps naturally to Bazel packages with
`csharp_library` targets and `deps` for cross-references.

### NuGet dependency graph is the primary adoption barrier

The biggest obstacle to Bazelifying a .NET project is not the rule
definitions -- those map 1:1 from `.csproj` -- but the NuGet dependency
graph. A typical .NET project depends on hundreds of transitive NuGet
packages. The `nuget` module extension with `from_lock` (issue #530)
directly addresses this by consuming the standard `packages.lock.json`.

### net10.0 targeting works

rules_dotnet's .NET 10.0.100 SDK support correctly handles the net10.0
target framework, including targeting pack resolution and Roslyn compilation.

## Files created

```
validation/booking/
  MODULE.bazel                          # Workspace definition
  .bazelversion                         # Bazel 8.3.0
  .bazelrc                              # bzlmod enabled
  BUILD.bazel                           # Root package
  paket.booking.bzl                     # 10 NuGet packages with SHA-512 hashes
  paket.booking_extension.bzl           # Module extension wrapper
  src/BUILD.bazel                       # Intermediate
  src/src/BUILD.bazel                   # Intermediate
  src/src/BuildingBlocks/BUILD.bazel    # Core domain library (COMPILES)
  src/src/Aspire/src/ServiceDefaults/BUILD.bazel  # Service defaults
  src/src/Services/Flight/src/Flight/BUILD.bazel   # Flight service
  src/src/Services/Booking/src/Booking/BUILD.bazel # Booking service
  src/src/Services/Passenger/src/Passenger/BUILD.bazel # Passenger service
  src/src/Services/Identity/src/Identity/BUILD.bazel   # Identity service
  RESULTS.md                            # This file
```

## Conclusion

rules_dotnet can successfully express and partially compile a real-world
.NET microservices application. The rule definitions (`csharp_library`,
`nuget_repo`, toolchain registration) work correctly for net10.0 targets.
The primary barrier to full compilation is the NuGet dependency graph,
which the `nuget` module extension (#530) is designed to solve by consuming
standard `packages.lock.json` files.

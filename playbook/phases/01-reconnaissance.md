# Phase 1: Reconnaissance

## Anti-Patterns (this phase)
- NEVER assume host .NET SDK exists (#11)
- NEVER batch BUILD file generation before building (#12)

## Goal

Produce a complete classification matrix of the .NET repository. Every decision in subsequent phases depends on accurate reconnaissance.

## Step 1: Discover Solution and Project Files

Find all `.sln`, `.csproj`, and `.fsproj` files:

```bash
find . -name "*.sln" -o -name "*.csproj" -o -name "*.fsproj" | sort
```

Ignore files under `bin/`, `obj/`, `node_modules/`, and `.git/`.

## Step 2: Parse Each Project File

For each `.csproj` / `.fsproj`, extract:

### Target Framework(s)
```xml
<TargetFramework>net8.0</TargetFramework>
<!-- or multi-targeting -->
<TargetFrameworks>net8.0;net6.0;netstandard2.0</TargetFrameworks>
```

Map to rules_dotnet TFM strings: `net8.0`, `net6.0`, `netstandard2.0`, etc. See `reference/tfm-compatibility.md` for the complete chain.

### Output Type
```xml
<OutputType>Exe</OutputType>     <!-- → csharp_binary / fsharp_binary -->
<OutputType>Library</OutputType> <!-- → csharp_library / fsharp_library (default) -->
```

If `OutputType` is absent, it defaults to `Library`.

### SDK Type
```xml
<Project Sdk="Microsoft.NET.Sdk">           <!-- project_sdk = "default" -->
<Project Sdk="Microsoft.NET.Sdk.Web">       <!-- project_sdk = "web" -->
<Project Sdk="Microsoft.NET.Sdk.Razor">     <!-- project_sdk = "web" + razor_library -->
<Project Sdk="Microsoft.NET.Sdk.Worker">    <!-- project_sdk = "default" (worker services) -->
```

### Package References
```xml
<PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
```

Collect all: `{id, version}` pairs. These drive Phase 3 NuGet resolution.

### Project References
```xml
<ProjectReference Include="..\MyLib\MyLib.csproj" />
```

These become `deps` labels in BUILD files. Build the full dependency graph from these.

### Test Framework Detection

Detect by PackageReference:
- `NUnit` + `NUnit3TestAdapter` → NUnit → `csharp_nunit_test`
- `xunit` + `xunit.runner.visualstudio` → xUnit → `csharp_test` + Program.cs
- `MSTest.TestFramework` + `MSTest.TestAdapter` → MSTest → `csharp_test` + Program.cs
- `Expecto` → Expecto (F#) → `fsharp_test`

### Special Features

Flag each project for:
- **Proto/gRPC**: Has `<Protobuf Include="...">` or references `Grpc.Tools`, `Google.Protobuf`
- **Razor**: Has `.cshtml` or `.razor` files, or SDK is `Microsoft.NET.Sdk.Razor`
- **Source generator**: References a project marked as analyzer, or has `<IsRoslynComponent>true</IsRoslynComponent>`
- **Native interop**: Has `[DllImport]` usage or `<NativeReference>` elements
- **RESX resources**: Has `.resx` files
- **Nullable**: `<Nullable>enable</Nullable>`
- **Unsafe code**: `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>`
- **InternalsVisibleTo**: `[assembly: InternalsVisibleTo("...")]` in AssemblyInfo.cs or `<InternalsVisibleTo>`

## Step 3: Build Dependency Graph

From ProjectReferences, construct a directed acyclic graph (DAG).

**Cycle detection**: If cycles exist, the migration CANNOT proceed. .NET allows circular ProjectReferences in some cases (using `ReferenceOutputAssembly=false`), but Bazel does not permit dependency cycles. Resolution options:
1. Merge the cyclic projects into a single `csharp_library`
2. Extract the shared interface into a new library that both depend on
3. Use `exports` to break the apparent cycle

**Topological sort**: Order projects from leaves (no deps) to roots (depended on by nothing). This is the order for Phase 4 BUILD generation.

## Step 4: Identify Independent Clusters

Find connected components in the undirected version of the dependency graph. Independent clusters can be:
- Migrated in parallel by sub-agents
- Built/tested independently
- Assigned separate NuGet hubs if needed

## Step 5: Produce Classification Matrix

Create a summary table:

```
| Project | Language | Type | TFMs | Test Framework | SDK | Special Features |
|---------|----------|------|------|----------------|-----|------------------|
| MyLib   | C#       | lib  | net8.0 | -            | default | nullable, resx |
| MyApp   | C#       | exe  | net8.0 | -            | web | razor, proto |
| MyTest  | C#       | test | net8.0 | NUnit        | default | - |
```

Plus aggregate counts:
- Total projects by type (lib/exe/test)
- TFM distribution
- Test framework distribution
- Feature flags summary

## Verification Gate

- [ ] All .csproj/.fsproj files parsed
- [ ] Dependency graph is acyclic
- [ ] Classification matrix complete
- [ ] Independent clusters identified
- [ ] Highest TFM identified (drives SDK version in Phase 2)

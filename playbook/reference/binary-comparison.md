# Build Equivalence: Binary Comparison Methodology

## Why This Matters

RE cache convergence proves hermiticity (same inputs → same outputs within Bazel). But stakeholders need stronger proof: **Bazel produces the same assembly that `dotnet build` would.** This is the difference between "trust us, it's deterministic" and "here's the diff — it's empty."

Build equivalence is the single most powerful adoption tool. When a principal engineer can see that `bazel build` and `dotnet build` produce byte-identical IL, the "but what if Bazel changes the output" objection evaporates.

## What rules_dotnet Already Does

The compiler infrastructure is designed for equivalence:

1. **`/deterministic+`** — Roslyn and F# compiler flag. Ensures output is a function of inputs only (no timestamps, no random MVIDs, no PID-derived entropy).

2. **`-pathmap:$PWD=.`** — Injected at execution time by `compiler_wrapper.sh`/`.bat`. Strips absolute sandbox paths from PDB source references, making PDBs path-independent.

3. **`/utf8output`** — Consistent text encoding.

4. **`/filealign:512`** — Consistent PE file alignment (matches MSBuild default).

## Comparison Levels

### Level 1: IL Equivalence (recommended default)

Compare the Intermediate Language (IL) code of both assemblies after stripping non-deterministic metadata. This proves the compiled code is functionally identical.

**What to strip before comparison:**
- **MVID** (Module Version ID) — a GUID that differs per compilation even with `/deterministic+` when inputs differ by path
- **PDB checksum** in PE header — tied to the PDB, which has path differences
- **Debug directory entries** — contain PDB references with absolute paths
- **Assembly MVID custom attribute** — embeds the MVID value

**What must match:**
- All IL method bodies
- Type definitions, fields, properties, events
- Assembly references (by name and version)
- Embedded resources
- Custom attributes (except MVID-related)
- Public API surface

### Level 2: Metadata Equivalence (fast sanity check)

Compare assembly metadata without disassembling IL. Good for quick validation of large repos.

**Checks:**
- Assembly identity (name, version, culture, public key token)
- All exported types and their members
- Referenced assembly identities
- Embedded resource names and sizes
- Module-level attributes

### Level 3: Byte-Identical (gold standard, achievable with effort)

With careful alignment of all compiler inputs, Roslyn's `/deterministic+` produces byte-identical output. This requires:

- Identical reference assembly order
- Identical defines
- Identical compiler version
- Identical source file order and content
- Path-normalized PDB settings

When `dotnet build` and `bazel build` use the exact same Roslyn version (from the same SDK) with the same flags and the same reference order, byte identity is achievable.

## The Comparison Script

`verify/build-equivalence.sh` automates the comparison:

```
1. Run `dotnet build` on the .NET project → collect output DLL + PDB
2. Run `bazel build` on the same target → collect output DLL + PDB
3. Disassemble both DLLs to IL text (using `dotnet-ildasm` or `ikdasm`)
4. Strip non-deterministic metadata (MVID, PDB checksums, debug directory)
5. Diff the normalized IL text
6. Report: IDENTICAL, EQUIVALENT (IL matches, metadata differs), or DIVERGENT
```

## How to Read the Results

### IDENTICAL (exit 0)
The assemblies are byte-identical or IL-identical after MVID/PDB stripping. **This is the proof.** Show this to stakeholders.

### EQUIVALENT (exit 0, with warnings)
IL code matches but metadata differs in expected ways:
- Different MVID (expected — different input paths)
- Different PDB checksums (expected — different PDB content)
- Different assembly file version attributes (if version is injected differently)

Still safe. The runtime behavior is identical.

### DIVERGENT (exit 1)
IL code differs. Investigate:

| Divergence | Likely Cause | Fix |
|-----------|-------------|-----|
| Missing type | Missing dependency in BUILD | Add to `deps` |
| Extra type | Extra source file in glob | Tighten `exclude` pattern |
| Different method body | Conditional compilation (#if) | Align `defines` attribute |
| Different references | Different NuGet package version | Pin version in NuGet hub |
| Missing resource | Embedded resource not in `resources` | Add `resx_resource` or `resources` |
| Extra `[InternalsVisibleTo]` | Assembly attribute vs Bazel attribute | Use Bazel `internals_visible_to` only |

## Integration with Migration Phases

### During Phase 4 (BUILD Generation)

After each BUILD file passes `bazel build`, optionally run the equivalence check:

```bash
# Build with dotnet
dotnet build path/to/Project.csproj -c Release --no-restore
DOTNET_DLL="path/to/bin/Release/net8.0/Project.dll"

# Build with Bazel
bazel build //path/to:Project
BAZEL_DLL=$(bazel cquery --output=files //path/to:Project 2>/dev/null | grep '\.dll$' | head -1)

# Compare
./playbook/verify/build-equivalence.sh "$DOTNET_DLL" "$BAZEL_DLL"
```

### During Phase 7 (Verification)

Run equivalence checks on ALL assemblies as the final proof:

```bash
./playbook/verify/build-equivalence.sh --all-targets
```

## Stakeholder Evidence Format

When presenting to stakeholders, produce a comparison report:

```
Build Equivalence Report — MyApp (247 assemblies)
══════════════════════════════════════════════════
IDENTICAL:  241 assemblies (97.6%)
EQUIVALENT:   6 assemblies (2.4%) — MVID/PDB metadata only
DIVERGENT:    0 assemblies (0.0%)

Conclusion: Bazel build output is functionally identical
            to dotnet build output for all 247 assemblies.
```

This is the evidence that closes the adoption argument.

## Tools Required

The comparison uses tools available from NuGet:

1. **`ikdasm`** or **`dotnet-ildasm`** — IL disassembly (NuGet tool, cross-platform)
2. **`System.Reflection.Metadata`** — Programmatic metadata reading (NuGet package)
3. **`sn -T`** — Strong name token verification (part of .NET SDK)

The verification script bootstraps these via `dotnet tool install` or Bazel's own toolchain.

## Known Acceptable Differences

These differences are expected and do NOT indicate divergence:

1. **MVID**: Always different between `dotnet build` and `bazel build` (different input paths feed the deterministic hash)
2. **PDB reference in PE header**: Different PDB file paths
3. **Source Link JSON**: Different repository/path metadata
4. **`AssemblyInformationalVersionAttribute`**: May include source revision metadata
5. **Compilation relaxations**: `dotnet build` may inject `[assembly: CompilationRelaxations(8)]` and `[assembly: RuntimeCompatibility(WrapNonExceptionThrows = true)]` — Bazel does too, but order may differ

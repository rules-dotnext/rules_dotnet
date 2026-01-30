# rules_dotnet Rewrite — Validation & Proof Phase: Planning Session Prompt

## Context for this session

You are entering a planning session for the next phase of an ambitious project: a complete rewrite of `rules_dotnet` (https://github.com/bazel-contrib/rules_dotnet) intended to compete on features and maturity with `rules_go`, `rules_cc`, and `rules_py`.

Prior sessions have completed the implementation phase. This session's job is to design the **empirical validation and confidence-building phase** — the work that produces proof artifacts the Bazel community will recognize as credible evidence of maturity.

The owner of this project needs to review all proof artifacts privately before any public visibility. Build your plan around a staged audience model: owner-only first, then selectively broadened.

---

## The core thesis

The Bazel community does not evaluate rulesets by reading source code. They evaluate them by observable build behavior. The single most credible proof artifact is a **Build Event Protocol (BEP) stream** from a real invocation against a non-trivial project, rendered through tooling the community already uses daily (BuildBuddy, BEP JSON, timing profiles).

Your plan must produce these artifacts and structure a review pipeline around them.

---

## What you must discover first

Before planning anything, you need to assess the current state. Do the following:

1. **Inventory the implemented rules.** What rule types exist? (`dotnet_binary`, `dotnet_library`, `dotnet_test`, `dotnet_nunit_test`, `nuget_package`, etc.) What's declared but stubbed? What's missing entirely?

2. **Inventory toolchain support.** Does toolchain resolution work? Which SDK versions? Is there a `dotnet_register_toolchains` or equivalent? Does it support `--platforms` correctly?

3. **Inventory NuGet integration.** Is there a `nuget_deps` / `nuget_package` / lockfile mechanism? Can it resolve transitive dependencies? Does it produce hermetic actions or shell out to `dotnet restore` at build time?

4. **Inventory bzlmod support.** Is there a `MODULE.bazel`? Extension modules? Or is it WORKSPACE-only?

5. **Check for test infrastructure.** Does `bazel test` produce structured XML test output? Does test sharding work? Timeout handling?

6. **Check remote execution readiness.** Are actions hermetic? Do they declare all inputs? Is the toolchain resolved without host SDK leakage?

Only after this inventory should you proceed to planning.

---

## The validation plan structure

Design a plan with these phases. Each phase gates the next — do not proceed to a later phase until the owner has reviewed the outputs of the current one.

### Phase 1: Self-hosted smoke test

**Goal:** Can the rules build themselves and their own test suite?

- Run `bazel build //...` and `bazel test //...` within the rules_dotnet repository itself
- Capture BEP output: `bazel test //... --build_event_json_file=self_test.bep.json`
- Capture timing profile: `bazel test //... --profile=self_test.profile.gz`
- Parse the BEP JSON and produce a summary: total actions, pass/fail/skip test count, any action failures, any uncacheable actions

**Owner review gate:** Summary report + raw BEP file. Owner decides whether to proceed.

### Phase 2: Blind integration against real .NET projects

**Goal:** Can unrelated, real-world .NET projects build under these rules without modification to the rules themselves?

Select 3-5 open-source .NET projects that were never consulted during development. Prioritize diversity:

| Archetype | Why it matters | Example candidates |
|-----------|---------------|-------------------|
| Console app + NuGet deps | Baseline functionality | Any small CLI tool |
| ASP.NET Core web service | Most common real-world use case | eShop reference app, clean architecture templates |
| Multi-target library (net6.0 + net8.0) | Tests TFM resolution, a known hard problem | Polly, Humanizer, any library with multiple TFMs |
| Project using source generators | Tests Roslyn analyzer/generator integration | System.Text.Json usages, MediatR |
| Native interop / P/Invoke | Tests platform-dependent compilation | ImageSharp, SkiaSharp bindings |

For each project:

1. Write BUILD files from scratch using only the rules' public API and existing documentation
2. Attempt `bazel build //...` and `bazel test //...`
3. Capture BEP for every invocation
4. Document every friction point: things that required workarounds, missing features, confusing API, silent failures

**Deliverable per project:**

```
project_name/
  BUILD.bazel          # The build files written
  cold_build.bep.json  # First build from clean state
  warm_rebuild.bep.json # Immediate re-run, no changes (proves hermeticity via cache hits)
  incremental.bep.json  # After changing one source file (proves correct dep graph)
  friction_log.md       # Every point of difficulty, categorized
```

**Owner review gate:** Friction logs + BEP summaries. This is the most important review point. The friction logs tell you what the community will complain about. The cache hit rate on warm rebuilds tells you whether hermeticity is real.

### Phase 3: The five-invocation proof sequence

For the single most representative project from Phase 2, produce the canonical proof sequence:

1. **Cold build** — all actions execute, nothing cached → proves correctness
2. **Warm rebuild (no changes)** — 100% cache hit rate → proves hermeticity
3. **Incremental rebuild (one file changed)** — minimal re-execution → proves dependency graph accuracy
4. **Remote execution run** (if RBE infra is available) — same build on RBE → proves sandboxing
5. **Cross-platform build** — same project on a different OS → proves toolchain resolution

Each invocation captures:
- BEP JSON (`--build_event_json_file`)
- Timing profile (`--profile`)
- Execution log (`--execution_log_json_file`) for hermeticity debugging if needed

**Deliverable:** A summary table:

| Invocation | Total Actions | Cache Hits | Cache Rate | Failures | Platform |
|-----------|--------------|------------|------------|----------|----------|
| Cold build | N | 0 | 0% | 0 | linux-x86_64 |
| Warm rebuild | N | N | 100% | 0 | linux-x86_64 |
| Incremental | N | N-k | (N-k)/N% | 0 | linux-x86_64 |
| RBE | N | ... | ... | 0 | linux-x86_64 (remote) |
| Cross-platform | N | 0 | 0% | 0 | macos-arm64 |

Plus links to full BEP files and, if BuildBuddy is configured, invocation URLs.

**Owner review gate:** This table and the underlying data. If warm rebuild cache rate is not 100%, hermeticity is broken and must be fixed before proceeding.

### Phase 4: Feature parity audit

Produce a concrete feature comparison matrix against the contemporaries. Research what `rules_go`, `rules_py`, and `rules_cc` expose, then map each capability:

| Capability | rules_go | rules_cc | rules_py | rules_dotnet | Status |
|-----------|---------|---------|---------|-------------|--------|
| Hermetic toolchain | ✅ | ✅ | ✅ | ? | |
| bzlmod support | ✅ | ✅ | ✅ | ? | |
| Remote execution | ✅ | ✅ | ✅ | ? | |
| Test sharding | ✅ | ✅ | ✅ | ? | |
| Test output (XML) | ✅ | ✅ | ✅ | ? | |
| Dependency lockfile | ✅ (go.sum) | N/A | ✅ (requirements.txt) | ? | |
| IDE integration | gazelle | compile_commands | ? | ? | |
| Code coverage | ✅ | ✅ | ✅ | ? | |
| Cross-compilation | ✅ | ✅ | partial | ? | |
| stardoc API docs | ✅ | ✅ | ✅ | ? | |
| examples/ directory | ✅ | ✅ | ✅ | ? | |
| Multi-platform CI | ✅ | ✅ | ✅ | ? | |

**Owner review gate:** Completed matrix with honest assessments. "Missing" and "partial" are fine — the community respects honesty about known gaps far more than they respect false claims of completeness.

### Phase 5: Documentation dry-run

Before any external eyes see this:

1. Can someone write a `MODULE.bazel` that pulls in the rules and builds a hello-world .NET app using only the documentation?
2. Can they add a NuGet dependency using only the documentation?
3. Can they run a test using only the documentation?

Time each of these. Compare against the `rules_go` quickstart experience. Document gaps.

**Owner review gate:** Onboarding friction report.

### Phase 6: Staged visibility

Only after the owner has reviewed and approved all prior phases:

1. **Private BuildBuddy org** — upload invocation data to a BuildBuddy instance only the owner can see
2. **Trusted reviewers** — share invocation links with 2-3 experienced Bazel community members for feedback
3. **Public announcement** — publish the gap matrix, the proof invocations, and the friction logs alongside the code

---

## BEP analysis tooling

Write a script (Python or Bash) that ingests a `.bep.json` file and produces a structured summary. The BEP JSON is a newline-delimited stream of `BuildEvent` protobuf messages serialized as JSON. Key events to extract:

- `started` — invocation ID, command
- `buildMetrics` — action count, action cache statistics
- `testResult` — per-test pass/fail/status
- `targetComplete` — per-target success/failure
- `buildFinished` — overall exit code

The script should output a summary that answers:
- How many actions ran? How many were cache hits?
- How many tests passed/failed/skipped/timed out?
- What was the critical path duration?
- Were there any action failures? Which ones?
- What was the overall build result?

This script is itself a deliverable — it can be included in the rules_dotnet repository as a developer tool.

---

## What success looks like

At the end of this phase, the owner should have:

1. **Confidence based on data, not hope.** Every claim about the rules ("they're hermetic", "they support NuGet", "they work on macOS") is backed by a BEP file that proves it.

2. **A clear gap list.** Not "it works" or "it doesn't work" but a precise enumeration of what works, what's partial, and what's missing — with the friction logs to prove it.

3. **Proof artifacts the community recognizes.** BuildBuddy invocation links, BEP summaries, feature comparison matrices. These are the language the Bazel community speaks.

4. **A staged publication plan.** Private review first, trusted reviewers second, public third. No surprises.

---

## Important constraints

- **Do not optimize for demo-ability.** Do not cherry-pick projects that happen to work. The whole point is to find what breaks.
- **Do not fix issues silently.** Every bug found during validation gets documented in the friction log before it gets fixed. The friction log is as valuable as the fixes.
- **Do not skip the warm-rebuild cache test.** A cache hit rate below 100% on a zero-change rebuild means hermeticity is broken. This is the single most important number.
- **Do not conflate "builds" with "works correctly."** A build that succeeds but produces wrong output is worse than a build that fails. Test coverage matters.
- **Preserve all BEP files.** They are the empirical record. Even if a build fails, the BEP file from that failure is evidence.

# Phase 2: BEP Summary Table

**Date:** 2026-03-12

| Project | Cold Build | Warm Rebuild | Incremental | Status |
|---------|-----------|-------------|-------------|--------|
| Spectre.Console | N/A | N/A | N/A | Blocked (source-only NuGet) |
| Wolverine | Not attempted | — | — | — |
| Verify | Not attempted | — | — | — |
| SixLabors.ImageSharp | Not attempted | — | — | — |
| Riok.Mapperly | Not attempted | — | — | — |

Only 1/5 projects was attempted. All 5 projects would hit the same two
blocking NuGet gaps (source-only packages, transitive dependency resolution).
See `friction_summary.md` for details.

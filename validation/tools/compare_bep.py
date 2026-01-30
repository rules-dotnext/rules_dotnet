#!/usr/bin/env python3
"""Compare two BEP summary JSONs and output a delta table.

Usage:
    python3 compare_bep.py <baseline.json> <comparison.json> [--json]

Inputs are JSON files produced by `analyze_bep.py --json`.
"""

import argparse
import json
import sys
from pathlib import Path


def load_summary(path: str) -> dict:
    """Load a BEP summary JSON file."""
    with open(path) as f:
        return json.load(f)


def compute_delta(baseline: dict, comparison: dict) -> list[dict]:
    """Compute deltas for key metrics."""
    metrics = [
        ("Overall result", "overall_result", "str"),
        ("Actions executed", "actions_executed", "int"),
        ("Actions created", "actions_created", "int"),
        ("Cache hits", "cache_hits", "int"),
        ("Cache misses", "cache_misses", "int"),
        ("Cache rate (%)", "cache_rate_pct", "float"),
        ("Tests passed", "tests_passed", "int"),
        ("Tests failed", "tests_failed", "int"),
        ("Tests skipped", "tests_skipped", "int"),
        ("Tests timed out", "tests_timed_out", "int"),
        ("Critical path (ms)", "critical_path_ms", "int"),
    ]

    deltas = []
    for label, key, typ in metrics:
        b = baseline.get(key, 0)
        c = comparison.get(key, 0)

        if typ == "str":
            delta = {
                "metric": label,
                "baseline": b,
                "comparison": c,
                "delta": "—" if b == c else f"{b} → {c}",
                "changed": b != c,
            }
        elif typ == "float":
            diff = round(c - b, 1)
            delta = {
                "metric": label,
                "baseline": b,
                "comparison": c,
                "delta": f"{'+' if diff >= 0 else ''}{diff}",
                "changed": diff != 0,
            }
        else:
            diff = c - b
            delta = {
                "metric": label,
                "baseline": b,
                "comparison": c,
                "delta": f"{'+' if diff >= 0 else ''}{diff}",
                "changed": diff != 0,
            }

        deltas.append(delta)

    return deltas


def format_table(deltas: list[dict], baseline_name: str, comparison_name: str) -> str:
    """Format deltas as a markdown-style table."""
    lines = [
        f"| Metric | {baseline_name} | {comparison_name} | Delta |",
        "|--------|" + "-" * (len(baseline_name) + 2) + "|" + "-" * (len(comparison_name) + 2) + "|-------|",
    ]

    for d in deltas:
        marker = " ⚠" if d["changed"] else ""
        lines.append(
            f"| {d['metric']} | {d['baseline']} | {d['comparison']} | {d['delta']}{marker} |"
        )

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Compare two BEP summaries")
    parser.add_argument("baseline", help="Baseline BEP summary JSON")
    parser.add_argument("comparison", help="Comparison BEP summary JSON")
    parser.add_argument(
        "--json", action="store_true", dest="json_output",
        help="Output machine-readable JSON"
    )
    parser.add_argument(
        "--output", "-o", help="Write output to file instead of stdout"
    )
    args = parser.parse_args()

    for p in [args.baseline, args.comparison]:
        if not Path(p).exists():
            print(f"Error: {p} does not exist", file=sys.stderr)
            sys.exit(1)

    baseline = load_summary(args.baseline)
    comparison = load_summary(args.comparison)
    deltas = compute_delta(baseline, comparison)

    if args.json_output:
        output = json.dumps(deltas, indent=2)
    else:
        baseline_name = Path(args.baseline).stem
        comparison_name = Path(args.comparison).stem
        output = format_table(deltas, baseline_name, comparison_name)

    if args.output:
        Path(args.output).write_text(output + "\n")
        print(f"Written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()

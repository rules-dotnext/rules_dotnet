#!/usr/bin/env python3
"""Analyze a Bazel Build Event Protocol (BEP) JSON file.

Parses newline-delimited BEP JSON and outputs a human-readable summary.
Supports --json flag for machine-readable output.

Usage:
    python3 analyze_bep.py <bep_file> [--json] [--output <file>]
"""

import argparse
import json
import sys
from pathlib import Path


def parse_bep(path: str) -> list[dict]:
    """Parse newline-delimited BEP JSON file into a list of events."""
    events = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                events.append(json.loads(line))
    return events


def analyze(events: list[dict]) -> dict:
    """Extract summary metrics from BEP events."""
    summary = {
        "invocation_id": "",
        "command": "",
        "buildbuddy_url": "",
        "overall_result": "UNKNOWN",
        "actions_executed": 0,
        "actions_created": 0,
        "cache_hits": 0,
        "cache_misses": 0,
        "cache_rate_pct": 0.0,
        "tests_passed": 0,
        "tests_failed": 0,
        "tests_skipped": 0,
        "tests_timed_out": 0,
        "critical_path_ms": 0,
        "failures": [],
        "total_targets": 0,
        "targets_passed": 0,
        "targets_failed": 0,
    }

    test_summaries = {}  # label -> overall status

    for event in events:
        eid = event.get("id", {})

        # started event
        if "started" in eid:
            started = event.get("started", {})
            summary["invocation_id"] = started.get("uuid", "")
            summary["command"] = started.get("command", "")

        # buildToolLogs — contains BES URLs
        if "buildToolLogs" in eid:
            tool_logs = event.get("buildToolLogs", {})
            for log in tool_logs.get("log", []):
                uri = log.get("uri", "")
                if "buildbuddy.io" in uri:
                    summary["buildbuddy_url"] = uri

        # buildFinished
        if "buildFinished" in eid:
            finished = event.get("finished", {})
            if finished.get("overallSuccess", False):
                summary["overall_result"] = "SUCCESS"
            else:
                exit_code = finished.get("exitCode", {})
                name = exit_code.get("name", "")
                if name == "SUCCESS":
                    summary["overall_result"] = "SUCCESS"
                else:
                    summary["overall_result"] = "FAILURE"

        # buildMetrics
        if "buildMetrics" in eid:
            metrics = event.get("buildMetrics", {})
            action_summary = metrics.get("actionSummary", {})
            summary["actions_executed"] = int(
                action_summary.get("actionsExecuted", 0)
            )

            # actionsCreated: sum from actionData entries (not top-level)
            action_data = action_summary.get("actionData", [])
            total_created = sum(
                int(d.get("actionsCreated", 0)) for d in action_data
            )
            summary["actions_created"] = total_created

            # Action cache statistics
            # Note: actionsExecuted counts only non-cached actions.
            # actionCacheStatistics.hits counts actions served from cache.
            # Cache rate = hits / (hits + misses) where misses ≈ actionsExecuted.
            action_cache = action_summary.get("actionCacheStatistics", {})
            hits = int(action_cache.get("hits", 0))
            misses = int(action_cache.get("misses", 0))
            summary["cache_hits"] = hits
            summary["cache_misses"] = misses

            total_actions = hits + misses
            if total_actions > 0:
                summary["cache_rate_pct"] = round(
                    (hits / total_actions) * 100, 1
                )

            # Timing metrics
            timing = metrics.get("timingMetrics", {})
            cp = timing.get("criticalPath", {})
            if isinstance(cp, dict):
                summary["critical_path_ms"] = int(
                    cp.get("durationMillis", 0)
                )
            elif isinstance(cp, (int, float)):
                summary["critical_path_ms"] = int(cp)

        # testSummary — one per test target
        if "testSummary" in eid:
            test_summary = event.get("testSummary", {})
            label = eid.get("testSummary", {}).get("label", "unknown")
            status = test_summary.get("overallStatus", "UNKNOWN")
            test_summaries[label] = status

        # targetComplete — track failures
        if "targetCompleted" in eid:
            summary["total_targets"] += 1
            target_completed = event.get("completed", event.get("targetCompleted", {}))
            label = eid.get("targetCompleted", {}).get("label", "unknown")
            success = target_completed.get("success", True)
            if success:
                summary["targets_passed"] += 1
            else:
                summary["targets_failed"] += 1
                # Collect failure reason
                failure_detail = target_completed.get("failureDetail", {})
                message = failure_detail.get("message", "build failed")
                summary["failures"].append(
                    {"target": label, "reason": message}
                )

    # Tally test results from testSummary events
    for label, status in test_summaries.items():
        if status == "PASSED":
            summary["tests_passed"] += 1
        elif status in ("FAILED", "INCOMPLETE"):
            summary["tests_failed"] += 1
            if not any(f["target"] == label for f in summary["failures"]):
                summary["failures"].append(
                    {"target": label, "reason": f"test {status.lower()}"}
                )
        elif status == "SKIPPED":
            summary["tests_skipped"] += 1
        elif status in ("TIMEOUT", "TIMED_OUT"):
            summary["tests_timed_out"] += 1
            if not any(f["target"] == label for f in summary["failures"]):
                summary["failures"].append(
                    {"target": label, "reason": "test timed out"}
                )

    return summary


def format_summary(summary: dict, filename: str) -> str:
    """Format summary as human-readable text."""
    lines = [
        f"=== BEP Summary: {filename} ===",
        f"Invocation ID: {summary['invocation_id']}",
        f"Command: {summary['command']}",
    ]
    if summary.get("buildbuddy_url"):
        lines.append(f"BuildBuddy: {summary['buildbuddy_url']}")
    lines += [
        f"Overall result: {summary['overall_result']}",
        f"Actions: {summary['actions_executed']} executed, {summary['actions_created']} total",
        f"Cache hits: {summary['cache_hits']} / {summary['cache_hits'] + summary['cache_misses']} ({summary['cache_rate_pct']}%)",
    ]

    total_tests = (
        summary["tests_passed"]
        + summary["tests_failed"]
        + summary["tests_skipped"]
        + summary["tests_timed_out"]
    )
    if total_tests > 0:
        lines.append(
            f"Tests: {summary['tests_passed']} passed, "
            f"{summary['tests_failed']} failed, "
            f"{summary['tests_skipped']} skipped, "
            f"{summary['tests_timed_out']} timed out"
        )

    if summary["critical_path_ms"] > 0:
        lines.append(f"Critical path: {summary['critical_path_ms']}ms")

    if summary["failures"]:
        lines.append("Failures:")
        for f in summary["failures"]:
            lines.append(f"  - {f['target']}: {f['reason']}")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Analyze Bazel BEP JSON file")
    parser.add_argument("bep_file", help="Path to BEP JSON file")
    parser.add_argument(
        "--json", action="store_true", dest="json_output",
        help="Output machine-readable JSON"
    )
    parser.add_argument(
        "--output", "-o", help="Write output to file instead of stdout"
    )
    args = parser.parse_args()

    bep_path = Path(args.bep_file)
    if not bep_path.exists():
        print(f"Error: {bep_path} does not exist", file=sys.stderr)
        sys.exit(1)

    events = parse_bep(str(bep_path))
    summary = analyze(events)

    if args.json_output:
        output = json.dumps(summary, indent=2)
    else:
        output = format_summary(summary, bep_path.name)

    if args.output:
        Path(args.output).write_text(output + "\n")
        print(f"Written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()

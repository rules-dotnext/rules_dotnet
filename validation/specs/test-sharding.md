---
priority: P1
category: testing
discovered_in: Parity audit (Phase 4)
---

# Test Sharding Support

## Description

Bazel supports test sharding via `shard_count` attribute and `TEST_SHARD_INDEX`
/ `TEST_TOTAL_SHARDS` environment variables. The test launcher should split
test execution across shards when these variables are set.

For .NET/NUnit, this means filtering test cases based on shard index (e.g.,
using `--where "id % $TEST_TOTAL_SHARDS == $TEST_SHARD_INDEX"` or similar).

## Impact

Large test suites cannot be parallelized across shards, leading to longer CI
times. rules_go, rules_cc, and rules_py all support test sharding.

## Proposed Fix

In `dotnet/private/launcher.sh.tpl`:
1. Check for `TEST_SHARD_INDEX` and `TEST_TOTAL_SHARDS`
2. Write `TEST_SHARD_STATUS_FILE` to signal shard support
3. For NUnit: use `--where` filter based on test ID modulo
4. For xUnit: use `--filter` with similar approach

## Estimated Effort

Easy — launcher template change + test runner filter logic.

#!/usr/bin/env bash
# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---
runfiles_export_envvars

set -o pipefail -o errexit -o nounset

export DOTNET_MULTILEVEL_LOOKUP="false"
export DOTNET_NOLOGO="1"
export DOTNET_CLI_TELEMETRY_OPTOUT="1"
export DOTNET_ROOT="$(dirname $(rlocation TEMPLATED_dotnet))"

# #349 — P/Invoke native library search path
NATIVE_LIB_DIR="$(dirname $(rlocation TEMPLATED_executable))"
if [ -n "${LD_LIBRARY_PATH:-}" ]; then
  export LD_LIBRARY_PATH="${NATIVE_LIB_DIR}:${LD_LIBRARY_PATH}"
else
  export LD_LIBRARY_PATH="${NATIVE_LIB_DIR}"
fi
if [ "$(uname)" = "Darwin" ]; then
  if [ -n "${DYLD_LIBRARY_PATH:-}" ]; then
    export DYLD_LIBRARY_PATH="${NATIVE_LIB_DIR}:${DYLD_LIBRARY_PATH}"
  else
    export DYLD_LIBRARY_PATH="${NATIVE_LIB_DIR}"
  fi
fi

DOTNET_EXEC="$(rlocation TEMPLATED_dotnet)"
ASSEMBLY="$(rlocation TEMPLATED_executable)"

# Coverage support: when Bazel sets COVERAGE_DIR (via `bazel coverage`),
# invoke coverlet.console to instrument and collect LCOV data.
# TEMPLATED_coverlet_console is substituted by expand_template in _create_launcher():
#   - For test rules: the rlocation path of the coverlet dotnet_tool launcher
#   - For binary rules: "NONE"
if [ -n "${COVERAGE_DIR:-}" ] && [ "TEMPLATED_coverlet_console" != "NONE" ]; then
  COVERLET="$(rlocation TEMPLATED_coverlet_console)"
  if [ -x "$COVERLET" ] || [ -f "$COVERLET" ]; then
    "$COVERLET" "$(dirname "$ASSEMBLY")" \
      --target "$DOTNET_EXEC" \
      --targetargs "exec $ASSEMBLY $*" \
      --output "${COVERAGE_OUTPUT_FILE}" \
      --format lcov
    exit $?
  fi
fi

# Test sharding: signal shard awareness to Bazel
if [ -n "${TEST_SHARD_STATUS_FILE:-}" ]; then
  touch "${TEST_SHARD_STATUS_FILE}"
fi

exec "$DOTNET_EXEC" exec "$ASSEMBLY" "$@"

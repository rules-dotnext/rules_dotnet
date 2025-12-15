#! /usr/bin/env bash
set -eou pipefail

# This wrapper script is used because the C#/F# compilers both embed absolute paths
# into their outputs and those paths are not deterministic. The compilers also
# allow overriding these paths using pathmaps. Since the paths can not be known
# at analysis time we need to override them at execution time.

COMPILER="$2"
PATHMAP_FLAG="-pathmap"

# Needed because unfortunately the F# compiler uses a different flag name
if [[ $(basename "$COMPILER") == "fsc.dll" ]]; then
  PATHMAP_FLAG="--pathmap"
fi
PATHMAP="$PATHMAP_FLAG:$PWD=."

# --- spec-razor-blazor: editorconfig rewriting (#249) ---
# Razor source generator requires absolute paths in analyzerconfig section headers.
# At analysis time we don't know the sandbox path, so razor_preprocess writes
# sentinel values that we rewrite here at execution time.
# Arguments are in a response file (@path); find it and scan for /analyzerconfig:.
for arg in "$@"; do
  if [[ "$arg" == @* ]]; then
    RESP_FILE="${arg#@}"
    if [[ -f "$RESP_FILE" ]]; then
      while IFS= read -r resp_line; do
        if [[ "$resp_line" == /analyzerconfig:* ]]; then
          CONFIG_FILE="${resp_line#/analyzerconfig:}"
          if [[ -f "$CONFIG_FILE" ]] && grep -q '__RAZOR_FILE__:' "$CONFIG_FILE" 2>/dev/null; then
            TEMP_CONFIG="${CONFIG_FILE}.resolved"
            while IFS= read -r line; do
              if [[ "$line" == "[__RAZOR_FILE__:"*"]" ]]; then
                # Extract relative path and prepend $PWD for absolute sandbox path
                REL_PATH="${line#\[__RAZOR_FILE__:}"
                REL_PATH="${REL_PATH%\]}"
                echo "[$PWD/$REL_PATH]"
              elif [[ "$line" == *"__RAZOR_B64__:"* ]]; then
                # Extract relative path and base64-encode it for TargetPath metadata
                PREFIX="${line%%__RAZOR_B64__:*}"
                REL_PATH="${line#*__RAZOR_B64__:}"
                B64_PATH=$(echo -n "$REL_PATH" | base64 -w 0)
                echo "${PREFIX}${B64_PATH}"
              else
                echo "$line"
              fi
            done < "$CONFIG_FILE" > "$TEMP_CONFIG"
            mv "$TEMP_CONFIG" "$CONFIG_FILE"
          fi
        fi
      done < "$RESP_FILE"
    fi
  fi
done
# --- end spec-razor-blazor: #249 ---

# shellcheck disable=SC2145
./"$@" "$PATHMAP"

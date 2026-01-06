#!/usr/bin/env bash
# Runtime validation: run the app binary and verify it exits 0.
# This proves appsettings are in the right runfiles paths (#490, #526),
# native interop works (#349), F# interop works (#315, #500),
# and resx resources load (#466).
set -euo pipefail

# Locate the app binary in runfiles
APP="$(dirname "$0")/app"
if [ ! -x "$APP" ]; then
    # Try platform-specific path
    APP="$(dirname "$0")/app.exe"
fi
if [ ! -x "$APP" ]; then
    echo "FAIL: Cannot find app binary"
    exit 1
fi

exec "$APP"

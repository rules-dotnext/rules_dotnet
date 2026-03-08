#! /usr/bin/env bash

set -eou pipefail

# Unset the runfiles related envs to make sure that runfiles work outside of Bazel
export RUNFILES_DIR=""
export JAVA_RUNFILES=""
export RUNFILES_MANIFEST_FILE=""
export RUNFILES_MANIFEST_ONLY=""

# Set DOTNET_ROOT to the location of the dotnet runtime
# this way the framework dependent publish will use the
# dotnet installation that is located there to run the
# binary.
TOOLCHAIN_LOCATION=$(dirname "$1")
# Framework-dependent apps need DOTNET_ROOT to locate the .NET runtime.
# $(DOTNET_BIN) gives us the path to the dotnet binary inside the external
# toolchain repo; we derive DOTNET_ROOT by stripping the "external/" prefix
# and prepending "../" to navigate from the runfiles root to the SDK.
DOTNET_ROOT="../${TOOLCHAIN_LOCATION#'external/'}/"
export DOTNET_ROOT
ls -la ./../_main/dotnet/private/tests/publish

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    tar -xvf ./dotnet/private/tests/publish/framework_dependent/tar.tar
    ./app_to_publish
elif [[ "$OSTYPE" == "darwin"* ]]; then
    tar -xvf ./dotnet/private/tests/publish/framework_dependent/tar.tar
    ./app_to_publish
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    tar -xvf ./dotnet/private/tests/publish/framework_dependent/tar.tar
    ./app_to_publish.exe
else
    echo "Could not figure out which OS is running the test"
    exit 1
fi


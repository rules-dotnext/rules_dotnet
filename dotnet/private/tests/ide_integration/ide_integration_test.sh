#!/usr/bin/env bash
set -euo pipefail

# --- Test: dotnet_project produces .csproj files ---

# Find the .csproj output from the project targets
found_lib_csproj=false
found_app_csproj=false
found_sln=false
found_props=false
found_nuget_config=false

for f in $(find . -name "*.csproj" 2>/dev/null); do
    case "$(basename "$f")" in
        *integration_lib*) found_lib_csproj=true ;;
        *integration_app*) found_app_csproj=true ;;
    esac
done

for f in $(find . -name "*.sln" 2>/dev/null); do
    found_sln=true
done

for f in $(find . -name "Directory.Build.props" 2>/dev/null); do
    found_props=true
done

for f in $(find . -name "NuGet.config" 2>/dev/null); do
    found_nuget_config=true
done

# Report results
errors=0

if [ "$found_lib_csproj" != "true" ]; then
    echo "FAIL: integration_lib .csproj not found"
    errors=$((errors + 1))
else
    echo "PASS: integration_lib .csproj found"
fi

if [ "$found_app_csproj" != "true" ]; then
    echo "FAIL: integration_app .csproj not found"
    errors=$((errors + 1))
else
    echo "PASS: integration_app .csproj found"
fi

if [ "$found_sln" != "true" ]; then
    echo "FAIL: .sln file not found"
    errors=$((errors + 1))
else
    echo "PASS: .sln file found"
fi

if [ "$found_props" != "true" ]; then
    echo "FAIL: Directory.Build.props not found"
    errors=$((errors + 1))
else
    echo "PASS: Directory.Build.props found"
fi

if [ "$found_nuget_config" != "true" ]; then
    echo "FAIL: NuGet.config not found"
    errors=$((errors + 1))
else
    echo "PASS: NuGet.config found"
fi

# Check .sln content if found
if [ "$found_sln" = "true" ]; then
    sln_file=$(find . -name "*.sln" | head -1)
    if grep -q "Microsoft Visual Studio Solution" "$sln_file"; then
        echo "PASS: .sln has correct header"
    else
        echo "FAIL: .sln missing VS solution header"
        errors=$((errors + 1))
    fi

    if grep -q "EndProject" "$sln_file"; then
        echo "PASS: .sln has project entries"
    else
        echo "FAIL: .sln missing project entries"
        errors=$((errors + 1))
    fi
fi

# Check Directory.Build.props content
if [ "$found_props" = "true" ]; then
    props_file=$(find . -name "Directory.Build.props" | head -1)
    if grep -q "GenerateAssemblyInfo" "$props_file"; then
        echo "PASS: Directory.Build.props has GenerateAssemblyInfo"
    else
        echo "FAIL: Directory.Build.props missing GenerateAssemblyInfo"
        errors=$((errors + 1))
    fi
fi

if [ $errors -gt 0 ]; then
    echo ""
    echo "FAILED: $errors error(s)"
    exit 1
fi

echo ""
echo "All IDE integration checks passed."

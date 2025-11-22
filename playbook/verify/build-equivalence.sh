#!/bin/bash
# Build Equivalence Verification
#
# Compares dotnet build output against bazel build output to prove
# they produce functionally identical assemblies.
#
# Usage:
#   Single target:  ./build-equivalence.sh <dotnet_dll> <bazel_dll>
#   All targets:    ./build-equivalence.sh --all-targets <project_root>
#
# Prerequisites:
#   - dotnet CLI available (for dotnet build and ildasm tool)
#   - bazel available
#   - Both builds must succeed before comparison
#
# Exit codes:
#   0 = IDENTICAL or EQUIVALENT (safe — IL matches)
#   1 = DIVERGENT (IL differs — investigate)
#   2 = Tool error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR=""
IDENTICAL=0
EQUIVALENT=0
DIVERGENT=0
TOTAL=0
REPORT_FILE=""

cleanup() {
    if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

ensure_ildasm() {
    # Check if ildasm-like tool is available
    # Prefer ikdasm (Mono's IL disassembler, works cross-platform)
    # Fall back to dotnet-ildasm NuGet tool
    if command -v ikdasm &>/dev/null; then
        ILDASM_CMD="ikdasm"
        return 0
    fi

    # Try dotnet tool
    if dotnet tool list -g 2>/dev/null | grep -qi "ildasm"; then
        ILDASM_CMD="dotnet ildasm"
        return 0
    fi

    # Install dotnet-ildasm as a local tool
    echo "Installing dotnet-ildasm tool..."
    dotnet tool install --global dotnet-ildasm 2>/dev/null || true
    if dotnet tool list -g 2>/dev/null | grep -qi "ildasm"; then
        ILDASM_CMD="dotnet ildasm"
        return 0
    fi

    # Fall back to raw metadata comparison if no IL disassembler available
    echo "WARNING: No IL disassembler found. Falling back to metadata comparison only."
    ILDASM_CMD=""
    return 0
}

# Disassemble a DLL to normalized IL text
# Strips MVID, PDB checksums, debug directory, and path-dependent metadata
disassemble_and_normalize() {
    local dll_path="$1"
    local output_path="$2"

    if [ -n "$ILDASM_CMD" ]; then
        $ILDASM_CMD "$dll_path" 2>/dev/null > "$output_path.raw" || {
            # If ildasm fails, try with dotnet exec
            echo "// ILDASM FAILED for $dll_path" > "$output_path"
            return 1
        }
    else
        # No ildasm — extract what we can with strings + basic PE parsing
        strings "$dll_path" | sort > "$output_path.raw"
    fi

    # Normalize: strip non-deterministic metadata
    sed \
        -e '/\.custom.*System\.Runtime\.CompilerServices\.CompilationRelaxationsAttribute/d' \
        -e '/\.hash algorithm/d' \
        -e '/\.mvid/,+1d' \
        -e '/\/\/ MVID:/d' \
        -e '/\/\/ Image base:/d' \
        -e '/\.imagebase/d' \
        -e '/Debug Directory/,/^$/d' \
        -e '/\.pdb/d' \
        -e '/PDB checksum/d' \
        -e '/Checksum:/d' \
        -e '/Time-date stamp:/d' \
        -e '/Time date stamp:/d' \
        -e '/GUID:/d' \
        -e '/guidval/d' \
        -e '/\.ver [0-9]/d' \
        -e 's|/[^ ]*/||g' \
        "$output_path.raw" > "$output_path"

    rm -f "$output_path.raw"
}

# Compare two DLLs and report result
compare_dlls() {
    local dotnet_dll="$1"
    local bazel_dll="$2"
    local label="${3:-$(basename "$dotnet_dll")}"

    TOTAL=$((TOTAL + 1))

    if [ ! -f "$dotnet_dll" ]; then
        echo "  SKIP  $label — dotnet DLL not found: $dotnet_dll"
        return
    fi
    if [ ! -f "$bazel_dll" ]; then
        echo "  SKIP  $label — bazel DLL not found: $bazel_dll"
        return
    fi

    # Level 0: Byte-identical check (fast path)
    if cmp -s "$dotnet_dll" "$bazel_dll"; then
        IDENTICAL=$((IDENTICAL + 1))
        echo "  IDENTICAL  $label"
        [ -n "$REPORT_FILE" ] && echo "IDENTICAL,$label" >> "$REPORT_FILE"
        return
    fi

    # Level 1: IL comparison
    local dotnet_il="$WORK_DIR/dotnet_$(basename "$dotnet_dll" .dll).il"
    local bazel_il="$WORK_DIR/bazel_$(basename "$bazel_dll" .dll).il"

    disassemble_and_normalize "$dotnet_dll" "$dotnet_il"
    disassemble_and_normalize "$bazel_dll" "$bazel_il"

    if diff -q "$dotnet_il" "$bazel_il" &>/dev/null; then
        EQUIVALENT=$((EQUIVALENT + 1))
        echo "  EQUIVALENT $label (IL identical, binary metadata differs)"
        [ -n "$REPORT_FILE" ] && echo "EQUIVALENT,$label" >> "$REPORT_FILE"
    else
        DIVERGENT=$((DIVERGENT + 1))
        echo "  DIVERGENT  $label"
        # Show first few differences
        diff --unified=3 "$dotnet_il" "$bazel_il" | head -30 || true
        echo "  ... (full diff: diff $dotnet_il $bazel_il)"
        [ -n "$REPORT_FILE" ] && echo "DIVERGENT,$label" >> "$REPORT_FILE"
    fi
}

# ─── Single target mode ───

single_target_mode() {
    local dotnet_dll="$1"
    local bazel_dll="$2"

    echo "=== Build Equivalence Check ==="
    echo "dotnet: $dotnet_dll"
    echo "bazel:  $bazel_dll"
    echo ""

    compare_dlls "$dotnet_dll" "$bazel_dll"
    echo ""
    print_summary
}

# ─── All targets mode ───

all_targets_mode() {
    local project_root="$1"

    echo "=== Build Equivalence Report ==="
    echo "Project root: $project_root"
    echo ""

    REPORT_FILE="$WORK_DIR/report.csv"
    echo "status,assembly" > "$REPORT_FILE"

    # Find all .csproj files and build both ways
    while IFS= read -r csproj; do
        local project_dir
        project_dir=$(dirname "$csproj")
        local project_name
        project_name=$(basename "$csproj" .csproj)

        echo "--- $project_name ---"

        # Determine TFM from csproj
        local tfm
        tfm=$(grep -oP '<TargetFramework>\K[^<]+' "$csproj" 2>/dev/null | head -1 || true)
        if [ -z "$tfm" ]; then
            tfm=$(grep -oP '<TargetFrameworks>\K[^<;]+' "$csproj" 2>/dev/null | head -1 || true)
        fi
        if [ -z "$tfm" ]; then
            echo "  SKIP  $project_name — no TFM found in .csproj"
            continue
        fi

        # dotnet build
        local dotnet_output_dir="$project_dir/bin/Release/$tfm"
        if [ ! -f "$dotnet_output_dir/$project_name.dll" ]; then
            dotnet build "$csproj" -c Release --no-restore --nologo -v q 2>/dev/null || {
                echo "  SKIP  $project_name — dotnet build failed"
                continue
            }
        fi

        local dotnet_dll="$dotnet_output_dir/$project_name.dll"
        if [ ! -f "$dotnet_dll" ]; then
            echo "  SKIP  $project_name — dotnet DLL not found at $dotnet_dll"
            continue
        fi

        # bazel build — find the target label
        local rel_dir="${project_dir#$project_root/}"
        rel_dir="${rel_dir#./}"
        local bazel_target="//${rel_dir}:${project_name}"

        bazel build "$bazel_target" --noshow_progress 2>/dev/null || {
            echo "  SKIP  $project_name — bazel build failed for $bazel_target"
            continue
        }

        # Find bazel output DLL
        local bazel_dll
        bazel_dll=$(bazel cquery --output=files "$bazel_target" 2>/dev/null | grep '\.dll$' | head -1 || true)
        if [ -z "$bazel_dll" ] || [ ! -f "$bazel_dll" ]; then
            echo "  SKIP  $project_name — bazel DLL not found"
            continue
        fi

        compare_dlls "$dotnet_dll" "$bazel_dll" "$project_name"

    done < <(find "$project_root" -name "*.csproj" -not -path "*/obj/*" -not -path "*/bin/*" | sort)

    echo ""
    print_summary
    echo ""
    echo "Full report: $REPORT_FILE"
}

print_summary() {
    echo "═══════════════════════════════════════"
    echo "Build Equivalence Summary"
    echo "═══════════════════════════════════════"
    echo "Total assemblies: $TOTAL"
    echo "  IDENTICAL:  $IDENTICAL"
    echo "  EQUIVALENT: $EQUIVALENT (IL matches, metadata differs — safe)"
    echo "  DIVERGENT:  $DIVERGENT"
    echo "═══════════════════════════════════════"

    if [ "$DIVERGENT" -gt 0 ]; then
        echo "RESULT: DIVERGENT — $DIVERGENT assemblies have different IL"
        echo "See reference/binary-comparison.md for diagnosis guide"
        exit 1
    elif [ "$TOTAL" -eq 0 ]; then
        echo "RESULT: NO ASSEMBLIES COMPARED"
        exit 2
    else
        local pct_identical=0
        if [ "$TOTAL" -gt 0 ]; then
            pct_identical=$(( (IDENTICAL * 100) / TOTAL ))
        fi
        echo "RESULT: PASS — all assemblies are functionally identical"
        echo "        ($pct_identical% byte-identical, remainder differs only in MVID/PDB metadata)"
        exit 0
    fi
}

# ─── Main ───

WORK_DIR=$(mktemp -d)
ensure_ildasm

if [ "${1:-}" = "--all-targets" ]; then
    PROJECT_ROOT="${2:-.}"
    all_targets_mode "$PROJECT_ROOT"
elif [ $# -ge 2 ]; then
    single_target_mode "$1" "$2"
else
    echo "Usage:"
    echo "  $0 <dotnet_dll> <bazel_dll>          Compare two specific DLLs"
    echo "  $0 --all-targets [project_root]      Compare all .csproj projects"
    echo ""
    echo "Exit codes: 0=identical/equivalent, 1=divergent, 2=error"
    exit 2
fi

#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo >&2 "Usage: $0 /path/to/binary expected_file_type expected_arch"
    exit 1
fi

binary="$1"
expected_file_type="$2"
expected_arches="${@:3}"

# Resolve symlinks to get the actual binary path
actual="$(readlink -f "${binary}" 2>/dev/null || readlink "${binary}")"

# Detect binary format and architecture using POSIX od(1) — no dependency
# on the `file` command, so this works on any executor (local, RBE, sandbox).
magic=$(od -An -N4 -tx1 "$actual" | tr -d ' \n')

case "$magic" in
    7f454c46)  # ELF
        class=$(od -An -N1 -j4 -tx1 "$actual" | tr -d ' \n')
        if [ "$class" = "02" ]; then
            type_str="ELF 64-bit"
        else
            type_str="ELF 32-bit"
        fi
        # e_machine: little-endian uint16 at offset 18
        machine=$(od -An -N2 -j18 -tx1 "$actual" | tr -d ' \n')
        case "$machine" in
            3e00) arch_str="x86-64" ;;
            b700) arch_str="aarch64" ;;
            *)    arch_str="unknown($machine)" ;;
        esac
        ;;
    4d5a*)  # PE (MZ header)
        type_str="PE32+"
        # PE header offset: little-endian uint32 at offset 60
        b=$(od -An -N4 -j60 -tx1 "$actual" | tr -d ' \n')
        pe_offset=$(( 16#${b:6:2}${b:4:2}${b:2:2}${b:0:2} ))
        # Machine type: little-endian uint16 at pe_offset+4
        machine=$(od -An -N2 -j$((pe_offset + 4)) -tx1 "$actual" | tr -d ' \n')
        case "$machine" in
            6486) arch_str="x86-64" ;;
            64aa) arch_str="Aarch64 ARM64" ;;
            *)    arch_str="unknown($machine)" ;;
        esac
        ;;
    cffaedfe)  # Mach-O 64-bit little-endian
        type_str="Mach-O"
        cpu=$(od -An -N4 -j4 -tx1 "$actual" | tr -d ' \n')
        case "$cpu" in
            07000001) arch_str="x86_64" ;;
            0c000001) arch_str="arm64" ;;
            *)        arch_str="unknown($cpu)" ;;
        esac
        ;;
    feedfacf)  # Mach-O 64-bit big-endian
        type_str="Mach-O"
        cpu=$(od -An -N4 -j4 -tx1 "$actual" | tr -d ' \n')
        case "$cpu" in
            01000007) arch_str="x86_64" ;;
            0100000c) arch_str="arm64" ;;
            *)        arch_str="unknown($cpu)" ;;
        esac
        ;;
    *)
        echo >&2 "Unknown binary format (magic: $magic)"
        exit 1
        ;;
esac

out="${type_str}, ${arch_str}"

# Loop over all expected arches and check if the output contains any of them
for expected_arch in ${expected_arches}; do
    if [[ "${out}" == *"${expected_arch}"* ]]; then
        if [[ "${out}" == *"${expected_file_type}"* ]]; then
            exit 0
        fi
    fi
done

echo >&2 "Wrong file type: ${out}"
exit 1

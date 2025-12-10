"""Utilities for copying DLLs into a flat output layout.

Extracted from publish_binary.bzl to be shared by binary/test rules
when flatten_deps is enabled (spec-testing-infra: #450).
"""

load("@bazel_skylib//lib:shell.bzl", "shell")

def copy_file(script_body, src, dst, is_windows):
    """Append a copy command to script_body.

    Args:
        script_body: List of script lines to append to.
        src: Source File object.
        dst: Destination File object.
        is_windows: Whether target platform is Windows.
    """
    if is_windows:
        script_body.append("if not exist \"{dir}\" @mkdir \"{dir}\" >NUL".format(
            dir = dst.dirname.replace("/", "\\"),
        ))
        script_body.append("@copy /Y \"{src}\" \"{dst}\" >NUL".format(
            src = src.path.replace("/", "\\"),
            dst = dst.path.replace("/", "\\"),
        ))
    else:
        script_body.append("mkdir -p {dir} && cp -f {src} {dst}".format(
            dir = shell.quote(dst.dirname),
            src = shell.quote(src.path),
            dst = shell.quote(dst.path),
        ))

def flatten_transitive_dlls(ctx, dll, runtime_deps, tfm):
    """Copy all transitive DLLs into a flat directory alongside the main DLL.

    Args:
        ctx: The rule context.
        dll: The main output DLL File.
        runtime_deps: List of DotnetAssemblyRuntimeInfo-like structs (from deps.to_list()).
        tfm: Target framework moniker string.

    Returns:
        List of output files created by the copy action.
    """
    is_windows = ctx.target_platform_has_constraint(
        ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
    )
    inputs = []
    outputs = []
    script_body = ["@echo off"] if is_windows else ["#!/usr/bin/env bash", "set -eou pipefail"]

    seen_basenames = {dll.basename: True}

    for dep_info in runtime_deps:
        for lib in dep_info.libs:
            if lib.basename not in seen_basenames:
                seen_basenames[lib.basename] = True
                output = ctx.actions.declare_file(
                    "{}/{}/{}".format(ctx.label.name, tfm, lib.basename),
                )
                outputs.append(output)
                inputs.append(lib)
                copy_file(script_body, lib, output, is_windows)

    if outputs:
        copy_script = ctx.actions.declare_file(
            ctx.label.name + ".flatten_dlls." + ("bat" if is_windows else "sh"),
        )
        ctx.actions.write(
            output = copy_script,
            content = "\n".join(script_body),
            is_executable = True,
        )
        ctx.actions.run(
            outputs = outputs,
            inputs = inputs,
            executable = copy_script,
            tools = [copy_script],
            toolchain = None,
        )

    return outputs

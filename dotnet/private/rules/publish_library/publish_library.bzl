"""
Rule for publishing a .NET library with all transitive dependencies.
"""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("//dotnet/private:common.bzl", "generate_depsjson")
load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyCompileInfo",
    "DotnetAssemblyRuntimeInfo",
)
load("//dotnet/private/transitions:tfm_transition.bzl", "tfm_transition")

def _copy_file(script_body, src, dst, is_windows):
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

def _publish_library_impl(ctx):
    assembly_runtime_info = ctx.attr.library[0][DotnetAssemblyRuntimeInfo]
    target_framework = ctx.attr.target_framework
    assembly_name = assembly_runtime_info.name
    transitive_runtime_deps = assembly_runtime_info.deps.to_list()

    is_windows = ctx.target_platform_has_constraint(
        ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
    )

    # Generate deps.json (no runtimeconfig for libraries)
    depsjson = ctx.actions.declare_file(
        "{}/publish/{}.deps.json".format(ctx.label.name, assembly_name),
    )
    depsjson_struct = generate_depsjson(
        ctx,
        target_framework,
        is_self_contained = False,
        target_assembly_runtime_info = assembly_runtime_info,
        transitive_runtime_deps = transitive_runtime_deps,
    )
    ctx.actions.write(
        output = depsjson,
        content = json.encode_indent(depsjson_struct),
    )

    # Copy all files into flat publish directory
    inputs = []
    outputs = []
    script_body = ["@echo off"] if is_windows else ["#! /usr/bin/env bash", "set -eou pipefail"]

    # Track basenames to avoid duplicate file declarations
    seen_basenames = {}

    # Copy the main library DLLs
    for lib in assembly_runtime_info.libs:
        if lib.basename in seen_basenames:
            continue
        seen_basenames[lib.basename] = True
        output = ctx.actions.declare_file(
            "{}/publish/{}".format(ctx.label.name, lib.basename),
        )
        outputs.append(output)
        inputs.append(lib)
        _copy_file(script_body, lib, output, is_windows)

    # Copy transitive dependency libs
    for dep_variant in transitive_runtime_deps:
        dep = dep_variant.assembly_runtime_info
        for lib in dep.libs:
            if lib.basename in seen_basenames:
                continue
            seen_basenames[lib.basename] = True
            output = ctx.actions.declare_file(
                "{}/publish/{}".format(ctx.label.name, lib.basename),
            )
            outputs.append(output)
            inputs.append(lib)
            _copy_file(script_body, lib, output, is_windows)

        # Resource assemblies
        for res in dep.resource_assemblies:
            locale = res.dirname.split("/")[-1]
            res_key = "{}/{}".format(locale, res.basename)
            if res_key in seen_basenames:
                continue
            seen_basenames[res_key] = True
            output = ctx.actions.declare_file(
                "{}/publish/{}/{}".format(ctx.label.name, locale, res.basename),
            )
            outputs.append(output)
            inputs.append(res)
            _copy_file(script_body, res, output, is_windows)

        # Native files
        for native_file in dep.native:
            rid = native_file.dirname.split("/")[-2]
            native_key = "runtimes/{}/native/{}".format(rid, native_file.basename)
            if native_key in seen_basenames:
                continue
            seen_basenames[native_key] = True
            output = ctx.actions.declare_file(
                "{}/publish/runtimes/{}/native/{}".format(
                    ctx.label.name,
                    rid,
                    native_file.basename,
                ),
            )
            outputs.append(output)
            inputs.append(native_file)
            _copy_file(script_body, native_file, output, is_windows)

    if outputs:
        copy_script = ctx.actions.declare_file(
            ctx.label.name + ".copy.bat" if is_windows else ctx.label.name + ".copy.sh",
        )
        ctx.actions.write(
            output = copy_script,
            content = "\r\n".join(script_body) if is_windows else "\n".join(script_body),
            is_executable = True,
        )
        ctx.actions.run(
            outputs = outputs,
            inputs = inputs,
            executable = copy_script,
            tools = [copy_script],
            toolchain = None,
        )

    return [
        DefaultInfo(
            files = depset([depsjson] + outputs),
        ),
    ]

publish_library = rule(
    _publish_library_impl,
    doc = """Publish a .NET library with all transitive runtime dependencies.

    Collects all runtime DLLs into a flat publish directory and generates a
    deps.json file. Unlike publish_binary, no apphost or runtimeconfig.json
    is produced.
    """,
    attrs = {
        "library": attr.label(
            doc = "The .NET library target to publish",
            providers = [DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo],
            cfg = tfm_transition,
            mandatory = True,
        ),
        "target_framework": attr.string(
            doc = "The target framework to publish for",
            mandatory = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
    },
    toolchains = ["//dotnet:toolchain_type"],
)

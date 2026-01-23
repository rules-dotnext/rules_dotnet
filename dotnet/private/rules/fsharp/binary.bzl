"""
Rule for compiling F# binaries.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "//dotnet/private:common.bzl",
    "extract_native_libs_from_cc",
    "get_toolchain",
    "is_debug",
)
load("//dotnet/private/rules/analysis:resolve.bzl", "resolve_analysis_config")
load("//dotnet/private/rules/common:attrs.bzl", "FSHARP_BINARY_COMMON_ATTRS")
load("//dotnet/private/rules/common:binary.bzl", "build_binary")
load("//dotnet/private/rules/fsharp/actions:fsharp_assembly.bzl", "AssemblyAction")
load("//dotnet/private/transitions:tfm_transition.bzl", "tfm_transition")

def _compile_action(ctx, tfm):
    toolchain = get_toolchain(ctx)

    # Resolve global analysis config (warning settings only for F#)
    analysis = resolve_analysis_config(ctx)

    # #524 — expand $(location) in compiler_options
    compiler_options = [ctx.expand_location(opt, ctx.attr.compile_data) for opt in ctx.attr.compiler_options]

    # #349
    native = extract_native_libs_from_cc(ctx.attr.native_deps) if hasattr(ctx.attr, "native_deps") else []

    return AssemblyAction(
        ctx.actions,
        ctx.executable._compiler_wrapper_bat if ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]) else ctx.executable._compiler_wrapper_sh,
        label = ctx.label,
        debug = is_debug(ctx),
        defines = ctx.attr.defines,
        deps = ctx.attr.deps,
        exports = [],
        targeting_pack = ctx.attr._targeting_pack[0],
        internals_visible_to = ctx.attr.internals_visible_to,
        keyfile = ctx.file.keyfile,
        langversion = ctx.attr.langversion if ctx.attr.langversion != "" else toolchain.dotnetinfo.fsharp_default_version,
        resources = ctx.files.resources,
        srcs = ctx.files.srcs,
        data = ctx.files.data,
        appsetting_files = ctx.files.appsetting_files,
        compile_data = ctx.files.compile_data,
        out = ctx.attr.out,
        version = ctx.attr.version,
        target = "exe",
        target_name = ctx.attr.name,
        target_framework = tfm,
        toolchain = toolchain,
        strict_deps = toolchain.strict_deps[BuildSettingInfo].value,
        generate_documentation_file = ctx.attr.generate_documentation_file,
        treat_warnings_as_errors = analysis.effective_treat_warnings_as_errors,
        warnings_as_errors = analysis.effective_warnings_as_errors,
        warnings_not_as_errors = analysis.effective_warnings_not_as_errors,
        warning_level = analysis.effective_warning_level,
        nowarn = analysis.effective_nowarn,
        project_sdk = ctx.attr.project_sdk,
        compiler_options = compiler_options,
        pathmap = ctx.attr.pathmap,
        is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]),
        native = native,
    )

def _binary_private_impl(ctx):
    return build_binary(ctx, _compile_action)

fsharp_binary = rule(
    _binary_private_impl,
    doc = """Compile a F# exe""",
    attrs = FSHARP_BINARY_COMMON_ATTRS,
    executable = True,
    toolchains = [
        "//dotnet:toolchain_type",
    ],
    cfg = tfm_transition,
)

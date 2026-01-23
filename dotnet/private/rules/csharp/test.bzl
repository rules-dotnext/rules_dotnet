"""
Rule for compiling and running test binaries.

This rule can be used to compile and run any C# binary and run it as
a Bazel test.
"""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(
    "//dotnet/private:common.bzl",
    "extract_native_libs_from_cc",
    "get_toolchain",
    "is_debug",
)
load("//dotnet/private/rules/analysis:resolve.bzl", "resolve_analysis_config")
load("//dotnet/private/rules/common:attrs.bzl", "CSHARP_BINARY_COMMON_ATTRS")
load("//dotnet/private/rules/common:binary.bzl", "build_binary")
load("//dotnet/private/rules/csharp/actions:csharp_assembly.bzl", "AssemblyAction")
load("//dotnet/private/transitions:tfm_transition.bzl", "tfm_transition")

def _compile_action(ctx, tfm):
    toolchain = get_toolchain(ctx)

    # Resolve global analysis config
    analysis = resolve_analysis_config(ctx)

    # #524 — expand $(location) in compiler_options
    compiler_options = [ctx.expand_location(opt, ctx.attr.compile_data) for opt in ctx.attr.compiler_options]

    # #349
    native = extract_native_libs_from_cc(ctx.attr.native_deps) if hasattr(ctx.attr, "native_deps") else []

    return AssemblyAction(
        ctx.actions,
        ctx.executable._compiler_wrapper_bat if ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]) else ctx.executable._compiler_wrapper_sh,
        label = ctx.label,
        additionalfiles = ctx.files.additionalfiles,
        debug = is_debug(ctx),
        defines = ctx.attr.defines,
        deps = ctx.attr.deps,
        exports = [],
        targeting_pack = ctx.attr._targeting_pack[0],
        internals_visible_to = ctx.attr.internals_visible_to,
        keyfile = ctx.file.keyfile,
        langversion = ctx.attr.langversion if ctx.attr.langversion != "" else toolchain.dotnetinfo.csharp_default_version,
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
        include_host_model_dll = False,
        treat_warnings_as_errors = analysis.effective_treat_warnings_as_errors,
        warnings_as_errors = analysis.effective_warnings_as_errors,
        warnings_not_as_errors = analysis.effective_warnings_not_as_errors,
        warning_level = analysis.effective_warning_level,
        nowarn = analysis.effective_nowarn,
        project_sdk = ctx.attr.project_sdk,
        allow_unsafe_blocks = ctx.attr.allow_unsafe_blocks,
        nullable = ctx.attr.nullable,
        run_analyzers = ctx.attr.run_analyzers,
        is_analyzer = False,
        is_language_specific_analyzer = False,
        analyzer_configs = ctx.files.analyzer_configs + analysis.extra_global_configs,
        extra_analyzer_files = analysis.extra_analyzer_files,
        compiler_options = compiler_options,
        pathmap = ctx.attr.pathmap,
        is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]),
        implicit_usings = ctx.attr.implicit_usings,
        native = native,
    )

def _csharp_test_impl(ctx):
    return build_binary(ctx, _compile_action)

# #359 — Test-only attrs for coverage support
_CSHARP_TEST_ATTRS = dicts.add(
    CSHARP_BINARY_COMMON_ATTRS,
    {
        "_lcov_merger": attr.label(
            default = configuration_field(fragment = "coverage", name = "output_generator"),
            executable = True,
            cfg = "exec",
        ),
    },
)

csharp_test = rule(
    _csharp_test_impl,
    doc = """Compiles a C# executable and runs it as a test""",
    attrs = _CSHARP_TEST_ATTRS,
    test = True,
    toolchains = [
        "//dotnet:toolchain_type",
    ],
    cfg = tfm_transition,
)

"Common implementation for building .Net libraries"

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//dotnet/private:common.bzl", "collect_transitive_runfiles")

def build_library(ctx, compile_action):
    """Builds a .Net library from a compilation action

    Args:
        ctx: Bazel build ctx.
        compile_action: A compilation function
            Args:
                ctx: Bazel build ctx.
                tfm: Target framework string
            Returns:
                An tuple of (DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo)
    Returns:
        A collection of the references, runfiles and native dlls.
    """
    tfm = ctx.attr._target_framework[BuildSettingInfo].value

    (compile_provider, runtime_provider) = compile_action(ctx, tfm)

    # spec-testing-infra: #359 — Coverage instrumentation info
    instrumented_files_info = coverage_common.instrumented_files_info(
        ctx,
        source_attributes = ["srcs"],
        dependency_attributes = ["deps", "data"],
        extensions = ["cs", "fs"],
    )

    return [
        compile_provider,
        runtime_provider,
        DefaultInfo(
            files = depset(runtime_provider.libs + runtime_provider.xml_docs),
            default_runfiles = collect_transitive_runfiles(
                ctx,
                runtime_provider,
                ctx.attr.deps,
            ),
        ),
        instrumented_files_info,
    ]

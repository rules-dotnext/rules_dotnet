"""Rule for compiling C# gRPC libraries from proto_library targets."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load(
    "//dotnet/private:common.bzl",
    "collect_transitive_runfiles",
    "get_toolchain",
    "is_debug",
)
load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyCompileInfo",
    "DotnetAssemblyRuntimeInfo",
)
load(
    "//dotnet/private/rules/csharp/actions:csharp_assembly.bzl",
    "AssemblyAction",
)
load(
    "//dotnet/private/rules/proto:csharp_proto_compiler.bzl",
    "CSharpProtoCompilerInfo",
)
load(
    "//dotnet/private/rules/proto:proto_compile.bzl",
    "csharp_proto_compile",
)
load(
    "//dotnet/private/sdk/targeting_packs:targeting_pack_transition.bzl",
    "targeting_pack_transition",
)
load(
    "//dotnet/private/transitions:default_transition.bzl",
    "default_transition",
)
load(
    "//dotnet/private/transitions:tfm_transition.bzl",
    "tfm_transition",
)

def _empty_providers(name):
    """Return empty providers when there are no sources to compile."""
    return [
        DotnetAssemblyCompileInfo(
            name = name,
            version = "1.0.0",
            project_sdk = "default",
            refs = [],
            irefs = [],
            analyzers = [],
            analyzers_csharp = [],
            analyzers_fsharp = [],
            analyzers_vb = [],
            internals_visible_to = [],
            compile_data = [],
            exports = [],
            transitive_refs = depset(),
            transitive_analyzers = depset(),
            transitive_analyzers_csharp = depset(),
            transitive_analyzers_fsharp = depset(),
            transitive_analyzers_vb = depset(),
            transitive_compile_data = depset(),
        ),
        DotnetAssemblyRuntimeInfo(
            name = name,
            version = "1.0.0",
            libs = [],
            pdbs = [],
            xml_docs = [],
            native = [],
            data = [],
            resource_assemblies = [],
            appsetting_files = depset(),
            nuget_info = None,
            deps = depset(),
            direct_deps_depsjson_fragment = {},
        ),
        DefaultInfo(files = depset()),
    ]

def _csharp_grpc_library_impl(ctx):
    tfm = ctx.attr._target_framework[BuildSettingInfo].value
    toolchain = get_toolchain(ctx)

    # proto attr uses default_transition, so it's a list
    proto_info = ctx.attr.proto[0][ProtoInfo]

    # compiler uses default_transition, so it's a list
    compiler_info = ctx.attr.compiler[0][CSharpProtoCompilerInfo]

    # Phase 1: Generate gRPC C# sources
    generated_srcs = csharp_proto_compile(
        actions = ctx.actions,
        compiler_info = compiler_info,
        proto_info = proto_info,
        out_dir_name = ctx.attr.name + "_grpc_gen",
    )

    if not generated_srcs:
        return _empty_providers(ctx.attr.name)

    # Collect deps: explicit deps (proto deps + NuGet runtime deps)
    all_deps = list(ctx.attr.deps)

    # Phase 2: Compile gRPC generated sources
    (compile_info, runtime_info) = AssemblyAction(
        ctx.actions,
        ctx.executable._compiler_wrapper_bat if ctx.target_platform_has_constraint(
            ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
        ) else ctx.executable._compiler_wrapper_sh,
        label = ctx.label,
        additionalfiles = [],
        debug = is_debug(ctx),
        defines = [],
        deps = all_deps,
        exports = [],
        targeting_pack = ctx.attr._targeting_pack[0],
        internals_visible_to = [],
        keyfile = None,
        langversion = toolchain.dotnetinfo.csharp_default_version,
        resources = [],
        srcs = generated_srcs,
        data = [],
        appsetting_files = [],
        compile_data = [],
        out = ctx.attr.out if ctx.attr.out else "",
        version = "",
        target = "library",
        target_name = ctx.attr.name,
        target_framework = tfm,
        toolchain = toolchain,
        strict_deps = toolchain.strict_deps[BuildSettingInfo].value,
        generate_documentation_file = False,
        include_host_model_dll = False,
        treat_warnings_as_errors = False,
        warnings_as_errors = [],
        warnings_not_as_errors = [],
        warning_level = 0,
        nowarn = ["CS1591"],
        project_sdk = ctx.attr.project_sdk,
        allow_unsafe_blocks = False,
        nullable = "disable",
        run_analyzers = False,
        is_analyzer = False,
        is_language_specific_analyzer = False,
        analyzer_configs = [],
        compiler_options = [],
        pathmap = {},
        is_windows = ctx.target_platform_has_constraint(
            ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
        ),
    )

    return [
        compile_info,
        runtime_info,
        DefaultInfo(
            files = depset(runtime_info.libs + runtime_info.xml_docs),
            default_runfiles = collect_transitive_runfiles(
                ctx,
                runtime_info,
                all_deps,
            ),
        ),
        OutputGroupInfo(
            csharp_generated_srcs = generated_srcs,
        ),
    ]

csharp_grpc_library = rule(
    implementation = _csharp_grpc_library_impl,
    doc = """Generates a C# gRPC library from a proto_library.

    This rule invokes protoc with the grpc_csharp_plugin to generate gRPC
    service stubs, then compiles them into a .NET assembly.

    You must include Grpc.Core.Api NuGet package in `deps`, along with
    a csharp_proto_library for the same proto.

    Example:
        csharp_proto_library(
            name = "hello_csharp_proto",
            proto = ":hello_proto",
            target_frameworks = ["net8.0"],
            deps = ["@nuget//google.protobuf"],
        )

        csharp_grpc_library(
            name = "hello_csharp_grpc",
            proto = ":hello_proto",
            deps = [
                ":hello_csharp_proto",
                "@nuget//grpc.core.api",
            ],
            target_frameworks = ["net8.0"],
        )
    """,
    attrs = {
        "proto": attr.label(
            doc = "The proto_library target to generate gRPC C# code for.",
            mandatory = True,
            providers = [ProtoInfo],
            cfg = default_transition,
        ),
        "deps": attr.label_list(
            doc = "Dependencies including the csharp_proto_library and NuGet packages (Grpc.Core.Api).",
            providers = [DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo],
            cfg = tfm_transition,
        ),
        "compiler": attr.label(
            doc = "The csharp_proto_compiler to use for gRPC. Defaults to the built-in grpc_csharp_plugin.",
            providers = [CSharpProtoCompilerInfo],
            default = "//dotnet/private/rules/proto:default_csharp_grpc_compiler",
            cfg = default_transition,
        ),
        "out": attr.string(
            doc = "Output assembly name (without extension). Defaults to rule name.",
        ),
        "target_frameworks": attr.string_list(
            doc = "Target framework monikers to build for.",
            mandatory = True,
            allow_empty = False,
        ),
        "data": attr.label_list(
            doc = "Runtime data files.",
            allow_files = True,
            default = [],
            cfg = default_transition,
        ),
        "project_sdk": attr.string(
            doc = "The project SDK being targeted.",
            default = "default",
            values = ["default", "web"],
        ),
        # Private attributes (same as csharp_proto_library)
        "_target_framework": attr.label(
            default = "//dotnet:target_framework",
        ),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_compiler_wrapper_sh": attr.label(
            default = "//dotnet/private:compiler_wrapper.sh",
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "_compiler_wrapper_bat": attr.label(
            default = "//dotnet/private:compiler_wrapper.bat",
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "_targeting_pack": attr.label(
            default = "//dotnet/private/sdk/targeting_packs:targeting_pack",
            cfg = targeting_pack_transition,
        ),
    },
    toolchains = ["//dotnet:toolchain_type"],
    cfg = tfm_transition,
)

"""
Rule for compiling a .NET binary to a standalone native executable using NativeAOT.
"""

load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyRuntimeInfo",
    "DotnetBinaryInfo",
    "DotnetNativeAotPackInfo",
)
load("//dotnet/private/transitions:tfm_transition.bzl", "tfm_transition")

def _collect_all_managed_assemblies(binary_info, assembly_runtime_info):
    """Collect all managed DLLs from binary and its transitive deps."""
    dlls = [binary_info.dll]
    dlls.extend(assembly_runtime_info.libs)
    for dep in binary_info.transitive_runtime_deps:
        dlls.extend(dep.libs)
    return dlls

def _build_ilc_response_file(ctx, managed_dlls, aot_pack, native_obj):
    """Build a response file for the ILC compiler."""
    lines = []

    # Output file
    lines.append("-o:" + native_obj.path)

    # Input assemblies
    for dll in managed_dlls:
        lines.append(dll.path)

    # Target architecture from RID
    rid = aot_pack.runtime_identifier
    if "x64" in rid:
        lines.append("--targetarch:x64")
    elif "arm64" in rid:
        lines.append("--targetarch:arm64")
    elif "x86" in rid:
        lines.append("--targetarch:x86")

    # Optimization mode
    if ctx.attr.optimization_mode == "size":
        lines.append("-Os")
    else:
        lines.append("-O")

    # Invariant globalization
    if ctx.attr.invariant_globalization:
        lines.append("--feature:System.Globalization.Invariant=true")

    # Reference assemblies from AOT pack
    for ref in aot_pack.reference_assemblies:
        lines.append("-r:" + ref.path)

    # MIBC profile data
    for mibc in aot_pack.mibc_files:
        lines.append("--mibc:" + mibc.path)

    rsp_file = ctx.actions.declare_file(ctx.label.name + ".ilc.rsp")
    ctx.actions.write(output = rsp_file, content = "\n".join([line for line in lines if line]))
    return rsp_file

def _native_aot_binary_impl(ctx):
    binary_info = ctx.attr.binary[0][DotnetBinaryInfo]
    assembly_runtime_info = ctx.attr.binary[0][DotnetAssemblyRuntimeInfo]
    aot_pack = ctx.attr.native_aot_pack[DotnetNativeAotPackInfo]

    is_windows = ctx.target_platform_has_constraint(
        ctx.attr._windows_constraint[platform_common.ConstraintValueInfo],
    )
    is_macos = ctx.target_platform_has_constraint(
        ctx.attr._macos_constraint[platform_common.ConstraintValueInfo],
    )

    managed_dlls = _collect_all_managed_assemblies(binary_info, assembly_runtime_info)
    assembly_name = assembly_runtime_info.name

    # Step 1: Run ILC to produce native object file
    obj_ext = ".obj" if is_windows else ".o"
    native_obj = ctx.actions.declare_file(
        "{}/{}{}".format(ctx.label.name, assembly_name, obj_ext),
    )

    rsp_file = _build_ilc_response_file(ctx, managed_dlls, aot_pack, native_obj)

    ilc_inputs = managed_dlls + aot_pack.reference_assemblies + aot_pack.mibc_files + [rsp_file]

    ctx.actions.run(
        executable = aot_pack.ilc,
        arguments = ["@" + rsp_file.path],
        inputs = ilc_inputs,
        outputs = [native_obj],
        mnemonic = "DotnetIlc",
        progress_message = "NativeAOT compiling %{label}",
        toolchain = "//dotnet:toolchain_type",
    )

    # Step 2: Link the native object file with static runtime libs
    output_ext = ".exe" if is_windows else ""
    native_binary = ctx.actions.declare_file(
        "{}/{}{}".format(ctx.label.name, assembly_name, output_ext),
    )

    cc_toolchain = ctx.attr._cc_toolchain[cc_common.CcToolchainInfo]
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )

    link_inputs = [native_obj] + aot_pack.sdk_libs + aot_pack.framework_libs

    # Build linker arguments
    linker_args = ctx.actions.args()

    if is_windows:
        linker_args.add("/OUT:" + native_binary.path)
        linker_args.add(native_obj.path)
        for lib in aot_pack.sdk_libs + aot_pack.framework_libs:
            linker_args.add(lib.path)

        # Windows system libraries required by NativeAOT
        for syslib in [
            "advapi32.lib",
            "bcrypt.lib",
            "crypt32.lib",
            "iphlpapi.lib",
            "kernel32.lib",
            "mswsock.lib",
            "ncrypt.lib",
            "normaliz.lib",
            "ntdll.lib",
            "ole32.lib",
            "oleaut32.lib",
            "secur32.lib",
            "user32.lib",
            "version.lib",
            "ws2_32.lib",
        ]:
            linker_args.add(syslib)
    else:
        linker_args.add("-o", native_binary.path)
        linker_args.add(native_obj.path)
        for lib in aot_pack.sdk_libs + aot_pack.framework_libs:
            linker_args.add(lib.path)

        # POSIX system libraries required by NativeAOT
        linker_args.add("-lstdc++")
        linker_args.add("-lpthread")
        linker_args.add("-ldl")
        linker_args.add("-lm")
        linker_args.add("-lz")
        if is_macos:
            linker_args.add("-framework", "Foundation")
            linker_args.add("-framework", "Security")
            linker_args.add("-framework", "GSS")
            linker_args.add("-licucore")

    linker = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = "c++-link-executable",
    )

    ctx.actions.run(
        executable = linker,
        arguments = [linker_args],
        inputs = depset(link_inputs, transitive = [cc_toolchain.all_files]),
        outputs = [native_binary],
        mnemonic = "DotnetNativeAotLink",
        progress_message = "Linking NativeAOT binary %{label}",
        toolchain = "@bazel_tools//tools/cpp:toolchain_type",
    )

    return [
        DefaultInfo(
            executable = native_binary,
            files = depset([native_binary]),
        ),
    ]

native_aot_binary = rule(
    _native_aot_binary_impl,
    doc = """Compile a .NET binary to a standalone native executable using NativeAOT.

    Produces a fully native binary with no dependency on the .NET runtime.
    Equivalent to `dotnet publish -p:PublishAot=true`.
    """,
    attrs = {
        "binary": attr.label(
            doc = "The .NET binary to compile with NativeAOT",
            providers = [DotnetBinaryInfo],
            cfg = tfm_transition,
            mandatory = True,
        ),
        "target_framework": attr.string(
            doc = "The target framework (e.g. net8.0)",
            mandatory = True,
        ),
        "native_aot_pack": attr.label(
            doc = "The NativeAOT compiler pack providing ILC and static runtime libraries",
            providers = [DotnetNativeAotPackInfo],
            mandatory = True,
        ),
        "optimization_mode": attr.string(
            doc = "Optimization preference: 'speed' or 'size'",
            default = "speed",
            values = ["speed", "size"],
        ),
        "invariant_globalization": attr.bool(
            doc = "Use invariant globalization (removes ICU dependency)",
            default = False,
        ),
        "_cc_toolchain": attr.label(
            default = "@bazel_tools//tools/cpp:current_cc_toolchain",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
        "_macos_constraint": attr.label(default = "@platforms//os:macos"),
    },
    toolchains = [
        "//dotnet:toolchain_type",
        "@bazel_tools//tools/cpp:toolchain_type",
    ],
    executable = True,
    fragments = ["cpp"],
    cfg = tfm_transition,
)

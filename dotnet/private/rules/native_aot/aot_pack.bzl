"""Rule for declaring a NativeAOT compiler pack."""

load("//dotnet/private:providers.bzl", "DotnetNativeAotPackInfo")

def _native_aot_pack_impl(ctx):
    ilc = ctx.file.ilc
    return [
        DotnetNativeAotPackInfo(
            ilc = ilc,
            runtime_identifier = ctx.attr.runtime_identifier,
            mibc_files = ctx.files.mibc_files,
            sdk_libs = ctx.files.sdk_libs,
            framework_libs = ctx.files.framework_libs,
            reference_assemblies = ctx.files.reference_assemblies,
        ),
    ]

native_aot_pack = rule(
    _native_aot_pack_impl,
    doc = "Declare a NativeAOT compiler pack.",
    attrs = {
        "ilc": attr.label(
            doc = "The ILC compiler executable",
            allow_single_file = True,
            mandatory = True,
        ),
        "runtime_identifier": attr.string(
            doc = "The RID this pack targets (e.g. linux-x64)",
            mandatory = True,
        ),
        "mibc_files": attr.label_list(
            doc = "MIBC profile-guided optimization files",
            allow_files = True,
        ),
        "sdk_libs": attr.label_list(
            doc = "Static runtime libraries (.a / .lib)",
            allow_files = True,
            mandatory = True,
        ),
        "framework_libs": attr.label_list(
            doc = "Framework static libraries",
            allow_files = True,
        ),
        "reference_assemblies": attr.label_list(
            doc = "Reference assemblies needed by ILC",
            allow_files = True,
            mandatory = True,
        ),
    },
)

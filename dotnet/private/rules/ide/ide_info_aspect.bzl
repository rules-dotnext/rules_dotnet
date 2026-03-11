"Aspect that walks the build graph to collect IDE metadata into DotnetIdeInfo."

load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyCompileInfo",
    "DotnetAssemblyRuntimeInfo",
)
load(
    "//dotnet/private/rules/ide:providers.bzl",
    "DotnetIdeInfo",
)

# Rule kinds that produce executables
_BINARY_KINDS = [
    "csharp_binary",
    "csharp_test",
    "fsharp_binary",
    "fsharp_test",
]

def _ide_info_aspect_impl(target, ctx):
    # Skip targets that don't have the required providers
    if DotnetAssemblyCompileInfo not in target or DotnetAssemblyRuntimeInfo not in target:
        return []

    runtime_info = target[DotnetAssemblyRuntimeInfo]
    compile_info = target[DotnetAssemblyCompileInfo]
    is_nuget = runtime_info.nuget_info != None

    if is_nuget:
        return [DotnetIdeInfo(
            label = target.label,
            name = compile_info.name,
            is_nuget = True,
            nuget_id = runtime_info.name,
            nuget_version = runtime_info.version,
            srcs = [],
            target_framework = "",
            langversion = "",
            nullable = "disable",
            allow_unsafe_blocks = False,
            output_type = "Library",
            project_sdk = compile_info.project_sdk,
            analyzers = [],
            direct_project_deps = [],
            direct_nuget_deps = [],
        )]

    # Project node — read attrs from the underlying rule
    srcs = []
    if hasattr(ctx.rule.files, "srcs"):
        srcs = ctx.rule.files.srcs

    langversion = ""
    if hasattr(ctx.rule.attr, "langversion") and ctx.rule.attr.langversion:
        langversion = ctx.rule.attr.langversion

    nullable = "disable"
    if hasattr(ctx.rule.attr, "nullable"):
        nullable = ctx.rule.attr.nullable

    allow_unsafe_blocks = False
    if hasattr(ctx.rule.attr, "allow_unsafe_blocks"):
        allow_unsafe_blocks = ctx.rule.attr.allow_unsafe_blocks

    output_type = "Exe" if ctx.rule.kind in _BINARY_KINDS else "Library"
    project_sdk = compile_info.project_sdk

    # Collect analyzers (common + C#-specific)
    analyzers = list(compile_info.analyzers) + list(compile_info.analyzers_csharp)

    # Classify direct deps as NuGet or project
    direct_project_deps = []
    direct_nuget_deps = []
    seen_nuget = {}

    for attr_name in ["deps", "exports"]:
        if not hasattr(ctx.rule.attr, attr_name):
            continue
        for dep in getattr(ctx.rule.attr, attr_name):
            if DotnetIdeInfo not in dep:
                continue
            dep_info = dep[DotnetIdeInfo]
            if dep_info.is_nuget:
                key = dep_info.nuget_id + "@" + dep_info.nuget_version
                if key not in seen_nuget:
                    seen_nuget[key] = True
                    direct_nuget_deps.append(struct(
                        id = dep_info.nuget_id,
                        version = dep_info.nuget_version,
                    ))
            else:
                direct_project_deps.append(dep_info)

    return [DotnetIdeInfo(
        label = target.label,
        name = compile_info.name,
        is_nuget = False,
        nuget_id = None,
        nuget_version = None,
        srcs = srcs,
        target_framework = "",
        langversion = langversion,
        nullable = nullable,
        allow_unsafe_blocks = allow_unsafe_blocks,
        output_type = output_type,
        project_sdk = project_sdk,
        analyzers = analyzers,
        direct_project_deps = direct_project_deps,
        direct_nuget_deps = direct_nuget_deps,
    )]

ide_info_aspect = aspect(
    implementation = _ide_info_aspect_impl,
    attr_aspects = ["deps", "exports"],
)

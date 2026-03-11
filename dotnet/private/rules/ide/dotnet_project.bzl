"""Rule for generating .csproj files for IDE support.

Generates complete .csproj files with NuGet PackageReferences, ProjectReferences,
and analyzer entries by walking the build graph via ide_info_aspect.

See https://github.com/bazel-contrib/rules_dotnet/issues/228
"""

load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyCompileInfo",
    "DotnetAssemblyRuntimeInfo",
)
load(
    "//dotnet/private/rules/ide:ide_info_aspect.bzl",
    "ide_info_aspect",
)
load(
    "//dotnet/private/rules/ide:providers.bzl",
    "DotnetIdeInfo",
)
load(
    "//dotnet/private/transitions:tfm_transition.bzl",
    "tfm_transition",
)

_CSPROJ_TEMPLATE = """\
<Project Sdk="{project_sdk}">
  <PropertyGroup>
    <TargetFramework>{target_framework}</TargetFramework>
    <RootNamespace>{root_namespace}</RootNamespace>
    <AssemblyName>{assembly_name}</AssemblyName>
    <LangVersion>{langversion}</LangVersion>
    <Nullable>{nullable}</Nullable>
    <AllowUnsafeBlocks>{allow_unsafe_blocks}</AllowUnsafeBlocks>
    <OutputType>{output_type}</OutputType>
    <!-- This project is for IDE support only. Build with Bazel. -->
    <ProduceReferenceAssembly>false</ProduceReferenceAssembly>
  </PropertyGroup>

  <PropertyGroup>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <EnableDefaultItems>false</EnableDefaultItems>
  </PropertyGroup>

  <ItemGroup>
{compile_items}
  </ItemGroup>
{package_references}{project_references}{analyzer_references}
</Project>
"""

_COPY_SCRIPT_TEMPLATE = """\
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE_ROOT="${{BUILD_WORKSPACE_DIRECTORY}}"
CSPROJ_SOURCE="$0.runfiles/{workspace_name}/{csproj_short_path}"
CSPROJ_DEST="${{WORKSPACE_ROOT}}/{package}/{csproj_name}.csproj"

mkdir -p "$(dirname "${{CSPROJ_DEST}}")"
cp "${{CSPROJ_SOURCE}}" "${{CSPROJ_DEST}}"
echo "Generated ${{CSPROJ_DEST}}"
"""

def _relative_path(from_package, to_package, to_name):
    """Compute relative path from one package to another's .csproj."""
    from_parts = from_package.split("/") if from_package else []
    to_parts = to_package.split("/") if to_package else []

    # Go up from from_package to workspace root, then down to to_package
    up = "../" * len(from_parts) if from_parts else ""
    down = "/".join(to_parts) + "/" if to_parts else ""
    return up + down + to_name + ".csproj"

def _sdk_string(project_sdk):
    """Map internal project_sdk value to MSBuild SDK string."""
    if project_sdk == "web":
        return "Microsoft.NET.Sdk.Web"
    return "Microsoft.NET.Sdk"

def _dotnet_project_impl(ctx):
    """Generate a .csproj file from aspect data and optional overrides."""

    # cfg = tfm_transition on a singular attr.label wraps in a list
    target = ctx.attr.target[0]
    ide_info = target[DotnetIdeInfo]

    # Sources: use explicit srcs if provided, otherwise fall back to aspect
    srcs = ctx.files.srcs if ctx.files.srcs else ide_info.srcs
    src_items = []
    for src in srcs:
        src_items.append("    <Compile Include=\"%s\" />" % src.short_path)
    compile_items = "\n".join(src_items) if src_items else ""

    # Assembly name
    assembly_name = ctx.attr.csproj_name if ctx.attr.csproj_name else ctx.attr.name.replace(".project", "")

    # Properties: explicit attrs override aspect-inferred values
    nullable = ctx.attr.nullable if ctx.attr.nullable else ide_info.nullable
    langversion = ctx.attr.langversion if ctx.attr.langversion else ide_info.langversion
    if not langversion:
        langversion = "default"
    allow_unsafe = ctx.attr.allow_unsafe_blocks or ide_info.allow_unsafe_blocks
    output_type = ctx.attr.output_type if ctx.attr.output_type else ide_info.output_type
    if not output_type:
        output_type = "Library"

    # Project SDK: explicit attr overrides aspect
    project_sdk = ctx.attr.project_sdk
    if not project_sdk or project_sdk == "Microsoft.NET.Sdk":
        sdk_val = ide_info.project_sdk
        if sdk_val:
            project_sdk = _sdk_string(sdk_val)
        else:
            project_sdk = "Microsoft.NET.Sdk"

    # Package references from NuGet deps
    pkg_refs = ""
    if ide_info.direct_nuget_deps:
        lines = ["", "  <ItemGroup>"]
        for dep in ide_info.direct_nuget_deps:
            lines.append("    <PackageReference Include=\"%s\" Version=\"%s\" />" % (dep.id, dep.version))
        lines.append("  </ItemGroup>")
        pkg_refs = "\n".join(lines) + "\n"

    # Project references from project deps
    proj_refs = ""
    if ide_info.direct_project_deps:
        my_package = ctx.label.package
        lines = ["", "  <ItemGroup>"]
        for dep in ide_info.direct_project_deps:
            rel = _relative_path(my_package, dep.label.package, dep.name)
            lines.append("    <ProjectReference Include=\"%s\" />" % rel)
        lines.append("  </ItemGroup>")
        proj_refs = "\n".join(lines) + "\n"

    # Analyzer references
    analyzer_refs = ""
    if ide_info.analyzers:
        lines = ["", "  <ItemGroup>"]
        for a in ide_info.analyzers:
            lines.append("    <Analyzer Include=\"%s\" />" % a.short_path)
        lines.append("  </ItemGroup>")
        analyzer_refs = "\n".join(lines) + "\n"

    # Render .csproj
    csproj_content = _CSPROJ_TEMPLATE.format(
        project_sdk = project_sdk,
        target_framework = ctx.attr.target_framework,
        root_namespace = ctx.attr.root_namespace if ctx.attr.root_namespace else assembly_name,
        assembly_name = assembly_name,
        langversion = langversion,
        nullable = nullable,
        allow_unsafe_blocks = "true" if allow_unsafe else "false",
        output_type = output_type,
        compile_items = compile_items,
        package_references = pkg_refs,
        project_references = proj_refs,
        analyzer_references = analyzer_refs,
    )

    output = ctx.actions.declare_file(ctx.attr.name + ".csproj")
    ctx.actions.write(output, csproj_content)

    # Generate copy script
    copy_script = ctx.actions.declare_file(ctx.attr.name + "_generate.sh")
    ctx.actions.write(
        output = copy_script,
        content = _COPY_SCRIPT_TEMPLATE.format(
            workspace_name = ctx.workspace_name,
            csproj_short_path = output.short_path,
            package = ctx.label.package,
            csproj_name = assembly_name,
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = [output])

    return [
        DefaultInfo(
            files = depset([output]),
            executable = copy_script,
            runfiles = runfiles,
        ),
    ]

_dotnet_project = rule(
    implementation = _dotnet_project_impl,
    doc = """Generate a .csproj file for IDE support.

Run with `bazel run` to copy the generated .csproj into the source tree
where Visual Studio, Rider, or OmniSharp can discover it.

The rule walks the target's dependency graph via an aspect to populate
PackageReference, ProjectReference, and Analyzer entries automatically.
""",
    attrs = {
        "target": attr.label(
            doc = "The csharp_binary or csharp_library target this project corresponds to.",
            mandatory = True,
            providers = [DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo],
            aspects = [ide_info_aspect],
            cfg = tfm_transition,
        ),
        "target_framework": attr.string(
            doc = "The target framework moniker (e.g., net8.0).",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Source files to include in the .csproj. If omitted, inferred from the target via aspect.",
            allow_files = [".cs"],
        ),
        "project_sdk": attr.string(
            doc = "The .NET project SDK.",
            default = "Microsoft.NET.Sdk",
        ),
        "output_type": attr.string(
            doc = "The output type (Exe or Library). If omitted, inferred from target rule kind.",
        ),
        "root_namespace": attr.string(
            doc = "The root namespace. Defaults to the assembly name.",
        ),
        "langversion": attr.string(
            doc = "The C# language version. If omitted, inferred from the target.",
        ),
        "nullable": attr.string(
            doc = "Nullable context. If omitted, inferred from the target.",
        ),
        "allow_unsafe_blocks": attr.bool(
            doc = "Whether to allow unsafe blocks.",
            default = False,
        ),
        "csproj_name": attr.string(
            doc = "Override the generated .csproj file name.",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
)

def dotnet_project(name, target, target_framework, srcs = None, **kwargs):
    """Macro that generates a .csproj for IDE support.

    Usage:
        csharp_library(
            name = "mylib",
            srcs = ["Foo.cs"],
            target_frameworks = ["net8.0"],
        )

        dotnet_project(
            name = "mylib.project",
            target = ":mylib",
            target_framework = "net8.0",
        )

    Then run: bazel run //path:mylib.project
    This generates path/mylib.csproj that Visual Studio / Rider / OmniSharp can consume.

    Args:
        name: Name of the target. Convention: "{library_name}.project"
        target: The csharp_binary or csharp_library label.
        target_framework: Target framework moniker (e.g., "net8.0").
        srcs: Source files (optional, inferred from target if omitted).
        **kwargs: Additional attributes passed to the underlying rule.
    """
    extra = {}
    if srcs != None:
        extra["srcs"] = srcs
    _dotnet_project(
        name = name,
        target = target,
        target_framework = target_framework,
        **dict(extra, **kwargs)
    )

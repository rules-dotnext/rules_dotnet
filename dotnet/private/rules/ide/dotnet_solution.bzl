"""Rule for generating Visual Studio .sln files with supporting IDE files.

Aggregates multiple csharp_binary/csharp_library targets into a complete
VS solution with .csproj files, Directory.Build.props, NuGet.config,
and launchSettings.json for debugger integration.
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

# C# project type GUID
_CSHARP_PROJECT_TYPE_GUID = "FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"

_HEX = "0123456789abcdef"

def _int_to_hex(n, digits):
    """Convert integer to hex string with fixed width."""
    if n < 0:
        n = -n
    chars = []
    for _ in range(digits):
        chars.append(_HEX[n % 16])
        n = n // 16
    return "".join(reversed(chars))

def _label_to_guid(label):
    """Generate a deterministic GUID from a Bazel label."""
    s = str(label)
    h1 = hash(s)
    h2 = hash(s + ":guid")
    h3 = hash(s + ":proj")
    h4 = hash(s + ":sln")
    return "%s-%s-%s-%s-%s" % (
        _int_to_hex(h1, 8),
        _int_to_hex(h2, 4),
        _int_to_hex(h3, 4),
        _int_to_hex(h4, 4),
        _int_to_hex(h1 ^ h2 ^ h3 ^ h4, 12),
    )

def _relative_path(from_package, to_package, to_name):
    """Compute relative path from one package to another's .csproj."""
    from_parts = from_package.split("/") if from_package else []
    to_parts = to_package.split("/") if to_package else []
    up = "../" * len(from_parts) if from_parts else ""
    down = "/".join(to_parts) + "/" if to_parts else ""
    return up + down + to_name + ".csproj"

def _sdk_string(project_sdk):
    """Map internal project_sdk value to MSBuild SDK string."""
    if project_sdk == "web":
        return "Microsoft.NET.Sdk.Web"
    return "Microsoft.NET.Sdk"

def _make_csproj(ide_info, target_framework, this_package):
    """Generate .csproj XML content from DotnetIdeInfo."""
    src_items = []
    for src in ide_info.srcs:
        src_items.append("    <Compile Include=\"%s\" />" % src.short_path)
    compile_items = "\n".join(src_items) if src_items else ""

    assembly_name = ide_info.name
    nullable = ide_info.nullable if ide_info.nullable else "disable"
    langversion = ide_info.langversion if ide_info.langversion else "default"
    allow_unsafe = "true" if ide_info.allow_unsafe_blocks else "false"
    output_type = ide_info.output_type if ide_info.output_type else "Library"
    project_sdk = _sdk_string(ide_info.project_sdk) if ide_info.project_sdk else "Microsoft.NET.Sdk"

    # Package references
    pkg_refs = ""
    if ide_info.direct_nuget_deps:
        lines = ["", "  <ItemGroup>"]
        for dep in ide_info.direct_nuget_deps:
            lines.append("    <PackageReference Include=\"%s\" Version=\"%s\" />" % (dep.id, dep.version))
        lines.append("  </ItemGroup>")
        pkg_refs = "\n".join(lines) + "\n"

    # Project references
    proj_refs = ""
    if ide_info.direct_project_deps:
        my_pkg = ide_info.label.package
        lines = ["", "  <ItemGroup>"]
        for dep in ide_info.direct_project_deps:
            rel = _relative_path(my_pkg, dep.label.package, dep.name)
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

    return """\
<Project Sdk="{sdk}">
  <PropertyGroup>
    <TargetFramework>{tfm}</TargetFramework>
    <RootNamespace>{ns}</RootNamespace>
    <AssemblyName>{asm}</AssemblyName>
    <LangVersion>{lang}</LangVersion>
    <Nullable>{nullable}</Nullable>
    <AllowUnsafeBlocks>{unsafe}</AllowUnsafeBlocks>
    <OutputType>{output}</OutputType>
    <ProduceReferenceAssembly>false</ProduceReferenceAssembly>
  </PropertyGroup>

  <PropertyGroup>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <EnableDefaultItems>false</EnableDefaultItems>
  </PropertyGroup>

  <ItemGroup>
{compile}
  </ItemGroup>
{pkgs}{projs}{analyzers}
</Project>
""".format(
        sdk = project_sdk,
        tfm = target_framework,
        ns = assembly_name,
        asm = assembly_name,
        lang = langversion,
        nullable = nullable,
        unsafe = allow_unsafe,
        output = output_type,
        compile = compile_items,
        pkgs = pkg_refs,
        projs = proj_refs,
        analyzers = analyzer_refs,
    )

def _make_sln(name, project_entries):
    """Generate .sln file content."""
    lines = [
        "",
        "Microsoft Visual Studio Solution File, Format Version 12.00",
        "# Visual Studio Version 17",
        "VisualStudioVersion = 17.0.31903.59",
        "MinimumVisualStudioVersion = 10.0.40219.1",
    ]

    config_lines = []

    for entry in project_entries:
        lines.append(
            "Project(\"{%s}\") = \"%s\", \"%s\", \"{%s}\"" % (
                _CSHARP_PROJECT_TYPE_GUID,
                entry.name,
                entry.csproj_path.replace("/", "\\"),
                entry.guid,
            ),
        )
        lines.append("EndProject")

        config_lines.append("\t\t{%s}.Debug|Any CPU.ActiveCfg = Debug|Any CPU" % entry.guid)
        config_lines.append("\t\t{%s}.Debug|Any CPU.Build.0 = Debug|Any CPU" % entry.guid)
        config_lines.append("\t\t{%s}.Release|Any CPU.ActiveCfg = Release|Any CPU" % entry.guid)
        config_lines.append("\t\t{%s}.Release|Any CPU.Build.0 = Release|Any CPU" % entry.guid)

    lines.append("Global")
    lines.append("\tGlobalSection(SolutionConfigurationPlatforms) = preSolution")
    lines.append("\t\tDebug|Any CPU = Debug|Any CPU")
    lines.append("\t\tRelease|Any CPU = Release|Any CPU")
    lines.append("\tEndGlobalSection")
    lines.append("\tGlobalSection(ProjectConfigurationPlatforms) = postSolution")
    lines.extend(config_lines)
    lines.append("\tEndGlobalSection")
    lines.append("EndGlobal")
    lines.append("")

    return "\n".join(lines)

_DIRECTORY_BUILD_PROPS = """\
<Project>
  <PropertyGroup>
    <!-- Shared properties for Bazel-generated IDE projects -->
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <RestorePackagesWithLockFile>false</RestorePackagesWithLockFile>
    <ProduceReferenceAssembly>false</ProduceReferenceAssembly>
    <GenerateDocumentationFile>false</GenerateDocumentationFile>
  </PropertyGroup>
</Project>
"""

_DIRECTORY_BUILD_TARGETS = """\
<Project>
  <!-- Stub: building is done via Bazel, not MSBuild.
       This file prevents accidental 'dotnet build' from producing
       confusing output. VS IntelliSense and restore still work. -->
</Project>
"""

def _make_nuget_config(sources):
    """Generate NuGet.config with package sources."""
    lines = [
        "<?xml version=\"1.0\" encoding=\"utf-8\"?>",
        "<configuration>",
        "  <packageSources>",
        "    <clear />",
    ]
    for i, source in enumerate(sources):
        lines.append("    <add key=\"source%d\" value=\"%s\" />" % (i, source))
    lines.append("  </packageSources>")
    lines.append("</configuration>")
    lines.append("")
    return "\n".join(lines)

def _make_launch_settings(label):
    """Generate launchSettings.json for a binary target."""
    target_str = str(label)
    return """\
{{
  "profiles": {{
    "Bazel Run": {{
      "commandName": "Executable",
      "executablePath": "bazel",
      "commandLineArgs": "run {label}"
    }},
    "Attach to Process": {{
      "commandName": "Project",
      "launchBrowser": false
    }}
  }}
}}
""".format(label = target_str)

def _dotnet_solution_impl(ctx):
    """Generate .sln, .csproj files, and supporting IDE files."""
    sln_name = ctx.attr.name
    target_framework = ctx.attr.target_framework
    nuget_sources = ctx.attr.nuget_sources
    sln_package = ctx.label.package

    project_entries = []
    all_outputs = []
    copy_commands = []

    for project_target in ctx.attr.projects:
        ide_info = project_target[DotnetIdeInfo]
        if ide_info.is_nuget:
            continue

        proj_name = ide_info.name
        proj_package = ide_info.label.package
        guid = _label_to_guid(ide_info.label)

        # .csproj relative path from .sln location
        if proj_package:
            csproj_rel = proj_package + "/" + proj_name + ".csproj"
        else:
            csproj_rel = proj_name + ".csproj"

        project_entries.append(struct(
            name = proj_name,
            csproj_path = csproj_rel,
            guid = guid,
            ide_info = ide_info,
        ))

        # Generate .csproj file
        csproj_out = ctx.actions.declare_file(proj_name + ".csproj")
        csproj_content = _make_csproj(ide_info, target_framework, sln_package)
        ctx.actions.write(csproj_out, csproj_content)
        all_outputs.append(csproj_out)

        # Copy command: .csproj to its package directory
        if proj_package:
            copy_commands.append(
                "mkdir -p \"${WORKSPACE_ROOT}/%s\"\n" % proj_package +
                "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/%s\"" % (csproj_out.short_path, csproj_rel),
            )
        else:
            copy_commands.append(
                "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/%s\"" % (csproj_out.short_path, csproj_rel),
            )

        # Generate launchSettings.json for binary projects
        if ide_info.output_type == "Exe":
            launch_out = ctx.actions.declare_file(proj_name + ".launchSettings.json")
            ctx.actions.write(launch_out, _make_launch_settings(ide_info.label))
            all_outputs.append(launch_out)

            props_dir = proj_package + "/Properties" if proj_package else "Properties"
            copy_commands.append(
                "mkdir -p \"${WORKSPACE_ROOT}/%s\"\n" % props_dir +
                "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/%s/launchSettings.json\"" % (launch_out.short_path, props_dir),
            )

    # Generate .sln file
    sln_out = ctx.actions.declare_file(sln_name + ".sln")
    sln_content = _make_sln(sln_name, project_entries)
    ctx.actions.write(sln_out, sln_content)
    all_outputs.append(sln_out)

    if sln_package:
        sln_dest = sln_package + "/" + sln_name + ".sln"
    else:
        sln_dest = sln_name + ".sln"
    copy_commands.append(
        "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/%s\"" % (sln_out.short_path, sln_dest),
    )

    # Generate Directory.Build.props
    props_out = ctx.actions.declare_file("Directory.Build.props")
    ctx.actions.write(props_out, _DIRECTORY_BUILD_PROPS)
    all_outputs.append(props_out)
    copy_commands.append(
        "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/Directory.Build.props\"" % props_out.short_path,
    )

    # Generate Directory.Build.targets
    targets_out = ctx.actions.declare_file("Directory.Build.targets")
    ctx.actions.write(targets_out, _DIRECTORY_BUILD_TARGETS)
    all_outputs.append(targets_out)
    copy_commands.append(
        "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/Directory.Build.targets\"" % targets_out.short_path,
    )

    # Generate NuGet.config
    nuget_out = ctx.actions.declare_file("NuGet.config")
    ctx.actions.write(nuget_out, _make_nuget_config(nuget_sources))
    all_outputs.append(nuget_out)
    copy_commands.append(
        "cp \"$RUNFILES/%s\" \"${WORKSPACE_ROOT}/NuGet.config\"" % nuget_out.short_path,
    )

    # Generate copy script
    script_content = """\
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE_ROOT="${BUILD_WORKSPACE_DIRECTORY}"
RUNFILES="$0.runfiles/%s"

%s

echo "Generated VS solution: ${WORKSPACE_ROOT}/%s"
echo "  %d project(s), Directory.Build.props, NuGet.config"
echo ""
echo "Next steps:"
echo "  1. Open %s in Visual Studio"
echo "  2. VS will run 'dotnet restore' automatically"
echo "  3. Build with Bazel, not VS: bazel build //..."
""" % (
        ctx.workspace_name,
        "\n".join(copy_commands),
        sln_dest,
        len(project_entries),
        sln_name + ".sln",
    )

    copy_script = ctx.actions.declare_file(sln_name + "_generate.sh")
    ctx.actions.write(copy_script, script_content, is_executable = True)

    runfiles = ctx.runfiles(files = all_outputs)

    return [
        DefaultInfo(
            files = depset(all_outputs),
            executable = copy_script,
            runfiles = runfiles,
        ),
    ]

_dotnet_solution = rule(
    implementation = _dotnet_solution_impl,
    doc = """Generate a Visual Studio .sln file with .csproj files and supporting IDE files.

Run with `bazel run` to write all generated files into the source tree.
Visual Studio, Rider, or any MSBuild-compatible IDE can then open the .sln.

Generated files:
- {name}.sln — solution file with all projects
- Per-project .csproj — complete with PackageReference, ProjectReference, Analyzer entries
- Directory.Build.props — shared properties (disable assembly info gen, etc.)
- Directory.Build.targets — stub to prevent accidental dotnet build
- NuGet.config — package source configuration for dotnet restore
- Properties/launchSettings.json — for binary projects (debugger profiles)
""",
    attrs = {
        "projects": attr.label_list(
            doc = "List of csharp_binary / csharp_library targets to include in the solution.",
            mandatory = True,
            allow_empty = False,
            providers = [DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo],
            aspects = [ide_info_aspect],
            cfg = tfm_transition,
        ),
        "target_framework": attr.string(
            doc = "The target framework moniker (e.g., net8.0).",
            mandatory = True,
        ),
        "nuget_sources": attr.string_list(
            doc = "NuGet package source URLs for NuGet.config.",
            default = ["https://api.nuget.org/v3/index.json"],
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    executable = True,
)

def dotnet_solution(name, projects, target_framework, **kwargs):
    """Macro that generates a VS solution for IDE support.

    Usage:
        dotnet_solution(
            name = "MySolution",
            projects = [":mylib", ":myapp"],
            target_framework = "net8.0",
        )

    Then run: bazel run //:MySolution
    This generates MySolution.sln, .csproj files, and supporting IDE files.

    Args:
        name: Name of the solution.
        projects: List of csharp_binary / csharp_library labels.
        target_framework: Target framework moniker (e.g., "net8.0").
        **kwargs: Additional attributes passed to the underlying rule.
    """
    _dotnet_solution(
        name = name,
        projects = projects,
        target_framework = target_framework,
        **kwargs
    )

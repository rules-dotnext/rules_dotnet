"""Rule for generating .csproj files for IDE support (OmniSharp, Rider, etc.).

Generates a .csproj file that IDE language servers can consume for IntelliSense,
go-to-definition, and code navigation, while keeping Bazel as the build system.

See https://github.com/bazel-contrib/rules_dotnet/issues/228
"""

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

def _dotnet_project_impl(ctx):
    """Generate a .csproj file from rule attributes for IDE consumption."""

    # Build compile items from srcs
    src_items = []
    for src in ctx.files.srcs:
        src_items.append("    <Compile Include=\"%s\" />" % src.short_path)

    compile_items = "\n".join(src_items) if src_items else ""

    # Determine assembly name
    assembly_name = ctx.attr.csproj_name if ctx.attr.csproj_name else ctx.attr.name.replace(".project", "")

    # Substitute template values
    csproj_content = _CSPROJ_TEMPLATE.format(
        project_sdk = ctx.attr.project_sdk,
        target_framework = ctx.attr.target_framework,
        root_namespace = ctx.attr.root_namespace if ctx.attr.root_namespace else assembly_name,
        assembly_name = assembly_name,
        langversion = ctx.attr.langversion if ctx.attr.langversion else "default",
        nullable = ctx.attr.nullable,
        allow_unsafe_blocks = "true" if ctx.attr.allow_unsafe_blocks else "false",
        output_type = ctx.attr.output_type,
        compile_items = compile_items,
    )

    output = ctx.actions.declare_file(ctx.attr.name + ".csproj")
    ctx.actions.write(output, csproj_content)

    # Generate a script that copies the .csproj to the workspace
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
where OmniSharp/Rider can discover it.
""",
    attrs = {
        "target": attr.label(
            doc = "The csharp_binary or csharp_library target this project corresponds to.",
            mandatory = True,
        ),
        "srcs": attr.label_list(
            doc = "Source files to include in the .csproj. Should match the srcs of the target.",
            allow_files = [".cs"],
        ),
        "target_framework": attr.string(
            doc = "The target framework moniker (e.g., net8.0).",
            mandatory = True,
        ),
        "project_sdk": attr.string(
            doc = "The .NET project SDK.",
            default = "Microsoft.NET.Sdk",
        ),
        "output_type": attr.string(
            doc = "The output type (Exe or Library).",
            default = "Library",
            values = ["Exe", "Library"],
        ),
        "root_namespace": attr.string(
            doc = "The root namespace. Defaults to the assembly name.",
        ),
        "langversion": attr.string(
            doc = "The C# language version.",
        ),
        "nullable": attr.string(
            doc = "Nullable context.",
            default = "disable",
        ),
        "allow_unsafe_blocks": attr.bool(
            doc = "Whether to allow unsafe blocks.",
            default = False,
        ),
        "csproj_name": attr.string(
            doc = "Override the generated .csproj file name.",
        ),
    },
    executable = True,
)

def dotnet_project(name, target, srcs, target_framework, **kwargs):
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
            srcs = ["Foo.cs"],
            target_framework = "net8.0",
        )

    Then run: bazel run //path:mylib.project
    This generates path/mylib.csproj that OmniSharp can consume.

    Args:
        name: Name of the target. Convention: "{library_name}.project"
        target: The csharp_binary or csharp_library label.
        srcs: Source files (should match the target's srcs).
        target_framework: Target framework moniker (e.g., "net8.0").
        **kwargs: Additional attributes passed to the underlying rule.
    """
    _dotnet_project(
        name = name,
        target = target,
        srcs = srcs,
        target_framework = target_framework,
        **kwargs
    )

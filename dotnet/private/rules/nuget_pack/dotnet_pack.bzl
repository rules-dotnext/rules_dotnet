"""
Rule for creating NuGet packages (.nupkg) from .NET libraries.
"""

load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyCompileInfo",
    "DotnetAssemblyRuntimeInfo",
    "NuGetInfo",
)
load("//dotnet/private/transitions:tfm_transition.bzl", "tfm_transition")

_NUSPEC_TEMPLATE = """\
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.nuget.org/2010/07/nuspec.xsd">
  <metadata>
    <id>{package_id}</id>
    <version>{version}</version>
    <authors>{authors}</authors>
    <description>{description}</description>
    <license type="expression">{license}</license>
    <projectUrl>{project_url}</projectUrl>
    <repository type="git" url="{repository_url}" />
    <requireLicenseAcceptance>{require_license_acceptance}</requireLicenseAcceptance>
{dependency_groups}
  </metadata>
</package>
"""

_DEPENDENCY_GROUP_TEMPLATE = """\
    <group targetFramework="{tfm}">
{dependencies}
    </group>"""

_DEPENDENCY_TEMPLATE = """\
      <dependency id="{id}" version="{version}" />"""

def _generate_nuspec(ctx, assembly_runtime_info, target_framework):
    """Generate a .nuspec XML file."""
    package_id = ctx.attr.package_id if ctx.attr.package_id else assembly_runtime_info.name
    version = ctx.attr.package_version

    # Collect NuGet dependencies from direct deps
    dep_lines = []
    for dep in assembly_runtime_info.deps.to_list():
        dep_runtime = dep.assembly_runtime_info
        if dep.nuget_info and dep.nuget_info.nupkg:
            dep_lines.append(_DEPENDENCY_TEMPLATE.format(
                id = dep_runtime.name,
                version = dep_runtime.version,
            ))

    dependency_groups = ""
    if dep_lines:
        # Map target_framework to NuGet TFM format
        nuget_tfm = _to_nuget_tfm(target_framework)
        dependency_groups = "    <dependencies>\n" + _DEPENDENCY_GROUP_TEMPLATE.format(
            tfm = nuget_tfm,
            dependencies = "\n".join(dep_lines),
        ) + "\n    </dependencies>"

    nuspec_content = _NUSPEC_TEMPLATE.format(
        package_id = package_id,
        version = version,
        authors = ctx.attr.authors,
        description = ctx.attr.description,
        license = ctx.attr.license_expression,
        project_url = ctx.attr.project_url,
        repository_url = ctx.attr.repository_url,
        require_license_acceptance = "true" if ctx.attr.require_license_acceptance else "false",
        dependency_groups = dependency_groups,
    )

    nuspec = ctx.actions.declare_file("{}/{}.nuspec".format(ctx.label.name, package_id))
    ctx.actions.write(output = nuspec, content = nuspec_content)
    return (nuspec, package_id)

def _to_nuget_tfm(tfm):
    """Convert internal TFM to NuGet framework string.

    e.g. 'net8.0' -> '.NETCoreApp,Version=v8.0'
    """
    if tfm.startswith("net") and "." in tfm:
        version = tfm[3:]  # e.g. "8.0"
        return ".NETCoreApp,Version=v" + version
    if tfm.startswith("netstandard"):
        version = tfm[len("netstandard"):]
        return ".NETStandard,Version=v" + version
    return tfm

def _dotnet_pack_impl(ctx):
    assembly_runtime_info = ctx.attr.library[0][DotnetAssemblyRuntimeInfo]
    assembly_compile_info = ctx.attr.library[0][DotnetAssemblyCompileInfo]
    target_framework = ctx.attr.target_framework

    (nuspec, package_id) = _generate_nuspec(
        ctx,
        assembly_runtime_info,
        target_framework,
    )

    # Determine the nupkg filename
    nupkg_name = "{}.{}.nupkg".format(package_id, ctx.attr.package_version)
    nupkg = ctx.actions.declare_file("{}/{}".format(ctx.label.name, nupkg_name))

    # Build the file list for the packer
    file_args = []
    inputs = [nuspec]

    for lib in assembly_runtime_info.libs:
        rel_path = "lib/{}/{}".format(target_framework, lib.basename)
        file_args.append("{}={}".format(rel_path, lib.path))
        inputs.append(lib)

    for xml_doc in assembly_runtime_info.xml_docs:
        rel_path = "lib/{}/{}".format(target_framework, xml_doc.basename)
        file_args.append("{}={}".format(rel_path, xml_doc.path))
        inputs.append(xml_doc)

    # Optionally include reference assemblies under ref/{tfm}/
    if ctx.attr.include_ref_assemblies:
        for ref in assembly_compile_info.refs:
            rel_path = "ref/{}/{}".format(target_framework, ref.basename)
            file_args.append("{}={}".format(rel_path, ref.path))
            inputs.append(ref)

    # Optionally include PDBs
    if ctx.attr.include_symbols:
        for pdb in assembly_runtime_info.pdbs:
            rel_path = "lib/{}/{}".format(target_framework, pdb.basename)
            file_args.append("{}={}".format(rel_path, pdb.path))
            inputs.append(pdb)

    # Additional content files
    for content_file in ctx.files.content_files:
        rel_path = "contentFiles/any/{}/{}".format(target_framework, content_file.basename)
        file_args.append("{}={}".format(rel_path, content_file.path))
        inputs.append(content_file)

    nuspec_rel = "{}.nuspec".format(package_id)

    args = ctx.actions.args()
    args.add("--output", nupkg)
    args.add("--nuspec", nuspec)
    args.add("--nuspec-path-in-pkg", nuspec_rel)
    args.add_all(file_args, format_each = "--files=%s")

    ctx.actions.run(
        executable = ctx.executable._packer,
        arguments = [args],
        inputs = inputs,
        outputs = [nupkg],
        mnemonic = "DotnetPack",
        progress_message = "Packing NuGet package %{label}",
        toolchain = None,
    )

    return [
        DefaultInfo(
            files = depset([nupkg]),
        ),
        NuGetInfo(
            targeting_pack_overrides = {},
            framework_list = {},
            sha512 = "",
            nupkg = nupkg,
        ),
    ]

dotnet_pack = rule(
    _dotnet_pack_impl,
    doc = """Create a NuGet package (.nupkg) from a .NET library.

    Equivalent to `dotnet pack`. Generates a .nuspec and assembles the
    package with the correct lib/{tfm}/ layout.
    """,
    attrs = {
        "library": attr.label(
            doc = "The csharp_library or fsharp_library target to pack",
            providers = [DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo],
            cfg = tfm_transition,
            mandatory = True,
        ),
        "target_framework": attr.string(
            doc = "The target framework (e.g. net8.0)",
        ),
        "package_id": attr.string(
            doc = "NuGet package ID. Defaults to the assembly name.",
        ),
        "package_version": attr.string(
            doc = "Package version (SemVer)",
            mandatory = True,
        ),
        "authors": attr.string(
            doc = "Package authors",
            default = "",
        ),
        "description": attr.string(
            doc = "Package description",
            default = "",
        ),
        "license_expression": attr.string(
            doc = "SPDX license expression (e.g. 'MIT', 'Apache-2.0')",
            default = "MIT",
        ),
        "project_url": attr.string(
            doc = "Project URL",
            default = "",
        ),
        "repository_url": attr.string(
            doc = "Source repository URL",
            default = "",
        ),
        "require_license_acceptance": attr.bool(
            doc = "Whether the package requires license acceptance",
            default = False,
        ),
        "include_ref_assemblies": attr.bool(
            doc = "Include reference assemblies under ref/{tfm}/ in the package",
            default = False,
        ),
        "include_symbols": attr.bool(
            doc = "Include PDB files in the package",
            default = False,
        ),
        "content_files": attr.label_list(
            doc = "Additional content files to include in the package",
            allow_files = True,
        ),
        "_packer": attr.label(
            default = "//dotnet/private/tools/nuget_packer:pack",
            executable = True,
            cfg = "exec",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
    },
    toolchains = ["//dotnet:toolchain_type"],
)

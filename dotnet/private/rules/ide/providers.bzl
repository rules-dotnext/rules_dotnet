"IDE integration providers"

DotnetIdeInfo = provider(
    doc = "IDE metadata collected by ide_info_aspect for .csproj/.sln generation.",
    fields = {
        "label": "Label: The target's label",
        "name": "string: Assembly name",
        "is_nuget": "bool: True if this is a NuGet package, False if a project",
        "nuget_id": "string or None: NuGet package ID (from DotnetAssemblyRuntimeInfo.name when is_nuget)",
        "nuget_version": "string or None: NuGet package version (from DotnetAssemblyRuntimeInfo.version when is_nuget)",
        "srcs": "list[File]: Source files (empty for NuGet deps)",
        "target_framework": "string: Target framework moniker (empty for NuGet deps)",
        "langversion": "string: C# language version",
        "nullable": "string: Nullable context setting",
        "allow_unsafe_blocks": "bool: Whether unsafe blocks are allowed",
        "output_type": "string: Exe or Library",
        "project_sdk": "string: .NET project SDK",
        "analyzers": "list[File]: Analyzer DLLs",
        "direct_project_deps": "list[DotnetIdeInfo]: Non-NuGet direct deps",
        "direct_nuget_deps": "list[struct(id, version)]: NuGet direct deps, deduplicated",
    },
)

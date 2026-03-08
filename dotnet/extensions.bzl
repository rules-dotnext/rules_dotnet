"extensions for bzlmod"

load(
    "//dotnet/private/rules/nuget:nuget_lock.bzl",
    "parse_nuget_lock_file",
)
load(
    "//dotnet/private/rules/nuget:nuget_repo.bzl",
    "nuget_repo",
)
load(":repositories.bzl", "dotnet_register_toolchains")

_DEFAULT_NAME = "dotnet"

_ATTRS = {
    "name": attr.string(
        doc = "Base name for generated repositories",
        default = _DEFAULT_NAME,
    ),
    "dotnet_version": attr.string(
        doc = "Version of the .Net SDK",
    ),
}

def _toolchain_extension(module_ctx):
    registrations = {}

    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            if toolchain.name in registrations.keys():
                if toolchain.name == _DEFAULT_NAME:
                    # Prioritize the root-most registration of the default dotnet toolchain version and
                    # ignore any further registrations (modules are processed breadth-first)
                    continue
                if toolchain.dotnet_version == registrations[toolchain.name]:
                    # No problem to register a matching toolchain twice
                    continue
                fail("Multiple conflicting toolchains declared for name {} ({} and {})".format(
                    toolchain.name,
                    toolchain.dotnet_version,
                    registrations[toolchain.name],
                ))
            else:
                registrations[toolchain.name] = toolchain.dotnet_version

    for name, dotnet_version in registrations.items():
        dotnet_register_toolchains(
            name = name,
            dotnet_version = dotnet_version,
            register = False,
        )


dotnet = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {
        "toolchain": tag_class(attrs = _ATTRS),
    },
)

# NuGet module extension

_FROM_LOCK_ATTRS = {
    "name": attr.string(
        doc = "Name for the generated nuget hub repository",
        mandatory = True,
    ),
    "lock_file": attr.label(
        doc = "Label of a packages.lock.json file (standard NuGet lock file, optionally augmented with nupkgSha512 fields by nuget2bazel)",
        mandatory = True,
    ),
    "sources": attr.string_list(
        doc = "NuGet package source URLs (e.g. https://api.nuget.org/v3/index.json)",
        default = ["https://api.nuget.org/v3/index.json"],
    ),
    "netrc": attr.label(
        doc = "Label of a netrc file for authenticating to package sources",
        mandatory = False,
    ),
}

_PACKAGE_ATTRS = {
    "name": attr.string(
        doc = "Name for the generated nuget hub repository this package belongs to",
        mandatory = True,
    ),
    "id": attr.string(
        doc = "NuGet package ID",
        mandatory = True,
    ),
    "version": attr.string(
        doc = "Exact package version",
        mandatory = True,
    ),
    "sha512": attr.string(
        doc = "SRI-format SHA-512 hash of the .nupkg file (e.g. sha512-...)",
        mandatory = True,
    ),
    "sources": attr.string_list(
        doc = "NuGet package source URLs",
        default = ["https://api.nuget.org/v3/index.json"],
    ),
    "tfms": attr.string_list(
        doc = "Target frameworks this package supports",
        default = [],
    ),
    "deps": attr.string_list_dict(
        doc = "Per-TFM dependency lists: {tfm: [dep_id, ...]}",
        default = {},
    ),
    "targeting_pack_overrides": attr.string_list(
        doc = "PackageOverride entries from targeting packs",
        default = [],
    ),
    "framework_list": attr.string_list(
        doc = "FrameworkList entries from targeting packs",
        default = [],
    ),
    "netrc": attr.label(
        doc = "Label of a netrc file for authentication",
        mandatory = False,
    ),
}

def _nuget_deps_extension(module_ctx):
    """Module extension that creates NuGet package repositories.

    Supports two tag types:
    - from_lock: reads a packages.lock.json file
    - package: declares an individual NuGet package
    """

    # Collect all packages grouped by hub repo name.
    # Key: repo name, Value: list of package dicts
    repos = {}

    for mod in module_ctx.modules:
        # Process from_lock tags
        for lock_tag in mod.tags.from_lock:
            repo_name = lock_tag.name
            lock_content = module_ctx.read(lock_tag.lock_file)
            packages = parse_nuget_lock_file(
                lock_content,
                lock_tag.sources,
                netrc = getattr(lock_tag, "netrc", None),
            )
            if repo_name not in repos:
                repos[repo_name] = []
            repos[repo_name].extend(packages)

        # Process individual package tags
        for pkg_tag in mod.tags.package:
            repo_name = pkg_tag.name
            deps = {}
            for tfm in pkg_tag.tfms:
                deps[tfm] = pkg_tag.deps.get(tfm, [])

            package = {
                "name": pkg_tag.id,
                "id": pkg_tag.id,
                "version": pkg_tag.version,
                "sha512": pkg_tag.sha512,
                "sources": pkg_tag.sources,
                "dependencies": deps,
                "targeting_pack_overrides": pkg_tag.targeting_pack_overrides,
                "framework_list": pkg_tag.framework_list,
                "tools": {},
            }
            if getattr(pkg_tag, "netrc", None):
                package["netrc"] = pkg_tag.netrc
            if repo_name not in repos:
                repos[repo_name] = []
            repos[repo_name].append(package)

    # Create nuget_repo for each hub
    for repo_name, packages in repos.items():
        nuget_repo(
            name = repo_name,
            packages = packages,
        )

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
    )

nuget = module_extension(
    implementation = _nuget_deps_extension,
    tag_classes = {
        "from_lock": tag_class(attrs = _FROM_LOCK_ATTRS),
        "package": tag_class(attrs = _PACKAGE_ATTRS),
    },
)

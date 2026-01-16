"""Parser for NuGet packages.lock.json files.

Provides a pure-Starlark parser that converts the standard NuGet lock file format
into the package dict list expected by nuget_repo().
"""

def parse_nuget_lock_file(lock_file_content, sources, netrc = None):
    """Parses a NuGet packages.lock.json and returns a list of package dicts.

    The returned list is compatible with the `packages` parameter of `nuget_repo()`.

    The NuGet lock file organizes dependencies per target framework (TFM). This
    parser merges packages across TFMs, collecting per-TFM dependency lists for
    each unique package.

    IMPORTANT: The `contentHash` in NuGet lock files is NOT the .nupkg file hash.
    It is a hash of the package content. To use Bazel's integrity checking, the
    lock file must be augmented with `nupkgSha512` fields (added by a helper tool
    like nuget2bazel). When `nupkgSha512` is absent, downloads proceed without
    integrity verification.

    Args:
        lock_file_content: string, the raw JSON content of packages.lock.json
        sources: list of string, NuGet package source URLs
        netrc: optional string, path to a netrc file for authentication

    Returns:
        list of dicts, each with keys compatible with nuget_repo() packages parameter:
        name, id, version, sha512, sources, dependencies, targeting_pack_overrides,
        framework_list, tools
    """
    lock = json.decode(lock_file_content)

    version = lock.get("version", 0)
    if version != 1 and version != 2:
        fail("Unsupported packages.lock.json version: %s. Expected 1 or 2." % version)

    # Collect all unique packages across all TFMs.
    # Key: "id_lower|version", Value: package dict being built
    packages_by_key = {}

    tfm_sections = lock.get("dependencies", {})

    for tfm, packages in tfm_sections.items():
        for package_id, info in packages.items():
            version = info["resolved"]
            key = "%s|%s" % (package_id.lower(), version)

            if key not in packages_by_key:
                # The nupkgSha512 field is added by the nuget2bazel augmentation
                # tool. The contentHash from NuGet is NOT usable for Bazel's
                # integrity checking.
                sha512 = info.get("nupkgSha512", "")

                packages_by_key[key] = {
                    "name": package_id,
                    "id": package_id,
                    "version": version,
                    "sha512": sha512,
                    "sources": sources,
                    "dependencies": {},
                    "targeting_pack_overrides": [],
                    "framework_list": [],
                    "tools": {},
                }
                if netrc:
                    packages_by_key[key]["netrc"] = netrc

            # Add deps for this TFM
            pkg = packages_by_key[key]
            tfm_deps = []
            for dep_id in info.get("dependencies", {}).keys():
                tfm_deps.append(dep_id)
            pkg["dependencies"][tfm] = tfm_deps

    # Warn about missing hashes
    missing_hashes = []
    for key in sorted(packages_by_key.keys()):
        pkg = packages_by_key[key]
        if not pkg["sha512"]:
            missing_hashes.append("%s@%s" % (pkg["id"], pkg["version"]))

    if missing_hashes:
        # buildifier: disable=print
        print(
            "WARNING: The following packages in the lock file are missing " +
            "nupkgSha512 hashes. Downloads will proceed without integrity " +
            "verification. Run nuget2bazel to augment your lock file:\n  " +
            "\n  ".join(missing_hashes),
        )

    return packages_by_key.values()

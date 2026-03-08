"""Shared utilities for proto/gRPC rule implementations."""

load(
    "//dotnet/private:providers.bzl",
    "DotnetAssemblyCompileInfo",
    "DotnetAssemblyRuntimeInfo",
)

def empty_providers(name):
    """Return empty providers when there are no sources to compile.

    Proto libraries may have zero direct sources (e.g. a proto_library that
    only re-exports other protos). In that case the rule still needs to return
    valid providers so downstream consumers can depend on it uniformly.

    Args:
        name: Assembly name for the empty providers.

    Returns:
        A list of [DotnetAssemblyCompileInfo, DotnetAssemblyRuntimeInfo, DefaultInfo].
    """
    return [
        DotnetAssemblyCompileInfo(
            name = name,
            version = "1.0.0",
            project_sdk = "default",
            refs = [],
            irefs = [],
            analyzers = [],
            analyzers_csharp = [],
            analyzers_fsharp = [],
            analyzers_vb = [],
            internals_visible_to = [],
            compile_data = [],
            exports = [],
            transitive_refs = depset(),
            transitive_analyzers = depset(),
            transitive_analyzers_csharp = depset(),
            transitive_analyzers_fsharp = depset(),
            transitive_analyzers_vb = depset(),
            transitive_compile_data = depset(),
            content_srcs = [],
            transitive_content_srcs = depset(),
        ),
        DotnetAssemblyRuntimeInfo(
            name = name,
            version = "1.0.0",
            libs = [],
            pdbs = [],
            xml_docs = [],
            native = [],
            data = [],
            resource_assemblies = [],
            appsetting_files = depset(),
            nuget_info = None,
            deps = depset(),
            direct_deps_depsjson_fragment = {},
        ),
        DefaultInfo(files = depset()),
    ]

"""Stub macros for rules that don't exist yet in upstream rules_dotnet.

Each stub creates a genrule that fails with a clear message telling the agent
which spec must be implemented to make the target real.

When an agent implements a spec, they:
1. Add the real rule to @rules_dotnet//dotnet:defs.bzl
2. Move the load() in BUILD.bazel from :stubs.bzl to @rules_dotnet//dotnet:defs.bzl
3. The stub is no longer called; the real rule validates attributes.
"""

def _make_stub(rule_name, spec_name, issue):
    """Returns a stub macro that creates a failing genrule."""
    def _stub(name, **kwargs):  # buildifier: disable=unused-variable
        native.genrule(
            name = name,
            outs = [name + ".stub"],
            cmd = "echo 'ERROR: {rule} is not yet implemented. See {spec} (#{issue}).' && exit 1".format(
                rule = rule_name,
                spec = spec_name,
                issue = issue,
            ),
            visibility = kwargs.get("visibility"),
            tags = kwargs.get("tags", []) + ["manual"],
            testonly = kwargs.get("testonly", False),
        )

    return _stub

# spec-publishing
publish_binary = _make_stub("publish_binary", "spec-publishing", "358")
publish_library = _make_stub("publish_library", "spec-publishing", "391")
native_aot_binary = _make_stub("native_aot_binary", "spec-publishing", "484")
dotnet_pack = _make_stub("dotnet_pack", "spec-publishing", "527")

# spec-proto-grpc
csharp_proto_library = _make_stub("csharp_proto_library", "spec-proto-grpc", "proto")
csharp_grpc_library = _make_stub("csharp_grpc_library", "spec-proto-grpc", "grpc")

# spec-razor-blazor
razor_library = _make_stub("razor_library", "spec-razor-blazor", "249")

# spec-static-analysis
dotnet_analysis_config = _make_stub("dotnet_analysis_config", "spec-static-analysis", "analysis")

# spec-ide-integration
dotnet_project = _make_stub("dotnet_project", "spec-ide-integration", "228")

# spec-platform-features
resx_resource = _make_stub("resx_resource", "spec-platform-features", "466")

"extensions for bzlmod"

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

# spec-static-analysis: analysis tag class for global analyzer config
_ANALYSIS_ATTRS = {
    "config": attr.string(
        doc = "Label of a dotnet_analysis_config target to apply globally. " +
              "Set via .bazelrc: build --@rules_dotnet//dotnet/private/rules/analysis:analysis_config=<label>",
        mandatory = True,
    ),
}

def _analysis_config_repo_impl(ctx):
    """Repository rule that stores the analysis config label for documentation purposes."""
    ctx.file("BUILD.bazel", "")
    ctx.file("defs.bzl", 'ANALYSIS_CONFIG = "%s"\n' % ctx.attr.config)

_analysis_config_repo = repository_rule(
    implementation = _analysis_config_repo_impl,
    attrs = {
        "config": attr.string(mandatory = True),
    },
)

def _toolchain_extension(module_ctx):
    registrations = {}
    analysis_config = None

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

        # spec-static-analysis: collect analysis config
        for analysis in mod.tags.analysis:
            if analysis_config != None:
                fail("Multiple dotnet.analysis() declarations found. Only one is allowed.")
            analysis_config = analysis.config

    for name, dotnet_version in registrations.items():
        dotnet_register_toolchains(
            name = name,
            dotnet_version = dotnet_version,
            register = False,
        )

    if analysis_config:
        _analysis_config_repo(
            name = "dotnet_analysis_config",
            config = analysis_config,
        )

dotnet = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {
        "toolchain": tag_class(attrs = _ATTRS),
        # spec-static-analysis: global analysis configuration
        "analysis": tag_class(attrs = _ANALYSIS_ATTRS),
    },
)

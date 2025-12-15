"Rule for defining workspace-wide Roslyn analyzer configuration."

load(
    "//dotnet/private/rules/analysis:providers.bzl",
    "DotnetAnalysisConfigInfo",
)

def _dotnet_analysis_config_impl(ctx):
    # Validate mutual exclusivity
    if ctx.attr.treat_warnings_as_errors and len(ctx.attr.warnings_as_errors) > 0:
        fail("Cannot use both treat_warnings_as_errors and warnings_as_errors in dotnet_analysis_config")

    if not ctx.attr.treat_warnings_as_errors and len(ctx.attr.warnings_not_as_errors) > 0:
        fail("Cannot use warnings_not_as_errors without treat_warnings_as_errors in dotnet_analysis_config")

    # Collect all analyzer DLL files from the provided targets
    analyzer_file_sets = [dep[DefaultInfo].files for dep in ctx.attr.analyzers]
    analyzer_files = depset(transitive = analyzer_file_sets) if analyzer_file_sets else depset()

    return [
        DotnetAnalysisConfigInfo(
            analyzer_files = analyzer_files,
            global_configs = ctx.files.global_configs,
            treat_warnings_as_errors = ctx.attr.treat_warnings_as_errors,
            warnings_as_errors = ctx.attr.warnings_as_errors,
            warnings_not_as_errors = ctx.attr.warnings_not_as_errors,
            suppressed_diagnostics = ctx.attr.suppressed_diagnostics,
            warning_level = ctx.attr.warning_level,
        ),
    ]

dotnet_analysis_config = rule(
    implementation = _dotnet_analysis_config_impl,
    doc = """Defines a workspace-wide Roslyn analyzer configuration.

    Register this globally via the label flag in .bazelrc:
    build --@rules_dotnet//dotnet/private/rules/analysis:analysis_config=//:analysis

    Per-target attributes always take precedence over this global config.

    Analyzers should be NuGet packages or csharp_library targets with
    is_analyzer=True. Their files are collected via DefaultInfo and passed
    as additional /analyzer: flags to all C# compilations.
    """,
    attrs = {
        "analyzers": attr.label_list(
            doc = "Analyzer targets (NuGet packages or csharp_library with is_analyzer=True) to apply to all compilations.",
            default = [],
        ),
        "global_configs": attr.label_list(
            doc = "List of .globalconfig or .editorconfig files to apply to all compilations via /analyzerconfig:.",
            allow_files = [".globalconfig", ".editorconfig"],
            default = [],
        ),
        "treat_warnings_as_errors": attr.bool(
            doc = "Treat all analyzer warnings as errors globally. Per-target treat_warnings_as_errors overrides this.",
            default = False,
        ),
        "warnings_as_errors": attr.string_list(
            doc = "Specific diagnostic IDs to treat as errors (e.g. ['CA1000', 'SA1200']). Cannot be combined with treat_warnings_as_errors.",
            default = [],
        ),
        "warnings_not_as_errors": attr.string_list(
            doc = "Specific diagnostic IDs to exempt from warnaserror. Only valid when treat_warnings_as_errors is True.",
            default = [],
        ),
        "suppressed_diagnostics": attr.string_list(
            doc = "Diagnostic IDs to suppress entirely via /nowarn: (e.g. ['SA1633']).",
            default = [],
        ),
        "warning_level": attr.int(
            doc = "Warning level (0-5). Set to -1 to leave unset (use per-target default). Level 5 enables all .NET 5+ analyzers.",
            default = -1,
            values = [-1, 0, 1, 2, 3, 4, 5],
        ),
    },
)

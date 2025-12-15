"Helper for resolving analysis config with per-target overrides."

load(
    "//dotnet/private/rules/analysis:providers.bzl",
    "DotnetAnalysisConfigInfo",
)

def resolve_analysis_config(ctx):
    """Resolve the effective analysis configuration for a target.

    Merges global analysis config with per-target attributes.
    Per-target attributes take precedence when explicitly set.

    Args:
        ctx: The rule context. Must have _analysis_config attribute.

    Returns:
        A struct with fields:
            extra_analyzer_files: depset[File] - additional analyzer DLLs from global config
            extra_global_configs: list[File] - .globalconfig files from global config
            effective_treat_warnings_as_errors: bool
            effective_warnings_as_errors: list[string]
            effective_warnings_not_as_errors: list[string]
            effective_nowarn: list[string]
            effective_warning_level: int
    """
    analysis_config = None
    if hasattr(ctx.attr, "_analysis_config") and ctx.attr._analysis_config:
        if DotnetAnalysisConfigInfo in ctx.attr._analysis_config:
            analysis_config = ctx.attr._analysis_config[DotnetAnalysisConfigInfo]

    if analysis_config == None:
        # No global config; return per-target values as-is
        return struct(
            extra_analyzer_files = depset(),
            extra_global_configs = [],
            effective_treat_warnings_as_errors = ctx.attr.treat_warnings_as_errors,
            effective_warnings_as_errors = ctx.attr.warnings_as_errors,
            effective_warnings_not_as_errors = ctx.attr.warnings_not_as_errors,
            effective_nowarn = ctx.attr.nowarn,
            effective_warning_level = ctx.attr.warning_level,
        )

    # Per-target treat_warnings_as_errors: if the target explicitly sets it to True,
    # that wins. If the target leaves it at default (False) and the global config
    # sets it, use global. We cannot distinguish "explicitly set to False" from
    # "left at default" in Starlark, so we treat False as "not set" for merging.
    effective_twe = ctx.attr.treat_warnings_as_errors or analysis_config.treat_warnings_as_errors

    # warnings_as_errors: merge (union) per-target and global
    effective_wae = _unique_list(ctx.attr.warnings_as_errors + analysis_config.warnings_as_errors)

    # warnings_not_as_errors: merge (union) per-target and global
    effective_wnae = _unique_list(ctx.attr.warnings_not_as_errors + analysis_config.warnings_not_as_errors)

    # nowarn: merge per-target and global suppressed_diagnostics
    effective_nowarn = _unique_list(ctx.attr.nowarn + analysis_config.suppressed_diagnostics)

    # warning_level: per-target wins if non-default (3 is default in attrs.bzl)
    effective_wl = ctx.attr.warning_level
    if effective_wl == 3 and analysis_config.warning_level != -1:
        effective_wl = analysis_config.warning_level

    return struct(
        extra_analyzer_files = analysis_config.analyzer_files,
        extra_global_configs = analysis_config.global_configs,
        effective_treat_warnings_as_errors = effective_twe,
        effective_warnings_as_errors = effective_wae,
        effective_warnings_not_as_errors = effective_wnae,
        effective_nowarn = effective_nowarn,
        effective_warning_level = effective_wl,
    )

def _unique_list(items):
    """Deduplicate a list while preserving order."""
    seen = {}
    result = []
    for item in items:
        if item not in seen:
            seen[item] = True
            result.append(item)
    return result

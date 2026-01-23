"dotnet_analysis_config analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "dotnet_analysis_config")
load(
    "//dotnet/private/rules/analysis:providers.bzl",
    "DotnetAnalysisConfigInfo",
)

def _analysis_config_provider_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    asserts.true(
        env,
        DotnetAnalysisConfigInfo in target,
        "Expected target to provide DotnetAnalysisConfigInfo",
    )

    info = target[DotnetAnalysisConfigInfo]
    asserts.true(
        env,
        info.treat_warnings_as_errors,
        "Expected treat_warnings_as_errors to be True",
    )

    return analysistest.end(env)

analysis_config_provider_test = analysistest.make(
    _analysis_config_provider_test_impl,
)

def _analysis_config_warnings_as_errors_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    info = target[DotnetAnalysisConfigInfo]

    asserts.equals(
        env,
        ["CA1000", "SA1200"],
        info.warnings_as_errors,
    )
    asserts.false(
        env,
        info.treat_warnings_as_errors,
        "Expected treat_warnings_as_errors to be False when using specific warnings_as_errors",
    )

    return analysistest.end(env)

analysis_config_warnings_as_errors_test = analysistest.make(
    _analysis_config_warnings_as_errors_test_impl,
)

def _analysis_config_warning_level_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    info = target[DotnetAnalysisConfigInfo]

    asserts.equals(
        env,
        5,
        info.warning_level,
    )

    return analysistest.end(env)

analysis_config_warning_level_test = analysistest.make(
    _analysis_config_warning_level_test_impl,
)

def _analysis_config_suppressed_diagnostics_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    info = target[DotnetAnalysisConfigInfo]

    asserts.equals(
        env,
        ["SA1633", "SA1600"],
        info.suppressed_diagnostics,
    )

    return analysistest.end(env)

analysis_config_suppressed_diagnostics_test = analysistest.make(
    _analysis_config_suppressed_diagnostics_test_impl,
)

def _analysis_config_warnings_not_as_errors_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    info = target[DotnetAnalysisConfigInfo]

    asserts.true(
        env,
        info.treat_warnings_as_errors,
        "Expected treat_warnings_as_errors to be True",
    )
    asserts.equals(
        env,
        ["CS1591"],
        info.warnings_not_as_errors,
    )

    return analysistest.end(env)

analysis_config_warnings_not_as_errors_test = analysistest.make(
    _analysis_config_warnings_not_as_errors_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_analysis_config_tests():
    dotnet_analysis_config(
        name = "config_treat_warnings_as_errors",
        treat_warnings_as_errors = True,
        tags = ["manual"],
    )

    analysis_config_provider_test(
        name = "analysis_config_provider_test",
        target_under_test = ":config_treat_warnings_as_errors",
    )

    dotnet_analysis_config(
        name = "config_warnings_as_errors",
        warnings_as_errors = ["CA1000", "SA1200"],
        tags = ["manual"],
    )

    analysis_config_warnings_as_errors_test(
        name = "analysis_config_warnings_as_errors_test",
        target_under_test = ":config_warnings_as_errors",
    )

    dotnet_analysis_config(
        name = "config_warning_level",
        warning_level = 5,
        tags = ["manual"],
    )

    analysis_config_warning_level_test(
        name = "analysis_config_warning_level_test",
        target_under_test = ":config_warning_level",
    )

    dotnet_analysis_config(
        name = "config_suppressed_diagnostics",
        suppressed_diagnostics = ["SA1633", "SA1600"],
        tags = ["manual"],
    )

    analysis_config_suppressed_diagnostics_test(
        name = "analysis_config_suppressed_diagnostics_test",
        target_under_test = ":config_suppressed_diagnostics",
    )

    dotnet_analysis_config(
        name = "config_warnings_not_as_errors",
        treat_warnings_as_errors = True,
        warnings_not_as_errors = ["CS1591"],
        tags = ["manual"],
    )

    analysis_config_warnings_not_as_errors_test(
        name = "analysis_config_warnings_not_as_errors_test",
        target_under_test = ":config_warnings_not_as_errors",
    )

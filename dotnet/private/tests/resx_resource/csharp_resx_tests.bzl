"resx_resource analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library", "resx_resource")
load("//dotnet/private/tests:utils.bzl", "action_args_test_impl")

def _resx_compile_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)
    resx_actions = [a for a in actions if a.mnemonic == "ResxCompile"]

    asserts.true(
        env,
        len(resx_actions) > 0,
        "Expected at least one ResxCompile action, found none",
    )

    # Verify the output file ends with .resources
    for action in resx_actions:
        found_resources_output = False
        for output in action.outputs.to_list():
            if output.basename.endswith(".resources"):
                found_resources_output = True
        asserts.true(
            env,
            found_resources_output,
            "Expected ResxCompile action to produce a .resources output",
        )

    return analysistest.end(env)

resx_compile_action_test = analysistest.make(
    _resx_compile_action_test_impl,
)

def _resx_output_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    asserts.true(
        env,
        len(files) > 0,
        "Expected resx_resource to produce output files",
    )

    found_resources = False
    for f in files:
        if f.basename.endswith(".resources"):
            found_resources = True
    asserts.true(
        env,
        found_resources,
        "Expected resx_resource output to contain a .resources file",
    )

    return analysistest.end(env)

resx_output_test = analysistest.make(
    _resx_output_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_resx_tests():
    resx_resource(
        name = "test_resx",
        srcs = ["Strings.resx"],
        tags = ["manual"],
    )

    resx_compile_action_test(
        name = "resx_compile_action_test",
        target_under_test = ":test_resx",
    )

    resx_output_test(
        name = "resx_output_test",
        target_under_test = ":test_resx",
    )

    csharp_library(
        name = "resx_consumer_lib",
        srcs = ["consumer.cs"],
        target_frameworks = ["net6.0"],
        resources = [":test_resx"],
        tags = ["manual"],
    )

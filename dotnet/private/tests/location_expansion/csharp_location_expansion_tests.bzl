"Tests that $(location) is expanded in compiler_options (#524)"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library")

def _location_expanded_test_impl(ctx):
    env = analysistest.begin(ctx)

    action_under_test = None
    for action in analysistest.target_actions(env):
        if action.mnemonic == "CSharpCompile":
            action_under_test = action
            break

    if action_under_test == None:
        fail("No CSharpCompile action found")

    # The $(location :ruleset) should have been expanded to a real path
    found_expanded = False
    found_literal = False
    for arg in action_under_test.argv:
        if "$(location" in arg:
            found_literal = True
        if "/additionalfile:" in arg and "ruleset.txt" in arg:
            found_expanded = True

    asserts.false(env, found_literal, "$(location) should not appear literally in args")

    return analysistest.end(env)

_location_expanded_test = analysistest.make(_location_expanded_test_impl)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_location_expansion_tests():
    csharp_library(
        name = "csharp_location_expansion_lib",
        srcs = ["location_expansion.cs"],
        target_frameworks = ["net8.0"],
        compiler_options = ["/additionalfile:$(location :ruleset)"],
        compile_data = [":ruleset"],
        tags = ["manual"],
    )

    _location_expanded_test(
        name = "csharp_location_expansion_test",
        target_under_test = ":csharp_location_expansion_lib",
    )

    native.filegroup(
        name = "ruleset",
        srcs = ["ruleset.txt"],
    )

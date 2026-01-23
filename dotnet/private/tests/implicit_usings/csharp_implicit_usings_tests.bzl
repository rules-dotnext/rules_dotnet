"Tests for implicit_usings attribute (#436)"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library")

def _has_global_usings_input(action):
    """Returns True if the action has a GlobalUsings.g.cs file in its inputs."""
    for input in action.inputs.to_list():
        if input.basename.endswith(".GlobalUsings.g.cs"):
            return True
    return False

def _implicit_usings_enabled_test_impl(ctx):
    env = analysistest.begin(ctx)

    action_under_test = None
    for action in analysistest.target_actions(env):
        if action.mnemonic == "CSharpCompile":
            if action_under_test == None:
                action_under_test = action
            else:
                fail("Multiple CSharpCompile actions found")

    if action_under_test == None:
        fail("No CSharpCompile action found")

    asserts.true(
        env,
        _has_global_usings_input(action_under_test),
        "Expected GlobalUsings.g.cs in CSharpCompile inputs when implicit_usings = True",
    )

    return analysistest.end(env)

_implicit_usings_enabled_test = analysistest.make(
    _implicit_usings_enabled_test_impl,
)

def _implicit_usings_disabled_test_impl(ctx):
    env = analysistest.begin(ctx)

    action_under_test = None
    for action in analysistest.target_actions(env):
        if action.mnemonic == "CSharpCompile":
            if action_under_test == None:
                action_under_test = action
            else:
                fail("Multiple CSharpCompile actions found")

    if action_under_test == None:
        fail("No CSharpCompile action found")

    asserts.false(
        env,
        _has_global_usings_input(action_under_test),
        "Expected no GlobalUsings.g.cs in CSharpCompile inputs when implicit_usings = False",
    )

    return analysistest.end(env)

_implicit_usings_disabled_test = analysistest.make(
    _implicit_usings_disabled_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_implicit_usings_tests():
    csharp_library(
        name = "csharp_implicit_usings_enabled",
        srcs = ["implicit_usings.cs"],
        target_frameworks = ["net8.0"],
        implicit_usings = True,
        tags = ["manual"],
    )

    _implicit_usings_enabled_test(
        name = "csharp_implicit_usings_enabled_test",
        target_under_test = ":csharp_implicit_usings_enabled",
    )

    csharp_library(
        name = "csharp_implicit_usings_disabled",
        srcs = ["implicit_usings.cs"],
        target_frameworks = ["net8.0"],
        implicit_usings = False,
        tags = ["manual"],
    )

    _implicit_usings_disabled_test(
        name = "csharp_implicit_usings_disabled_test",
        target_under_test = ":csharp_implicit_usings_disabled",
    )

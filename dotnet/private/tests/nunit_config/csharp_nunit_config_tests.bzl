"Tests that csharp_nunit_test macro injects NUnit deps and shim (#207)"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_nunit_test")

def _nunit_has_shim_test_impl(ctx):
    env = analysistest.begin(ctx)

    action_under_test = None
    for action in analysistest.target_actions(env):
        if action.mnemonic == "CSharpCompile":
            action_under_test = action
            break

    if action_under_test == None:
        fail("No CSharpCompile action found")

    # The shim.cs should be present in action inputs (injected by the macro)
    input_paths = [f.short_path for f in action_under_test.inputs.to_list()]
    has_shim = False
    for p in input_paths:
        if "shim.cs" in p:
            has_shim = True
            break

    asserts.true(env, has_shim, "NUnit shim.cs should be in compile inputs")

    return analysistest.end(env)

_nunit_has_shim_test = analysistest.make(_nunit_has_shim_test_impl)

def _nunit_has_test_source_impl(ctx):
    env = analysistest.begin(ctx)

    action_under_test = None
    for action in analysistest.target_actions(env):
        if action.mnemonic == "CSharpCompile":
            action_under_test = action
            break

    if action_under_test == None:
        fail("No CSharpCompile action found")

    # The user's test source should also be present
    input_paths = [f.short_path for f in action_under_test.inputs.to_list()]
    has_user_src = False
    for p in input_paths:
        if "nunit_test.cs" in p:
            has_user_src = True
            break

    asserts.true(env, has_user_src, "User test source should be in compile inputs")

    return analysistest.end(env)

_nunit_has_test_source_test = analysistest.make(_nunit_has_test_source_impl)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_nunit_config_tests():
    csharp_nunit_test(
        name = "csharp_nunit_config_target",
        srcs = ["nunit_test.cs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    _nunit_has_shim_test(
        name = "csharp_nunit_shim_injected_test",
        target_under_test = ":csharp_nunit_config_target",
    )

    _nunit_has_test_source_test(
        name = "csharp_nunit_user_source_test",
        target_under_test = ":csharp_nunit_config_target",
    )

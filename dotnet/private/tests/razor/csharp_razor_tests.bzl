"Razor library analysis tests"

load("//dotnet:defs.bzl", "razor_library")
load("//dotnet/private/tests:utils.bzl", "action_args_substring_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_razor_tests():
    # Test: razor_library creates a CSharpCompile action with additionalfile args
    razor_library(
        name = "test_razor_lib",
        razor_srcs = ["Component.razor"],
        srcs = ["Code.cs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    # Verify the CSharpCompile action includes the razor file as an additional file
    action_args_substring_test(
        name = "razor_additional_file_test",
        target_under_test = ":test_razor_lib",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["/additionalfile:"],
    )

    # Verify the CSharpCompile action includes the editorconfig as an analyzer config
    action_args_substring_test(
        name = "razor_editorconfig_test",
        target_under_test = ":test_razor_lib",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["/analyzerconfig:"],
    )

    # Verify the generated RazorAssemblyInfo.cs is included as a source
    action_args_substring_test(
        name = "razor_assembly_info_test",
        target_under_test = ":test_razor_lib",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["razor_assembly_info"],
    )

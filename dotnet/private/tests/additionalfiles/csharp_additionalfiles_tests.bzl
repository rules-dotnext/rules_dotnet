"Tests that additionalfiles attr passes /additionalfile: flags to the compiler"

load("//dotnet:defs.bzl", "csharp_library")
load("//dotnet/private/tests:utils.bzl", "action_args_substring_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_additionalfiles_tests():
    csharp_library(
        name = "csharp_with_additionalfiles",
        srcs = ["lib.cs"],
        target_frameworks = ["net8.0"],
        additionalfiles = [":config.json"],
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "csharp_additionalfile_flag_test",
        target_under_test = ":csharp_with_additionalfiles",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["/additionalfile:"],
    )

    csharp_library(
        name = "csharp_without_additionalfiles",
        srcs = ["lib.cs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "csharp_no_additionalfile_flag_test",
        target_under_test = ":csharp_without_additionalfiles",
        action_mnemonic = "CSharpCompile",
        expected_nonexistent_arg_substrings = ["/additionalfile:"],
    )

"C# version attribute tests"

load("//dotnet:defs.bzl", "csharp_library")
load("//dotnet/private/tests:utils.bzl", "action_args_substring_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_version_tests():
    csharp_library(
        name = "csharp_versioned_lib",
        srcs = ["version.cs"],
        target_frameworks = ["net8.0"],
        version = "2.1.0",
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "csharp_version_test",
        target_under_test = ":csharp_versioned_lib",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["assemblyversion.cs"],
    )

    csharp_library(
        name = "csharp_no_version_lib",
        srcs = ["version.cs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "csharp_no_version_test",
        target_under_test = ":csharp_no_version_lib",
        action_mnemonic = "CSharpCompile",
        expected_nonexistent_arg_substrings = ["assemblyversion.cs"],
    )

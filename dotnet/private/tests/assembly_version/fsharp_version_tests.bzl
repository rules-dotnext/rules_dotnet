"F# version attribute tests"

load("//dotnet:defs.bzl", "fsharp_library")
load("//dotnet/private/tests:utils.bzl", "action_args_substring_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def fsharp_version_tests():
    fsharp_library(
        name = "fsharp_versioned_lib",
        srcs = ["version.fs"],
        target_frameworks = ["net8.0"],
        version = "2.1.0",
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "fsharp_version_test",
        target_under_test = ":fsharp_versioned_lib",
        action_mnemonic = "FSharpCompile",
        expected_arg_substrings = ["assemblyversion.fs"],
    )

    fsharp_library(
        name = "fsharp_no_version_lib",
        srcs = ["version.fs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "fsharp_no_version_test",
        target_under_test = ":fsharp_no_version_lib",
        action_mnemonic = "FSharpCompile",
        expected_nonexistent_arg_substrings = ["assemblyversion.fs"],
    )

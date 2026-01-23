"C# pathmap attribute tests"

load("//dotnet:defs.bzl", "csharp_library")
load("//dotnet/private/tests:utils.bzl", "action_args_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_pathmap_tests():
    csharp_library(
        name = "csharp_pathmap_lib",
        srcs = ["pathmap.cs"],
        target_frameworks = ["net8.0"],
        pathmap = {
            "/src": "/mapped",
            "/workspace": ".",
        },
        tags = ["manual"],
    )

    action_args_test(
        name = "csharp_pathmap_test",
        target_under_test = ":csharp_pathmap_lib",
        action_mnemonic = "CSharpCompile",
        expected_partial_args = [
            "/pathmap:/src=/mapped",
            "/pathmap:/workspace=.",
        ],
    )

    csharp_library(
        name = "csharp_no_pathmap_lib",
        srcs = ["pathmap.cs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    action_args_test(
        name = "csharp_no_pathmap_test",
        target_under_test = ":csharp_no_pathmap_lib",
        action_mnemonic = "CSharpCompile",
        expected_nonexistent_partial_args = [
            "/pathmap:/src=/mapped",
        ],
    )

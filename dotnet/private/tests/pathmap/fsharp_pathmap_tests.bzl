"F# pathmap attribute tests"

load("//dotnet:defs.bzl", "fsharp_library")
load("//dotnet/private/tests:utils.bzl", "action_args_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def fsharp_pathmap_tests():
    fsharp_library(
        name = "fsharp_pathmap_lib",
        srcs = ["pathmap.fs"],
        target_frameworks = ["net8.0"],
        pathmap = {
            "/src": "/mapped",
            "/workspace": ".",
        },
        tags = ["manual"],
    )

    action_args_test(
        name = "fsharp_pathmap_test",
        target_under_test = ":fsharp_pathmap_lib",
        action_mnemonic = "FSharpCompile",
        expected_partial_args = [
            "--pathmap:/src=/mapped",
            "--pathmap:/workspace=.",
        ],
    )

    fsharp_library(
        name = "fsharp_no_pathmap_lib",
        srcs = ["pathmap.fs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    action_args_test(
        name = "fsharp_no_pathmap_test",
        target_under_test = ":fsharp_no_pathmap_lib",
        action_mnemonic = "FSharpCompile",
        expected_nonexistent_partial_args = [
            "--pathmap:/src=/mapped",
        ],
    )

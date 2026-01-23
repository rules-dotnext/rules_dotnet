"Bazel compatibility tests"

load("//dotnet:defs.bzl", "csharp_library")
load("//dotnet/private/tests:utils.bzl", "action_args_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_bazel_compat_tests():
    # A basic csharp_library that must compile successfully.
    # This exercises the toolchain parameter on actions.run() and
    # the //conditions:default in select() added for bazel-compat.
    csharp_library(
        name = "bazel_compat_lib",
        srcs = ["lib.cs"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    # Verify the CSharpCompile action is produced with standard args.
    # This confirms that the toolchain registration and action plumbing
    # work correctly under the current Bazel version (8+), which enables
    # --incompatible_auto_exec_groups by default.
    action_args_test(
        name = "bazel_compat_compile_test",
        target_under_test = ":bazel_compat_lib",
        action_mnemonic = "CSharpCompile",
        expected_partial_args = ["/target:library"],
    )

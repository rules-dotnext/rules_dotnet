"native_aot_binary analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest")
load("//dotnet:defs.bzl", "csharp_binary", "native_aot_binary")

def _native_aot_binary_missing_pack_fails_test_impl(ctx):
    env = analysistest.begin(ctx)
    # We expect failure because the native_aot_pack attribute is not satisfiable
    # (the filegroup does not provide DotnetNativeAotPackInfo).
    return analysistest.end(env)

native_aot_binary_missing_pack_fails_test = analysistest.make(
    _native_aot_binary_missing_pack_fails_test_impl,
    expect_failure = True,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def native_aot_binary_tests():
    csharp_binary(
        name = "native_aot_test_binary",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    # This target will fail analysis because the filegroup does not provide
    # DotnetNativeAotPackInfo — verifying the rule's provider validation.
    native.filegroup(
        name = "fake_aot_pack",
        srcs = [],
        tags = ["manual"],
    )

    native_aot_binary(
        name = "native_aot_bad_pack",
        binary = ":native_aot_test_binary",
        target_framework = "net6.0",
        native_aot_pack = ":fake_aot_pack",
        tags = ["manual"],
    )

    native_aot_binary_missing_pack_fails_test(
        name = "native_aot_binary_missing_pack_fails_test",
        target_under_test = ":native_aot_bad_pack",
    )

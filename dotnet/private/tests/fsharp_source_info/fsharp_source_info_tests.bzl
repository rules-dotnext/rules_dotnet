"Tests for FSharpSourceInfo provider (#315)"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "fsharp_library")
load("//dotnet/private:providers.bzl", "FSharpSourceInfo")

def _fsharp_source_info_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    # Verify the provider exists
    asserts.true(
        env,
        FSharpSourceInfo in target_under_test,
        "Expected FSharpSourceInfo provider to be present",
    )

    info = target_under_test[FSharpSourceInfo]

    # Check direct srcs contains both .fs and .fsi files
    src_basenames = sorted([f.basename for f in info.srcs])
    asserts.equals(
        env,
        ["Types.fs", "Types.fsi"],
        src_basenames,
        "Expected srcs to contain Types.fs and Types.fsi",
    )

    return analysistest.end(env)

_fsharp_source_info_test = analysistest.make(
    _fsharp_source_info_test_impl,
)

def _fsharp_source_info_transitive_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    asserts.true(
        env,
        FSharpSourceInfo in target_under_test,
        "Expected FSharpSourceInfo provider to be present on consumer",
    )

    info = target_under_test[FSharpSourceInfo]

    # Direct srcs should only be Consumer.fs
    src_basenames = [f.basename for f in info.srcs]
    asserts.equals(
        env,
        ["Consumer.fs"],
        src_basenames,
        "Expected direct srcs to contain only Consumer.fs",
    )

    # Transitive srcs should include both Consumer.fs and the dependency's sources
    transitive_basenames = sorted([f.basename for f in info.transitive_srcs.to_list()])
    asserts.true(
        env,
        "Consumer.fs" in transitive_basenames,
        "Expected Consumer.fs in transitive_srcs",
    )
    asserts.true(
        env,
        "Types.fs" in transitive_basenames,
        "Expected Types.fs in transitive_srcs",
    )
    asserts.true(
        env,
        "Types.fsi" in transitive_basenames,
        "Expected Types.fsi in transitive_srcs",
    )

    return analysistest.end(env)

_fsharp_source_info_transitive_test = analysistest.make(
    _fsharp_source_info_transitive_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def fsharp_source_info_tests():
    fsharp_library(
        name = "fsharp_types_lib",
        srcs = [
            "Types.fsi",
            "Types.fs",
        ],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    _fsharp_source_info_test(
        name = "fsharp_source_info_provider_test",
        target_under_test = ":fsharp_types_lib",
    )

    fsharp_library(
        name = "fsharp_consumer_lib",
        srcs = ["Consumer.fs"],
        deps = [":fsharp_types_lib"],
        target_frameworks = ["net8.0"],
        tags = ["manual"],
    )

    _fsharp_source_info_transitive_test(
        name = "fsharp_source_info_transitive_test",
        target_under_test = ":fsharp_consumer_lib",
    )

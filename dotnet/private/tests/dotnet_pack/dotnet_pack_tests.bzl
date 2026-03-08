"dotnet_pack analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library", "dotnet_pack")

def _dotnet_pack_produces_nupkg_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    asserts.true(
        env,
        len(files) > 0,
        "Expected dotnet_pack to produce output files",
    )

    found_nupkg = False
    for f in files:
        if f.basename.endswith(".nupkg"):
            found_nupkg = True
    asserts.true(
        env,
        found_nupkg,
        "Expected dotnet_pack output to contain a .nupkg file, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

dotnet_pack_produces_nupkg_test = analysistest.make(
    _dotnet_pack_produces_nupkg_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def dotnet_pack_tests():
    csharp_library(
        name = "pack_test_lib",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    dotnet_pack(
        name = "pack_test_nupkg",
        library = ":pack_test_lib",
        target_framework = "net6.0",
        package_version = "1.0.0",
        tags = ["manual"],
    )

    dotnet_pack_produces_nupkg_test(
        name = "dotnet_pack_produces_nupkg_test",
        target_under_test = ":pack_test_nupkg",
    )

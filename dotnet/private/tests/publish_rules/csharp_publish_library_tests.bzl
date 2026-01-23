"publish_library analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library", "publish_library")

def _publish_library_produces_depsjson_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    asserts.true(
        env,
        len(files) > 0,
        "Expected publish_library to produce output files",
    )

    found_depsjson = False
    for f in files:
        if f.basename.endswith(".deps.json"):
            found_depsjson = True
    asserts.true(
        env,
        found_depsjson,
        "Expected publish_library output to contain a .deps.json file, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

publish_library_produces_depsjson_test = analysistest.make(
    _publish_library_produces_depsjson_test_impl,
)

def _publish_library_no_runtimeconfig_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    # publish_library should NOT produce a runtimeconfig.json (only binaries do)
    found_runtimeconfig = False
    for f in files:
        if f.basename.endswith(".runtimeconfig.json"):
            found_runtimeconfig = True

    asserts.false(
        env,
        found_runtimeconfig,
        "Expected publish_library NOT to produce runtimeconfig.json (that is for binaries only), got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

publish_library_no_runtimeconfig_test = analysistest.make(
    _publish_library_no_runtimeconfig_test_impl,
)

def _publish_library_produces_dlls_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    found_dll = False
    for f in files:
        if f.basename.endswith(".dll"):
            found_dll = True
    asserts.true(
        env,
        found_dll,
        "Expected publish_library output to contain .dll files, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

publish_library_produces_dlls_test = analysistest.make(
    _publish_library_produces_dlls_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_publish_library_tests():
    csharp_library(
        name = "publish_test_lib",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    publish_library(
        name = "published_lib",
        library = ":publish_test_lib",
        target_framework = "net6.0",
        tags = ["manual"],
    )

    publish_library_produces_depsjson_test(
        name = "publish_library_produces_depsjson_test",
        target_under_test = ":published_lib",
    )

    publish_library_no_runtimeconfig_test(
        name = "publish_library_no_runtimeconfig_test",
        target_under_test = ":published_lib",
    )

    publish_library_produces_dlls_test(
        name = "publish_library_produces_dlls_test",
        target_under_test = ":published_lib",
    )

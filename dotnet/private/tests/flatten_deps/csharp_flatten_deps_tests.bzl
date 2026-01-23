"Tests for flatten_deps attribute on csharp_binary."

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_binary", "csharp_library")

def _flatten_deps_includes_transitive_dlls_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    output_files = target_under_test[DefaultInfo].files.to_list()
    output_basenames = [f.basename for f in output_files]

    # When flatten_deps is True, the dep_lib DLL should appear in output files
    has_dep_lib = False
    for name in output_basenames:
        if "dep_lib" in name and name.endswith(".dll"):
            has_dep_lib = True
            break

    asserts.true(
        env,
        has_dep_lib,
        "Expected flatten_deps=True to copy dep_lib.dll into output files, got: {}".format(output_basenames),
    )

    return analysistest.end(env)

flatten_deps_includes_transitive_dlls_test = analysistest.make(
    _flatten_deps_includes_transitive_dlls_test_impl,
)

def _no_flatten_deps_excludes_transitive_dlls_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    output_files = target_under_test[DefaultInfo].files.to_list()
    output_basenames = [f.basename for f in output_files]

    # When flatten_deps is False (default), transitive dep DLLs should NOT be
    # in the output files (they are resolved via probing paths instead)
    has_dep_lib = False
    for name in output_basenames:
        if "dep_lib" in name and name.endswith(".dll"):
            has_dep_lib = True
            break

    asserts.false(
        env,
        has_dep_lib,
        "Expected flatten_deps=False to NOT copy dep_lib.dll into output files, got: {}".format(output_basenames),
    )

    return analysistest.end(env)

no_flatten_deps_excludes_transitive_dlls_test = analysistest.make(
    _no_flatten_deps_excludes_transitive_dlls_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_flatten_deps_tests():
    csharp_library(
        name = "dep_lib",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    csharp_binary(
        name = "app_with_flatten",
        srcs = ["app.cs"],
        target_frameworks = ["net6.0"],
        deps = [":dep_lib"],
        flatten_deps = True,
        tags = ["manual"],
    )

    flatten_deps_includes_transitive_dlls_test(
        name = "flatten_deps_includes_transitive_dlls_test",
        target_under_test = ":app_with_flatten",
    )

    csharp_binary(
        name = "app_without_flatten",
        srcs = ["app.cs"],
        target_frameworks = ["net6.0"],
        deps = [":dep_lib"],
        flatten_deps = False,
        tags = ["manual"],
    )

    no_flatten_deps_excludes_transitive_dlls_test(
        name = "no_flatten_deps_excludes_transitive_dlls_test",
        target_under_test = ":app_without_flatten",
    )

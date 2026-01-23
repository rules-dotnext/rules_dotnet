"Tests for native_deps attribute on csharp_library."

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library")

# buildifier: disable=bzl-visibility
load("//dotnet/private:providers.bzl", "DotnetAssemblyRuntimeInfo")

def _native_deps_populates_native_field_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    runtime_info = target_under_test[DotnetAssemblyRuntimeInfo]
    native_files = runtime_info.native

    asserts.true(
        env,
        len(native_files) > 0,
        "Expected native_deps to populate DotnetAssemblyRuntimeInfo.native, but got empty list",
    )

    # Verify the native file has a shared library extension
    native_basenames = [f.basename for f in native_files]
    has_shared_lib = False
    for name in native_basenames:
        if name.endswith(".so") or name.endswith(".dylib") or name.endswith(".dll"):
            has_shared_lib = True
            break

    asserts.true(
        env,
        has_shared_lib,
        "Expected at least one shared library in native files, got: {}".format(native_basenames),
    )

    return analysistest.end(env)

native_deps_populates_native_field_test = analysistest.make(
    _native_deps_populates_native_field_test_impl,
)

def _no_native_deps_empty_native_field_test_impl(ctx):
    env = analysistest.begin(ctx)
    target_under_test = analysistest.target_under_test(env)

    runtime_info = target_under_test[DotnetAssemblyRuntimeInfo]
    native_files = runtime_info.native

    asserts.equals(
        env,
        0,
        len(native_files),
        "Expected empty native field when no native_deps specified",
    )

    return analysistest.end(env)

no_native_deps_empty_native_field_test = analysistest.make(
    _no_native_deps_empty_native_field_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_native_deps_tests():
    native_library(
        name = "native_lib",
        srcs = ["native.c"],
        tags = ["manual"],
    )

    csharp_library(
        name = "csharp_with_native_deps",
        srcs = ["consumer.cs"],
        target_frameworks = ["net6.0"],
        native_deps = [":native_lib"],
        tags = ["manual"],
    )

    native_deps_populates_native_field_test(
        name = "native_deps_populates_native_field_test",
        target_under_test = ":csharp_with_native_deps",
    )

    csharp_library(
        name = "csharp_without_native_deps",
        srcs = ["consumer.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    no_native_deps_empty_native_field_test(
        name = "no_native_deps_empty_native_field_test",
        target_under_test = ":csharp_without_native_deps",
    )

def native_library(name, srcs, **kwargs):
    """Wrapper to create a cc_library with shared library output."""
    native.cc_library(
        name = name,
        srcs = srcs,
        linkstatic = False,
        **kwargs
    )

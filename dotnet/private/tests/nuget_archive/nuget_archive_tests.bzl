"nuget_archive filegroup structure tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

def _nuget_archive_exposes_files_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    # The fsharp.core package should expose files via its :files filegroup
    asserts.true(
        env,
        len(files) > 0,
        "Expected nuget_archive :files filegroup to contain files",
    )

    return analysistest.end(env)

nuget_archive_exposes_files_test = analysistest.make(
    _nuget_archive_exposes_files_test_impl,
)

def _nuget_archive_has_content_files_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)

    # The content_files filegroup should be resolvable
    asserts.true(
        env,
        target != None,
        "Expected nuget_archive :content_files to be resolvable",
    )

    return analysistest.end(env)

nuget_archive_has_content_files_test = analysistest.make(
    _nuget_archive_has_content_files_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def nuget_archive_tests():
    nuget_archive_exposes_files_test(
        name = "nuget_archive_exposes_files_test",
        target_under_test = "@paket.rules_dotnet_dev_nuget_packages//fsharp.core:files",
    )

    nuget_archive_has_content_files_test(
        name = "nuget_archive_has_content_files_test",
        target_under_test = "@paket.rules_dotnet_dev_nuget_packages//fsharp.core:content_files",
    )

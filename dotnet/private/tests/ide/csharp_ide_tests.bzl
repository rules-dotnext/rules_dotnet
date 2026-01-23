"dotnet_project analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//dotnet:defs.bzl", "csharp_library", "dotnet_project")

def _dotnet_project_produces_csproj_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    asserts.true(
        env,
        len(files) > 0,
        "Expected dotnet_project to produce output files",
    )

    found_csproj = False
    for f in files:
        if f.basename.endswith(".csproj"):
            found_csproj = True
    asserts.true(
        env,
        found_csproj,
        "Expected dotnet_project output to contain a .csproj file, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

dotnet_project_produces_csproj_test = analysistest.make(
    _dotnet_project_produces_csproj_test_impl,
)

def _dotnet_project_is_executable_test_impl(ctx):
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)

    # dotnet_project should be executable (produces a copy script)
    asserts.true(
        env,
        target[DefaultInfo].files_to_run.executable != None,
        "Expected dotnet_project to be executable (copy script)",
    )

    return analysistest.end(env)

dotnet_project_is_executable_test = analysistest.make(
    _dotnet_project_is_executable_test_impl,
)

def _dotnet_project_write_action_test_impl(ctx):
    env = analysistest.begin(ctx)

    actions = analysistest.target_actions(env)

    # dotnet_project uses ctx.actions.write to produce the .csproj
    write_actions = [a for a in actions if a.mnemonic == "FileWrite"]

    asserts.true(
        env,
        len(write_actions) >= 1,
        "Expected at least one FileWrite action for .csproj generation, found: {}".format(
            [a.mnemonic for a in actions],
        ),
    )

    return analysistest.end(env)

dotnet_project_write_action_test = analysistest.make(
    _dotnet_project_write_action_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_ide_tests():
    csharp_library(
        name = "ide_test_lib",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    dotnet_project(
        name = "ide_test_project",
        target = ":ide_test_lib",
        srcs = ["lib.cs"],
        target_framework = "net6.0",
        tags = ["manual"],
    )

    dotnet_project_produces_csproj_test(
        name = "dotnet_project_produces_csproj_test",
        target_under_test = ":ide_test_project",
    )

    dotnet_project_is_executable_test(
        name = "dotnet_project_is_executable_test",
        target_under_test = ":ide_test_project",
    )

    dotnet_project_write_action_test(
        name = "dotnet_project_write_action_test",
        target_under_test = ":ide_test_project",
    )

    # Test with custom attributes
    dotnet_project(
        name = "ide_test_project_exe",
        target = ":ide_test_lib",
        srcs = ["lib.cs"],
        target_framework = "net6.0",
        output_type = "Exe",
        nullable = "enable",
        project_sdk = "Microsoft.NET.Sdk.Web",
        tags = ["manual"],
    )

    dotnet_project_produces_csproj_test(
        name = "dotnet_project_custom_attrs_produces_csproj_test",
        target_under_test = ":ide_test_project_exe",
    )

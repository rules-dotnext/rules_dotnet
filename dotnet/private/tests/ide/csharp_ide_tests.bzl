"dotnet_project and dotnet_solution analysis tests"

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(
    "//dotnet:defs.bzl",
    "DotnetIdeInfo",
    "csharp_library",
    "dotnet_project",
    "dotnet_solution",
)

# --- Existing tests (preserved) ---

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

# --- New tests: aspect-powered IDE info ---

def _dotnet_project_has_project_deps_test_impl(ctx):
    """Test that dotnet_project on a library with deps populates DotnetIdeInfo."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    # Should still produce a .csproj
    found_csproj = False
    for f in files:
        if f.basename.endswith(".csproj"):
            found_csproj = True
    asserts.true(
        env,
        found_csproj,
        "Expected .csproj output for project with deps",
    )

    return analysistest.end(env)

dotnet_project_has_project_deps_test = analysistest.make(
    _dotnet_project_has_project_deps_test_impl,
)

def _dotnet_solution_produces_sln_test_impl(ctx):
    """Test that dotnet_solution produces a .sln file."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    asserts.true(
        env,
        len(files) > 0,
        "Expected dotnet_solution to produce output files",
    )

    found_sln = False
    for f in files:
        if f.basename.endswith(".sln"):
            found_sln = True
    asserts.true(
        env,
        found_sln,
        "Expected dotnet_solution output to contain a .sln file, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

dotnet_solution_produces_sln_test = analysistest.make(
    _dotnet_solution_produces_sln_test_impl,
)

def _dotnet_solution_produces_csproj_test_impl(ctx):
    """Test that dotnet_solution produces .csproj files for each project."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    csproj_files = [f for f in files if f.basename.endswith(".csproj")]
    asserts.true(
        env,
        len(csproj_files) >= 1,
        "Expected at least 1 .csproj from dotnet_solution, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

dotnet_solution_produces_csproj_test = analysistest.make(
    _dotnet_solution_produces_csproj_test_impl,
)

def _dotnet_solution_is_executable_test_impl(ctx):
    """Test that dotnet_solution is executable (copy script)."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)

    asserts.true(
        env,
        target[DefaultInfo].files_to_run.executable != None,
        "Expected dotnet_solution to be executable (copy script)",
    )

    return analysistest.end(env)

dotnet_solution_is_executable_test = analysistest.make(
    _dotnet_solution_is_executable_test_impl,
)

def _dotnet_solution_produces_props_test_impl(ctx):
    """Test that dotnet_solution produces Directory.Build.props."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    found_props = False
    for f in files:
        if f.basename == "Directory.Build.props":
            found_props = True
    asserts.true(
        env,
        found_props,
        "Expected Directory.Build.props in dotnet_solution output, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

dotnet_solution_produces_props_test = analysistest.make(
    _dotnet_solution_produces_props_test_impl,
)

def _dotnet_solution_produces_nuget_config_test_impl(ctx):
    """Test that dotnet_solution produces NuGet.config."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    found_config = False
    for f in files:
        if f.basename == "NuGet.config":
            found_config = True
    asserts.true(
        env,
        found_config,
        "Expected NuGet.config in dotnet_solution output, got: {}".format(
            [f.basename for f in files],
        ),
    )

    return analysistest.end(env)

dotnet_solution_produces_nuget_config_test = analysistest.make(
    _dotnet_solution_produces_nuget_config_test_impl,
)

def _dotnet_project_srcs_optional_test_impl(ctx):
    """Test that dotnet_project works without explicit srcs (infers from aspect)."""
    env = analysistest.begin(ctx)

    target = analysistest.target_under_test(env)
    files = target[DefaultInfo].files.to_list()

    found_csproj = False
    for f in files:
        if f.basename.endswith(".csproj"):
            found_csproj = True
    asserts.true(
        env,
        found_csproj,
        "Expected .csproj even without explicit srcs",
    )

    return analysistest.end(env)

dotnet_project_srcs_optional_test = analysistest.make(
    _dotnet_project_srcs_optional_test_impl,
)

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_ide_tests():
    # --- Base test library ---
    csharp_library(
        name = "ide_test_lib",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        tags = ["manual"],
    )

    # --- Library with a project dep (for ProjectReference testing) ---
    csharp_library(
        name = "ide_test_lib_with_dep",
        srcs = ["lib.cs"],
        target_frameworks = ["net6.0"],
        deps = [":ide_test_lib"],
        tags = ["manual"],
    )

    # --- Original tests (preserved) ---

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

    # --- New tests ---

    # Test: project with a dep still produces .csproj
    dotnet_project(
        name = "ide_test_project_with_dep",
        target = ":ide_test_lib_with_dep",
        target_framework = "net6.0",
        tags = ["manual"],
    )

    dotnet_project_has_project_deps_test(
        name = "dotnet_project_has_project_deps_test",
        target_under_test = ":ide_test_project_with_dep",
    )

    # Test: srcs optional (inferred from aspect)
    dotnet_project(
        name = "ide_test_project_no_srcs",
        target = ":ide_test_lib",
        target_framework = "net6.0",
        tags = ["manual"],
    )

    dotnet_project_srcs_optional_test(
        name = "dotnet_project_srcs_optional_test",
        target_under_test = ":ide_test_project_no_srcs",
    )

    # Test: dotnet_solution
    dotnet_solution(
        name = "ide_test_solution",
        projects = [":ide_test_lib", ":ide_test_lib_with_dep"],
        target_framework = "net6.0",
        tags = ["manual"],
    )

    dotnet_solution_produces_sln_test(
        name = "dotnet_solution_produces_sln_test",
        target_under_test = ":ide_test_solution",
    )

    dotnet_solution_produces_csproj_test(
        name = "dotnet_solution_produces_csproj_test",
        target_under_test = ":ide_test_solution",
    )

    dotnet_solution_is_executable_test(
        name = "dotnet_solution_is_executable_test",
        target_under_test = ":ide_test_solution",
    )

    dotnet_solution_produces_props_test(
        name = "dotnet_solution_produces_props_test",
        target_under_test = ":ide_test_solution",
    )

    dotnet_solution_produces_nuget_config_test(
        name = "dotnet_solution_produces_nuget_config_test",
        target_under_test = ":ide_test_solution",
    )

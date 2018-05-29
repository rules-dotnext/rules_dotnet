workspace(name = "io_bazel_rules_dotnet")

load("//dotnet:defs.bzl", "dotnet_register_toolchains", "dotnet_repositories", "dotnet_nuget_new")

dotnet_repositories()
dotnet_register_toolchains("host")

dotnet_nuget_new(
    name = "npgsql", 
    package="Npgsql", 
    version="3.2.7", 
    sha256="fa3e0cfbb2caa9946d2ce3d8174031a06320aad2c9e69a60f7739b9ddf19f172",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_import_library")

dotnet_import_library(
    name = "npgsqllib",
    src = "lib/net451/Npgsql.dll"
)    
    """
)

dotnet_nuget_new(
    name = "castle_core", 
    package="Castle.Core", 
    version="4.0.0", 
    sha256="5f15e3a575e3a009ab606d5e6fe74133c3947e4cabd6640fcb4d5e3d5e0ebc79",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_import_library")

dotnet_import_library(
    name = "castle.core.dll",
    src = "lib/net45/Castle.Core.dll"
)    
    """
)


load("@io_bazel_rules_dotnet//tests:bazel_tests.bzl", "test_environment")

test_environment()

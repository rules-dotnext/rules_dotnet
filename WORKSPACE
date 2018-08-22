workspace(name = "io_bazel_rules_dotnet")

load("//dotnet:defs.bzl", "dotnet_register_toolchains", "dotnet_repositories", 
        "dotnet_nuget_new", "net_gac4", "vs2017_ref_net")

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

dotnet_nuget_new(
    name = "Microsoft.Build.Framework", 
    package="Microsoft.Build.Framework", 
    version="15.7.179", 
    sha256="872275efced822c36e25b9ad88aa93272a9b85b3e6498855309a6fbb45f07b34",
    build_file_content = """
package(default_visibility = [ "//visibility:public" ])
load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "net_import_library")

net_import_library(
    name = "lib",
    src = "lib/net46/Microsoft.Build.Framework.dll"
)    
    """
)

net_gac4(
  name = "System.ComponentModel.DataAnnotations",
  version = "4.0.0.0",
  token = "31bf3856ad364e35"
)

# The rule is left as an example. It is commented out, because our CI server doesn't have VS2017 installed
# vs2017_ref_net(name = "vs2017_ref")

load("@io_bazel_rules_dotnet//tests:bazel_tests.bzl", "test_environment")

test_environment()

workspace(name = "io_bazel_rules_dotnet")

load("//dotnet:defs.bzl", "dotnet_register_toolchains", "dotnet_repositories", 
        "dotnet_nuget_new", "net_gac4", "vs2017_ref_net", "dotnet_nuget_simple", "nuget_package")

dotnet_repositories()
dotnet_register_toolchains("host")

nuget_package(
   name = "npgsql",
   package = "npgsql",
   version = "4.0.3",
   sha256 = "4e1f91eb9f0c3dfb8e029edbc325175cd202455df3641bc16155ef422b6bfd6f",
   core_lib = "lib/netstandard2.0/Npgsql.dll",
   net_lib = "lib/net451/Npgsql.dll",
   mono_lib = "lib/net45/Npgsql.dll",
   deps = [
   ],
   core_files = [
       "lib/netstandard2.0/Npgsql.dll",
       "lib/netstandard2.0/Npgsql.pdb",
       "lib/netstandard2.0/Npgsql.xml",
   ],
   net_files = [
       "lib/net451/Npgsql.dll",
       "lib/net451/Npgsql.pdb",
       "lib/net451/Npgsql.xml",
   ],
   mono_files = [
       "lib/net45/Npgsql.dll",
       "lib/net45/Npgsql.pdb",
       "lib/net45/Npgsql.xml",
   ],
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

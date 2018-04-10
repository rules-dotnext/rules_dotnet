load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
    "DotnetSource"
)


DotnetContext = provider()


def dotnet_repositories():
  print("DEPRECATED: go_repositories has been deprecated. go_rules_dependencies installs dependencies the way nested workspaces should, and go_register_toolchains adds the toolchains")
  
load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    dotnet_context = "dotnet_context",
)
load(
    "@io_bazel_rules_dotnet//dotnet/toolchain:toolchains.bzl",
    "dotnet_register_toolchains",
)
load(
    "@io_bazel_rules_dotnet//dotnet/private:sdk.bzl",
    dotnet_download_sdk = "dotnet_download_sdk",
    dotnet_host_sdk = "dotnet_host_sdk",
    dotnet_local_sdk = "dotnet_local_sdk",
)
load(
    "@io_bazel_rules_dotnet//dotnet/private:dotnet_toolchain.bzl",
    dotnet_toolchain = "dotnet_toolchain",
)

"{{MODULE_NAME}}"

module(
    name = "{{MODULE_NAME}}",
    version = "0.0.0",
    bazel_compatibility = ["{{BAZEL_COMPAT}}"],
)

# .NET toolchain
bazel_dep(name = "rules_dotnet", version = "{{RULES_DOTNET_VERSION}}")

dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "{{DOTNET_VERSION}}")
use_repo(dotnet, "dotnet_toolchains")
register_toolchains("@dotnet_toolchains//:all")

# Required dependencies
bazel_dep(name = "bazel_skylib", version = "1.7.1")
bazel_dep(name = "platforms", version = "1.0.0")
bazel_dep(name = "rules_cc", version = "0.1.2")      # Required for Bazel 9 CcInfo
bazel_dep(name = "rules_shell", version = "0.5.0")

{{#PROTO_SECTION}}
# Proto/gRPC — NOT dev_dependency in consumer repos
bazel_dep(name = "protobuf", version = "29.3")
bazel_dep(name = "rules_proto", version = "7.1.0")
{{#GRPC}}
bazel_dep(name = "grpc", version = "1.71.0")
{{/GRPC}}
{{/PROTO_SECTION}}

{{NUGET_SECTION}}

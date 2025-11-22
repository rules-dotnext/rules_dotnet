load("@rules_proto//proto:defs.bzl", "proto_library")
# Proto/gRPC rules load from proto.bzl, NEVER from defs.bzl
load("@rules_dotnet//dotnet:proto.bzl",
    "csharp_proto_library",
    {{#GRPC}}"csharp_grpc_library",{{/GRPC}}
)

proto_library(
    name = "{{PROTO_TARGET_NAME}}",
    srcs = [{{PROTO_SRCS}}],
    deps = [{{PROTO_DEPS}}],
    visibility = ["//visibility:public"],
)

csharp_proto_library(
    name = "{{PROTO_TARGET_NAME}}_csharp",
    proto = ":{{PROTO_TARGET_NAME}}",
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    visibility = ["//visibility:public"],
)

{{#GRPC}}
csharp_grpc_library(
    name = "{{PROTO_TARGET_NAME}}_grpc_csharp",
    proto = ":{{PROTO_TARGET_NAME}}",
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    visibility = ["//visibility:public"],
)
{{/GRPC}}

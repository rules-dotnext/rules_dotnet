"""Public API for protobuf and gRPC rules.

Users who want proto/gRPC support load from here instead of dotnet/defs.bzl:

    load("@rules_dotnet//dotnet:proto.bzl",
        "csharp_proto_library",
        "csharp_grpc_library",
        "csharp_proto_compiler",
    )

This file is separate from defs.bzl because proto rules depend on
@protobuf (for ProtoInfo), which is an optional dependency. Users who
don't use proto/gRPC should not need protobuf in their workspace.
"""

load(
    "//dotnet/private/rules/proto:csharp_grpc_library.bzl",
    _csharp_grpc_library = "csharp_grpc_library",
)
load(
    "//dotnet/private/rules/proto:csharp_proto_compiler.bzl",
    _csharp_proto_compiler = "csharp_proto_compiler",
)
load(
    "//dotnet/private/rules/proto:csharp_proto_library.bzl",
    _csharp_proto_library = "csharp_proto_library",
)

csharp_proto_library = _csharp_proto_library
csharp_grpc_library = _csharp_grpc_library
csharp_proto_compiler = _csharp_proto_compiler

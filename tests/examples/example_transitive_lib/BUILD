load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_library", "core_library", "net_library")

dotnet_library(
    name = "TransitiveClass",
    srcs = [
        "Properties/AssemblyInfo.cs",
        "TransitiveClass.cs",
    ],
    visibility = ["//visibility:public"],
)

core_library(
    name = "TransitiveClass-core",
    srcs = [
        "TransitiveClass.cs",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
    ]
)

net_library(
    name = "TransitiveClass-net",
    srcs = [
        "TransitiveClass.cs",
    ],
    visibility = ["//visibility:public"],
    deps = [
    ]
)

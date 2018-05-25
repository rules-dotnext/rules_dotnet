load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_library", "core_library")

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
)

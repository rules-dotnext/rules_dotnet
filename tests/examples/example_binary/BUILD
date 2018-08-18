load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_binary", "core_binary", "net_binary")


dotnet_binary(
    name = "hello",
    srcs = [
        "Program.cs",
        "Properties/AssemblyInfo.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass",
        "@npgsql//:npgsqllib",
    ],
)

core_binary(
    name = "hello-core",
    srcs = [
        "Program.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
    ]
)

net_binary(
    name = "hello-net",
    srcs = [
        "Program.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass",
        "@Microsoft.Build.Framework//:lib",
    ]
)

load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "core_binary")

core_binary(
    name = "genbuild",
    srcs = [
        "Program.cs",
        "DllInfo.cs",
    ],
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.FileSystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
    ]
)

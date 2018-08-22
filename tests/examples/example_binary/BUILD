load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_binary", 
        "core_binary", "net_binary", "net_com_library")


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

net_com_library(
    name = "com-ref-shell32",
    guid = "50A7E9B0-70EF-11D1-B75A-00A0C90564FE",
    major_version = 1,
    minor_version = 0,
    lcid = 0,
    platform = "win32",
    namespace = "Shell32",
    out = "shell32.dll"
)

# The rule is left as an example. It is commented out, because our CI server doesn't have VS2017 installed
#net_binary(
#    name = "shell-com-example",
#    srcs = [
#        "ShellComExample.cs",
#    ],
#    deps = [
#        ":com-ref-shell32",
#        "@Microsoft.Build.Framework//:lib",
#        "@System.ComponentModel.DataAnnotations//:GAC_MSIL",
#        "@vs2017_ref//:vs/v2.0/Microsoft.VisualStudio.QualityTools.UnitTestFramework"
#    ]
#)

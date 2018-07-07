load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "dotnet_binary", "core_binary", "net_binary")

dotnet_binary(
    name = "hello_tool",
    srcs = [
        "MyTool.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass",
    ],
)

core_binary(
    name = "hello_tool_core",
    srcs = [
        "MyTool.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.Extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.FileSystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
    ],
)

net_binary(
    name = "hello_tool_net",
    srcs = [
        "MyTool.cs",
    ],
    deps = [
        "//tests/examples/example_lib:MyClass",
    ],
)

genrule(
    name = "hello_single_output",
    outs = [
        "hello_world.txt",
    ],
    tools = [
        ":hello_tool",
    ],
    cmd = "$(location :hello_tool) $@",
)

genrule(
    name = "hello_multiple_outputs",
    outs = [
        "hello_world_1.txt",
        "hello_world_2.txt",
    ],
    tools = [
        ":hello_tool",
    ],
    cmd = "$(location :hello_tool) $(OUTS)",
)

genrule(
    name = "hello_single_output_core",
    outs = [
        "hello_world_core.txt",
    ],
    tools = [
        ":hello_tool_core",
    ],
    cmd = "$(location :hello_tool_core) $@",
)

genrule(
    name = "hello_multiple_outputs_core",
    outs = [
        "hello_world_1_core.txt",
        "hello_world_2_core.txt",
    ],
    tools = [
        ":hello_tool_core",
    ],
    cmd = "$(location :hello_tool_core) $(OUTS)",
)

genrule(
    name = "hello_single_output_net",
    outs = [
        "hello_world_net.txt",
    ],
    tools = [
        ":hello_tool_net",
    ],
    cmd = "$(location :hello_tool_net) $@",
)

genrule(
    name = "hello_multiple_outputs_net",
    outs = [
        "hello_world_1_net.txt",
        "hello_world_2_net.txt",
    ],
    tools = [
        ":hello_tool_net",
    ],
    cmd = "$(location :hello_tool_net) $(OUTS)",
)

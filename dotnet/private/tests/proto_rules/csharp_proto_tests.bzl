"C# proto and gRPC rule analysis tests"

load("@rules_proto//proto:defs.bzl", "proto_library")
load("//dotnet:proto.bzl", "csharp_grpc_library", "csharp_proto_library")
load("//dotnet/private/tests:utils.bzl", "action_args_substring_test")

# buildifier: disable=function-docstring
# buildifier: disable=unnamed-macro
def csharp_proto_tests():
    # Create a proto_library from the test proto file
    proto_library(
        name = "test_proto",
        srcs = ["test.proto"],
        tags = ["manual"],
    )

    # Test: csharp_proto_library creates a CSharpProtoGen action
    csharp_proto_library(
        name = "test_csharp_proto",
        proto = ":test_proto",
        target_frameworks = ["net8.0"],
        deps = [],
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "csharp_proto_gen_action_test",
        target_under_test = ":test_csharp_proto",
        action_mnemonic = "CSharpProtoGen",
        expected_arg_substrings = ["--csharp_out="],
    )

    action_args_substring_test(
        name = "csharp_proto_compile_action_test",
        target_under_test = ":test_csharp_proto",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["/nowarn:CS1591"],
    )

    # Test: csharp_grpc_library creates a CSharpProtoGen action with grpc plugin
    csharp_grpc_library(
        name = "test_csharp_grpc",
        proto = ":test_proto",
        target_frameworks = ["net8.0"],
        deps = [],
        tags = ["manual"],
    )

    action_args_substring_test(
        name = "csharp_grpc_gen_action_test",
        target_under_test = ":test_csharp_grpc",
        action_mnemonic = "CSharpProtoGen",
        expected_arg_substrings = [
            "--csharp_out=",
            "--grpc_out=",
        ],
    )

    action_args_substring_test(
        name = "csharp_grpc_compile_action_test",
        target_under_test = ":test_csharp_grpc",
        action_mnemonic = "CSharpCompile",
        expected_arg_substrings = ["/nowarn:CS1591"],
    )

load("@io_bazel_rules_dotnet//dotnet/private:rules/test.bzl", "dotnet_nunit_test")

dotnet_nunit_test(
    name = "MyTest",
    srcs = [
        "MyTest.cs",
    ],
    deps = [
        "//examples/example_lib:MyClass",
        "//dotnet/externals/nunit2:nunit.framework",
    ],
)

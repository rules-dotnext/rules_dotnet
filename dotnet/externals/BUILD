package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "core_library", "core_resource")

core_library(
    name = "xunit.abstractions.dll",
    srcs = glob(["abstractions.xunit/src/xunit.abstractions/**/*.cs"]),
    visibility = ["//visibility:public"],
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
    ]
)


filegroup(
  name = "common_core_files",
  srcs = [
    ":xunit/src/common/ExceptionExtensions.cs",
    ":xunit/src/common/Guard.cs",
    ":xunit/src/common/TestMethodDisplay.cs",
    ":assert.xunit/Sdk/ArgumentFormatter.cs",
    ":assert.xunit/Sdk/AssertEqualityComparer.cs",
    ":assert.xunit/Sdk/AssertEqualityComparerAdapter.cs",     
  ],
)

core_resource(
    name = "xunit_core_rd",
    src = ":xunit/src/xunit.core/Resources/xunit.core.rd.xml",
    identifier = "Resources.xunit.core.rd.xml"
)

core_library(
    name = "xunit.core.dll",
    srcs = [":common_core_files"] + glob(["xunit/src/xunit.core/**/*.cs"]),
    defines = ["XUNIT_FRAMEWORK"],
    resources = [":xunit_core_rd"],
    visibility = ["//visibility:public"],
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
        ":xunit.abstractions.dll",
    ]
)

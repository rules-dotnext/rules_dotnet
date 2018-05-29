package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "core_library", "core_resource", "core_binary")

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

filegroup(
  name = "common_utility_files",
  srcs = [
    ":xunit/src/common/AssemblyExtensions.cs",
    ":xunit/src/common/CommonTasks.cs",
    ":xunit/src/common/ConcurrentDictionary.cs",
    ":xunit/src/common/ConsoleHelper.cs",
    ":xunit/src/common/DictionaryExtensions.cs",
    ":xunit/src/common/ExceptionExtensions.cs",
    ":xunit/src/common/ExceptionUtility.cs",
    ":xunit/src/common/Guard.cs",
    ":xunit/src/common/Json.cs",
    #":xunit/src/common/LongLivedMarshalByRefObject.cs",
    ":xunit/src/common/NewReflectionExtensions.cs",
    ":xunit/src/common/NullMessageSink.cs",
    ":xunit/src/common/SerializationHelper.cs",
    ":xunit/src/common/SourceInformation.cs",
    ":xunit/src/common/TestMethodDisplay.cs",
    ":xunit/src/common/TestOptionsNames.cs",
    ":xunit/src/common/XunitSerializationInfo.cs",
    ":xunit/src/common/XunitWorkerThread.cs",
  ] + glob(["xunit/src/common/Microsoft.DotNet.PlatformAbstractions/**/*.cs"]) +
    glob(["xunit/src/common/Microsoft.Extensions.DependencyModel/**/*.cs"]) + 
    glob(["xunit/src/messages/**/*.cs"]),     
)

core_library(
    name = "xunit.runner.utility.dll",
    srcs = [":common_utility_files"] + glob(["xunit/src/xunit.runner.utility/**/*.cs"]),
    defines = ["NETCOREAPP1_0"],
    visibility = ["//visibility:public"],
    unsafe = True,
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.Extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.Concurrent.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Net.Http.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Tasks.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Thread.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.XDocument.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.FileSystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Text.RegularExpressions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.InteropServices.RuntimeInformation.dll",
        ":xunit.abstractions.dll",
    ]
)

core_library(
    name = "xunit.runner.reporters.dll",
    srcs = [":xunit/src/common/XunitWorkerThread.cs"] + glob(["xunit/src/xunit.runner.reporters/**/*.cs"]),
    defines = ["XUNIT_FRAMEWORK", "NETCOREAPP1_0"],
    visibility = ["//visibility:public"],
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.Extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.Concurrent.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Net.Http.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Net.Primitives.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Tasks.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Thread.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.Uri.dll",
        ":xunit.abstractions.dll",
        ":xunit.runner.utility.dll",
    ]
)

filegroup(
  name = "common_console_files",
  srcs = [
    ":xunit/src/common/AssemblyExtensions.cs",
    ":xunit/src/common/ConsoleHelper.cs",
    ":xunit/src/common/DictionaryExtensions.cs",
    ":xunit/src/common/Guard.cs",
    ":xunit/src/common/Json.cs",
  ]
)

core_resource(
    name = "HTML_xslt",
    src = ":xunit/src/xunit.console/HTML.xslt",
)

core_resource(
    name = "NUnitXml_xslt",
    src = ":xunit/src/xunit.console/NUnitXml.xslt",
)

core_resource(
    name = "xUnit1_xslt",
    src = ":xunit/src/xunit.console/xUnit1.xslt",
)

core_binary(
    name = "xunit.console.dll",
    srcs = [":common_console_files"] + glob(["xunit/src/xunit.console/**/*.cs"]),
    defines = ["NETCOREAPP1_0"],
    resources = [":HTML_xslt", ":NUnitXml_xslt", ":xUnit1_xslt"],
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.Extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.Concurrent.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Net.Http.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Net.Primitives.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Tasks.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Thread.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.Uri.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.XDocument.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.Xml.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.FileSystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.InteropServices.RuntimeInformation.dll",
        ":xunit.runner.reporters.dll",
        ":xunit.runner.utility.dll",
        ":xunit.abstractions.dll",
    ]
)

filegroup(
  name = "common_execution_files",
  srcs = [
    ":xunit/src/common/AssemblyExtensions.cs",
    ":xunit/src/common/CommonTasks.cs",
    ":xunit/src/common/DictionaryExtensions.cs",
    ":xunit/src/common/ExceptionExtensions.cs",
    ":xunit/src/common/ExceptionUtility.cs",
    ":xunit/src/common/ExecutionHelper.cs",
    ":xunit/src/common/Guard.cs",
    ":xunit/src/common/LongLivedMarshalByRefObject.cs",
    ":xunit/src/common/NewReflectionExtensions.cs",
    ":xunit/src/common/NullMessageSink.cs",
    ":xunit/src/common/SerializationHelper.cs",
    ":xunit/src/common/SourceInformation.cs",
    ":xunit/src/common/TestOptionsNames.cs",
    ":xunit/src/common/XunitSerializationInfo.cs",
    ":xunit/src/common/XunitWorkerThread.cs",
    ":assert.xunit/Sdk/ArgumentFormatter.cs",
    ":assert.xunit/Sdk/AssertEqualityComparer.cs",
    ":assert.xunit/Sdk/AssertEqualityComparerAdapter.cs",
  ] + glob(["xunit/src/messages/**/*.cs"]),
)

core_library(
    name = "xunit.execution.dll",
    srcs = [":common_execution_files"] + glob(["xunit/src/xunit.execution/**/*.cs"]),
    defines = ["NETSTANDARD1_1", "XUNIT_FRAMEWORK"],
    visibility = ["//visibility:public"],
    unsafe = True,
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.Extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.Expressions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.Concurrent.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Net.Http.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Tasks.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Thread.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.XDocument.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.FileSystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Text.RegularExpressions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.InteropServices.RuntimeInformation.dll",
        ":xunit.core.dll",
        ":xunit.abstractions.dll",
    ]
)

load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "core_binary")

core_binary(
    name = "nuget2bazel",
    srcs = glob(["*.cs"]),
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Runtime.Extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Console.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Private.CoreLib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Threading.Tasks.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.IO.FileSystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:netstandard.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Collections.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Security.Cryptography.Primitives.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Xml.XDocument.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Globalization.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Reflection.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:System.Reflection.Extensions.dll",
        "@nuget.frameworks//:core",
        "@nuget.common//:core",
        "@nuget.configuration//:core",
        "@nuget.packagemanagement//:core",
        "@nuget.packaging//:core",
        "@nuget.packaging.core//:core",
        "@nuget.protocol//:core",
        "@nuget.versioning//:core",
        "@nuget.resolver//:core",
        "@commandlineparser//:core",
        "@newtonsoft.json//:core"
    ]
)

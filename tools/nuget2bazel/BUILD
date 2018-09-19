load("@io_bazel_rules_dotnet//dotnet:defs.bzl", "core_binary")

core_binary(
    name = "nuget2bazel",
    srcs = glob(["*.cs"]),
    deps = [
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.runtime.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.runtime.extensions.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.console.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.private.corelib.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.xml.linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.threading.tasks.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.io.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.io.filesystem.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:netstandard.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.collections.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.security.cryptography.primitives.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.linq.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.xml.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.xml.xdocument.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.text.encoding.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.io.filesystem.primitives.dll",       
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.core.dll",
        "@io_bazel_rules_dotnet//dotnet/stdlib.core:system.dll",
        "@nuget.frameworks//:core",
        "@nuget.common//:core",
        "@nuget.configuration//:core",
        "@nuget.packagemanagement//:core",
        "@nuget.packaging//:core",
        "@nuget.packaging.core//:core",
        "@nuget.protocol//:core",
        "@nuget.projectmodel//:core",
        "@nuget.versioning//:core",
        "@nuget.resolver//:core",
        "@commandlineparser//:core",
        "@newtonsoft.json//:core"
    ]
)

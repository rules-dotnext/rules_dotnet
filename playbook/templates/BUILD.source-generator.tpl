load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

# Source generators / analyzers MUST target netstandard2.0
csharp_library(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = ["netstandard2.0"],
    is_analyzer = True,
    is_language_specific_analyzer = True,
    deps = [
        {{DEPS}}
        "@nuget//microsoft.codeanalysis.csharp",
        "@nuget//microsoft.codeanalysis.analyzers",
    ],
    visibility = ["//visibility:public"],
)

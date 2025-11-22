load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary", "razor_library")

razor_library(
    name = "{{TARGET_NAME}}_razor",
    srcs = glob(["**/*.cshtml", "**/*.razor"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [{{RAZOR_DEPS}}],
)

csharp_binary(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    project_sdk = "web",
    deps = [
        ":{{TARGET_NAME}}_razor",
        {{DEPS}}
    ],
    {{#APPSETTINGS}}appsetting_files = [{{APPSETTINGS}}],{{/APPSETTINGS}}
    visibility = ["//visibility:public"],
)

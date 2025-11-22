load("@rules_dotnet//dotnet:defs.bzl", "csharp_library")

csharp_library(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [{{DEPS}}],
    {{#NULLABLE}}nullable = "{{NULLABLE}}",{{/NULLABLE}}
    {{#PROJECT_SDK}}project_sdk = "{{PROJECT_SDK}}",{{/PROJECT_SDK}}
    {{#INTERNALS_VISIBLE_TO}}internals_visible_to = [{{INTERNALS_VISIBLE_TO}}],{{/INTERNALS_VISIBLE_TO}}
    {{#ALLOW_UNSAFE}}allow_unsafe_blocks = True,{{/ALLOW_UNSAFE}}
    {{#LANGVERSION}}langversion = "{{LANGVERSION}}",{{/LANGVERSION}}
    {{#DEFINES}}defines = [{{DEFINES}}],{{/DEFINES}}
    {{#RESOURCES}}resources = [{{RESOURCES}}],{{/RESOURCES}}
    {{#EXPORTS}}exports = [{{EXPORTS}}],{{/EXPORTS}}
    visibility = ["//visibility:public"],
)

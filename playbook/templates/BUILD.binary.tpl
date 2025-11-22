load("@rules_dotnet//dotnet:defs.bzl", "csharp_binary")

csharp_binary(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [{{DEPS}}],
    {{#PROJECT_SDK}}project_sdk = "{{PROJECT_SDK}}",{{/PROJECT_SDK}}
    {{#NULLABLE}}nullable = "{{NULLABLE}}",{{/NULLABLE}}
    {{#APPSETTINGS}}appsetting_files = [{{APPSETTINGS}}],{{/APPSETTINGS}}
    {{#ALLOW_UNSAFE}}allow_unsafe_blocks = True,{{/ALLOW_UNSAFE}}
    {{#LANGVERSION}}langversion = "{{LANGVERSION}}",{{/LANGVERSION}}
    {{#DEFINES}}defines = [{{DEFINES}}],{{/DEFINES}}
    {{#RESOURCES}}resources = [{{RESOURCES}}],{{/RESOURCES}}
    {{#DATA}}data = [{{DATA}}],{{/DATA}}
    visibility = ["//visibility:public"],
)

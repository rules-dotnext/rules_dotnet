load("@rules_dotnet//dotnet:defs.bzl", "csharp_library", "resx_resource")

resx_resource(
    name = "{{RESX_TARGET_NAME}}",
    src = "{{RESX_FILE}}",
)

csharp_library(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [{{DEPS}}],
    resources = [":{{RESX_TARGET_NAME}}"],
    visibility = ["//visibility:public"],
)

load("@rules_dotnet//dotnet:defs.bzl", "publish_binary")

publish_binary(
    name = "{{PUBLISH_NAME}}",
    binary = ":{{BINARY_TARGET}}",
    target_framework = "{{TARGET_FRAMEWORK}}",
    {{#SELF_CONTAINED}}self_contained = True,{{/SELF_CONTAINED}}
    visibility = ["//visibility:public"],
)

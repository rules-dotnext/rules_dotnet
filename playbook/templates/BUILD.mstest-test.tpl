load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

# MSTest — requires explicit Program.cs entry point.
csharp_test(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [
        {{DEPS}}
        "@nuget//mstest.testframework",
        "@nuget//mstest.testadapter",
        "@nuget//microsoft.net.test.sdk",
    ],
    {{#NULLABLE}}nullable = "{{NULLABLE}}",{{/NULLABLE}}
    {{#DATA}}data = [{{DATA}}],{{/DATA}}
    {{#ALLOW_UNSAFE}}allow_unsafe_blocks = True,{{/ALLOW_UNSAFE}}
)

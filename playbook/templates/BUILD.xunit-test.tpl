load("@rules_dotnet//dotnet:defs.bzl", "csharp_test")

# xUnit test — requires explicit Program.cs entry point.
# Ensure Program.cs exists with: Xunit.ConsoleClient.Program.Main(args)
csharp_test(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [
        {{DEPS}}
        "@nuget//xunit",
        "@nuget//xunit.runner.visualstudio",
        "@nuget//microsoft.net.test.sdk",
    ],
    {{#NULLABLE}}nullable = "{{NULLABLE}}",{{/NULLABLE}}
    {{#DATA}}data = [{{DATA}}],{{/DATA}}
    {{#ALLOW_UNSAFE}}allow_unsafe_blocks = True,{{/ALLOW_UNSAFE}}
)

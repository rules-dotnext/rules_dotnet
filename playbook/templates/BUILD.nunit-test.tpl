load("@rules_dotnet//dotnet:defs.bzl", "csharp_nunit_test")

# NUnit test — the macro auto-injects NUnit, NUnitLite, and shim.cs.
# Do NOT add NUnit/NUnitLite to deps. Do NOT include Program.cs in srcs.
csharp_nunit_test(
    name = "{{TARGET_NAME}}",
    srcs = glob(["**/*.cs"], exclude = ["obj/**", "bin/**", "Program.cs"]),
    target_frameworks = [{{TARGET_FRAMEWORKS}}],
    deps = [{{DEPS}}],
    {{#NULLABLE}}nullable = "{{NULLABLE}}",{{/NULLABLE}}
    {{#DATA}}data = [{{DATA}}],{{/DATA}}
    {{#ALLOW_UNSAFE}}allow_unsafe_blocks = True,{{/ALLOW_UNSAFE}}
)

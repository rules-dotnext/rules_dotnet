"""
Rules for compiling and running NUnit tests.

This rule is a macro that has the same attributes as `csharp_test`
"""

load("//dotnet/private/rules/csharp:test.bzl", "csharp_test")

# #207 — Configurable defaults via label_flags
_DEFAULT_NUNIT = Label("//dotnet/private/rules/common/nunit:nunit")
_DEFAULT_NUNITLITE = Label("//dotnet/private/rules/common/nunit:nunitlite")
_DEFAULT_SHIM = Label("//dotnet/private/rules/common/nunit:shim.cs")

def csharp_nunit_test(
        nunit = None,
        nunitlite = None,
        test_entry_point = None,
        **kwargs):
    """Compiles and runs an NUnit test.

    Args:
        nunit: Label for the NUnit framework package. Defaults to the
            label_flag at //dotnet/private/rules/common/nunit:nunit.
        nunitlite: Label for the NUnitLite runner package. Defaults to the
            label_flag at //dotnet/private/rules/common/nunit:nunitlite.
        test_entry_point: Label for a custom entry point source file.
            Defaults to the built-in NUnit shim (shim.cs).
        **kwargs: All other arguments are forwarded to csharp_test.
    """
    deps = kwargs.pop("deps", []) + [
        nunitlite or _DEFAULT_NUNITLITE,
        nunit or _DEFAULT_NUNIT,
    ]

    srcs = kwargs.pop("srcs", []) + [
        test_entry_point or _DEFAULT_SHIM,
    ]

    csharp_test(
        srcs = srcs,
        deps = deps,
        **kwargs
    )

"""Configurable C# proto compiler wrapper.

Defines the CSharpProtoCompilerInfo provider and the csharp_proto_compiler rule
that produces it. This is analogous to rules_go's GoProtoCompiler provider.
"""

CSharpProtoCompilerInfo = provider(
    doc = "Configuration for generating C# code from proto files.",
    fields = {
        "protoc": "FilesToRunProvider: The protoc compiler",
        "plugin": "FilesToRunProvider or None: The protoc plugin (e.g., grpc_csharp_plugin)",
        "plugin_name": "string: Plugin name for --plugin=protoc-gen-NAME=path",
        "protoc_plugin_name": "string: The built-in protoc plugin name (e.g., 'csharp' for --csharp_out)",
        "options": "list[string]: Extra options passed to the plugin",
        "suffixes": "list[string]: File suffixes generated per .proto (e.g., ['.cs'] or ['Grpc.cs'])",
        "deps": "list[Target]: Implicit NuGet dependencies (e.g., Google.Protobuf)",
        "exclusions": "list[string]: Proto path prefixes to skip (e.g., 'google/protobuf')",
    },
)

def _csharp_proto_compiler_impl(ctx):
    return [CSharpProtoCompilerInfo(
        protoc = ctx.attr.protoc[DefaultInfo].files_to_run,
        plugin = ctx.attr.plugin[DefaultInfo].files_to_run if ctx.attr.plugin else None,
        plugin_name = ctx.attr.plugin_name,
        protoc_plugin_name = ctx.attr.protoc_plugin_name,
        options = ctx.attr.options,
        suffixes = ctx.attr.suffixes,
        deps = ctx.attr.deps,
        exclusions = ctx.attr.exclusions,
    )]

csharp_proto_compiler = rule(
    implementation = _csharp_proto_compiler_impl,
    doc = """Configures a protoc-based C# code generator.

    This rule wraps protoc and optionally a plugin to generate C# source files
    from .proto files. It is used as the `compiler` attribute of
    `csharp_proto_library` and `csharp_grpc_library`.
    """,
    attrs = {
        "protoc": attr.label(
            doc = "The protoc compiler binary.",
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "plugin": attr.label(
            doc = "Optional protoc plugin binary (e.g., grpc_csharp_plugin).",
            executable = True,
            cfg = "exec",
        ),
        "plugin_name": attr.string(
            doc = "Name for --plugin=protoc-gen-NAME=path. Required if plugin is set.",
            default = "",
        ),
        "protoc_plugin_name": attr.string(
            doc = "Built-in protoc language plugin name (e.g., 'csharp' for --csharp_out).",
            default = "csharp",
        ),
        "options": attr.string_list(
            doc = "Extra options passed to the code generator.",
            default = [],
        ),
        "suffixes": attr.string_list(
            doc = "File suffixes generated per .proto input file.",
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "Implicit NuGet package dependencies to propagate to compiled libraries.",
        ),
        "exclusions": attr.string_list(
            doc = "Proto path prefixes to exclude from code generation (e.g., 'google/protobuf').",
            default = ["google/protobuf"],
        ),
    },
    provides = [CSharpProtoCompilerInfo],
)

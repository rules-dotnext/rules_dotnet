"""Action to invoke protoc for C# code generation."""

load(
    "@bazel_skylib//lib:paths.bzl",
    "paths",
)

def _proto_path(src, proto_info):
    """Compute the proto import path for a source file.

    Args:
        src: The proto source File.
        proto_info: The ProtoInfo provider.

    Returns:
        The import path string.
    """
    if proto_info.proto_source_root == ".":
        prefix = src.root.path + "/"
    elif proto_info.proto_source_root.startswith(src.root.path):
        prefix = proto_info.proto_source_root + "/"
    else:
        prefix = paths.join(src.root.path, proto_info.proto_source_root) + "/"

    if not src.path.startswith(prefix):
        # Handle the case where proto_source_root is empty string
        if proto_info.proto_source_root == "" or proto_info.proto_source_root == ".":
            return src.path
        return src.path
    return src.path[len(prefix):]

def _basename_to_pascal(name):
    """Convert a proto basename to PascalCase as protoc --csharp_out does.

    protoc converts snake_case filenames to PascalCase for C# output.
    e.g., "hello_world" -> "HelloWorld"

    Args:
        name: The proto file basename without extension.

    Returns:
        PascalCase string.
    """
    parts = name.split("_")
    return "".join([part.capitalize() for part in parts if part])

def csharp_proto_compile(
        actions,
        compiler_info,
        proto_info,
        out_dir_name):
    """Invoke protoc to generate C# sources from a proto_library.

    Args:
        actions: ctx.actions module.
        compiler_info: CSharpProtoCompilerInfo provider.
        proto_info: ProtoInfo provider from the proto_library.
        out_dir_name: A unique directory name for outputs.

    Returns:
        A list of generated .cs File objects.
    """
    generated_srcs = []
    proto_sources = []

    # Filter out well-known types (they're in the Google.Protobuf NuGet package)
    for src in proto_info.check_deps_sources.to_list():
        path = _proto_path(src, proto_info)
        skip = False
        for exclusion in compiler_info.exclusions:
            if path.startswith(exclusion):
                skip = True
                break
        if not skip:
            proto_sources.append(src)

    if not proto_sources:
        return []

    # Declare output files
    # protoc --csharp_out converts each foo_bar.proto to FooBar.cs (PascalCase)
    for src in proto_sources:
        basename = src.basename[:-len(".proto")]
        pascal_name = _basename_to_pascal(basename)
        for suffix in compiler_info.suffixes:
            out = actions.declare_file(
                "%s/%s%s" % (out_dir_name, pascal_name, suffix),
            )
            generated_srcs.append(out)

    # Build protoc arguments
    args = actions.args()

    # Output directory
    out_path = generated_srcs[0].dirname

    # Built-in plugin (e.g., --csharp_out)
    plugin_name = compiler_info.protoc_plugin_name
    if compiler_info.options:
        options_str = ",".join(compiler_info.options)
        args.add("--%s_out=%s:%s" % (plugin_name, options_str, out_path))
    else:
        args.add("--%s_out=%s" % (plugin_name, out_path))

    # External plugin (e.g., grpc_csharp_plugin)
    tools = []
    if compiler_info.plugin:
        args.add(
            "--plugin=protoc-gen-%s=%s" % (
                compiler_info.plugin_name,
                compiler_info.plugin.executable.path,
            ),
        )
        if compiler_info.options:
            options_str = ",".join(compiler_info.options)
            args.add("--%s_out=%s:%s" % (compiler_info.plugin_name, options_str, out_path))
        else:
            args.add("--%s_out=%s" % (compiler_info.plugin_name, out_path))
        tools.append(compiler_info.plugin)

    # Use descriptor sets for import resolution (standard Bazel proto pattern)
    descriptor_sets = proto_info.transitive_descriptor_sets
    args.add_joined(
        descriptor_sets,
        join_with = ":",
        format_joined = "--descriptor_set_in=%s",
    )

    # Add the proto source file paths (using import paths, not file system paths)
    args.add_all(
        proto_sources,
        map_each = lambda src: _proto_path(src, proto_info),
        allow_closure = True,
    )

    actions.run(
        mnemonic = "CSharpProtoGen",
        progress_message = "Generating C# proto sources for %s" % out_dir_name,
        executable = compiler_info.protoc,
        arguments = [args],
        inputs = depset(
            direct = proto_sources,
            transitive = [descriptor_sets],
        ),
        outputs = generated_srcs,
        tools = tools,
        toolchain = None,
    )

    return generated_srcs

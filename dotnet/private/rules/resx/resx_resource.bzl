"""Rule for compiling .resx files to .resources binary format."""

def _resx_resource_impl(ctx):
    outputs = []
    for src in ctx.files.srcs:
        # input: foo/Strings.resx -> output: Strings.resources
        out_name = src.basename.replace(".resx", ".resources")
        out_file = ctx.actions.declare_file(
            "{}/{}".format(ctx.attr.name, out_name),
        )
        outputs.append(out_file)

        ctx.actions.run(
            mnemonic = "ResxCompile",
            progress_message = "Compiling %s to .resources" % src.short_path,
            inputs = depset(
                direct = [src],
                transitive = [
                    ctx.attr._resx_compiler.files,
                    ctx.attr._resx_compiler.default_runfiles.files,
                ],
            ),
            outputs = [out_file],
            executable = ctx.attr._resx_compiler.files_to_run,
            arguments = [src.path, out_file.path],
        )

    return [
        DefaultInfo(files = depset(outputs)),
    ]

resx_resource = rule(
    implementation = _resx_resource_impl,
    doc = "Compiles .resx XML resource files to .resources binary format for embedding in .NET assemblies.",
    attrs = {
        "srcs": attr.label_list(
            doc = "The .resx source files to compile.",
            allow_files = [".resx"],
            mandatory = True,
        ),
        "_resx_compiler": attr.label(
            default = "//dotnet/private/tools/resx_compiler:ResxCompiler",
            executable = True,
            cfg = "exec",
        ),
    },
)

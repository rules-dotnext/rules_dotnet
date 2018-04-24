load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)

_TEMPLATE = """
const char * Exe = "{}";
"""

def _dotnet_launcher_gen_impl(ctx):
  """dotnet_launcher_gen_impl emits actions that generates .c file necessary to build launcher."""
  dotnet = dotnet_context(ctx)
  name = ctx.label.name
  exe = ctx.attr.exe.files.to_list()[0]

  generated_file = dotnet.declare_file(dotnet, "generated.c")
  content = _TEMPLATE.format(exe.path)
  dotnet.actions.write(output = generated_file, content = content, is_executable=False)

  return [
      DefaultInfo(
          files = depset([generated_file]),
      ),
  ]
  
dotnet_launcher_gen = rule(
    _dotnet_launcher_gen_impl,
    attrs = {
        "exe": attr.label(),
        "_dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:dotnet_context_data")),
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain"],
    executable = False,
    outputs = {"generated": "generated.c"}
)

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
const char * Nunit = "{}";
"""

def _dotnet_launcher_gen_impl(ctx):
  """dotnet_launcher_gen_impl emits actions that generates .c file necessary to build launcher."""
  name = ctx.label.name
  exe = ctx.attr.exe.files.to_list()[0]
  nunit = ""
  if ctx.attr.nunit:
    nunit = ctx.attr.nunit.files.to_list()[0].path
  
  generated_file = ctx.actions.declare_file("{}_generated.c".format(name))
  content = _TEMPLATE.format(exe.path, nunit)
  ctx.actions.write(output = generated_file, content = content, is_executable=False)

  return [
      DefaultInfo(
          files = depset([generated_file]),
      ),
  ]
  
dotnet_launcher_gen = rule(
    _dotnet_launcher_gen_impl,
    attrs = {
        "exe": attr.label(),
        "nunit": attr.label(),
    },
    executable = False,
)

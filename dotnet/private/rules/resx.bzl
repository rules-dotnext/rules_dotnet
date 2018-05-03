load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

def _dotnet_resx_impl(ctx):
  """dotnet_resx_impl emits actions for compiling resx to resource."""
  dotnet = dotnet_context(ctx)
  name = ctx.label.name
 
  result = dotnet.resx(dotnet,
      name = name,
      src = ctx.attr.src,
      out = ctx.attr.out,
  )
  return [
      DefaultInfo(
          files = depset([result]),
      ),
  ]
  
dotnet_resx = rule(
    _dotnet_resx_impl,
    attrs = {
        # source files for this target.
        "src": attr.label(allow_files = FileType([".resx"])),        
        "out": attr.string(),
        "_dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:dotnet_context_data"))
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain"],
    executable = False,
)
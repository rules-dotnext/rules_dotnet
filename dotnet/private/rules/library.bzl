load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)


def _dotnet_library_impl(ctx):
  """dotnet_library_impl emits actions for compiling dotnet executable assembly."""
  dotnet = dotnet_context(ctx)
  name = ctx.label.name
 
  library = dotnet.library(dotnet,
      name = name,
      srcs = ctx.attr.srcs,
      deps = ctx.attr.deps,
      out = ctx.attr.out,
      defines = ctx.attr.defines,

  )
  return [
      library,
      DefaultInfo(
          files = depset([library.result]),
      ),
  ]
  
dotnet_library = rule(
    _dotnet_library_impl,
    attrs = {
        "deps": attr.label_list(providers=[DotnetLibrary]),
        # source files for this target.
        "srcs": attr.label_list(allow_files = FileType([".cs"])),        
        "out": attr.string(),
        "defines": attr.string_list(),
        "_dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:dotnet_context_data"))
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain"],
    executable = False,
)
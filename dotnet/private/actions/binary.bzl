load(
    "@io_bazel_rules_dotnet//dotnet/private:actions/assembly.bzl",
    "emit_assembly",
)

def emit_binary(dotnet,
    name = "",
    srcs = None,
    deps = None,
    out = None,
    defines = None):

  return emit_assembly(
    dotnet = dotnet,
    name = name,
    srcs = srcs,
    deps = deps,
    out = out,
    executable = True,
    defines = defines,
  )

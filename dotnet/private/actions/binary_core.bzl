load(
    "@io_bazel_rules_dotnet//dotnet/private:actions/assembly_core.bzl",
    "emit_assembly_core",
)

def emit_binary_core(dotnet,
    name = "",
    srcs = None,
    deps = None,
    resources = None,
    out = None,
    defines = None,
    unsafe = False,
    data = None):

  return emit_assembly_core(
    dotnet = dotnet,
    name = name,
    srcs = srcs,
    deps = deps,
    resources = resources,
    out = out,
    executable = True,
    defines = defines,
    unsafe = unsafe,
    data = data,
  )

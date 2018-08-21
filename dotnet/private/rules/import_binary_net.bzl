load(
    "@io_bazel_rules_dotnet//dotnet/private:context.bzl",
    "dotnet_context",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:common.bzl",
    "sets"
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:rules/launcher_gen.bzl",
    "dotnet_launcher_gen",
)


def _net_import_binary_impl(ctx):
  """net_import_library_impl emits actions for importing an external dll (for example provided by nuget)."""
  dotnet = dotnet_context(ctx)
  name = ctx.label.name
 
  # Handle case of empty toolchain on linux and darwin
  if dotnet.library == None:
    empty = dotnet.declare_file(dotnet, path="empty.sh")
    dotnet.actions.write(output = empty, content = "echo '.net not supported on this platform'")
    return [DefaultInfo(executable = empty)]

  deps = ctx.attr.deps
  src = ctx.attr.src

  deps_libraries = [d[DotnetLibrary] for d in deps]
  transitive = sets.union(deps_libraries, *[a[DotnetLibrary].transitive for a in deps])

  library = dotnet.new_library(
    dotnet = dotnet, 
    name = name, 
    deps = deps, 
    transitive = transitive,
    result = src.files.to_list()[0])

  transitive_files = [d.result for d in library.transitive.to_list()]

  return [
      library,
      DefaultInfo(
          files = depset([library.result]),
          runfiles = ctx.runfiles(files = [dotnet.stdlib, library.result], transitive_files=depset(direct=transitive_files)),
      ),
  ]
  
_net_import_binary = rule(
    _net_import_binary_impl,
    attrs = {
        "deps": attr.label_list(providers=[DotnetLibrary]),
        "src": attr.label(allow_files = FileType([".exe"]), mandatory=True),        
        "_dotnet_context_data": attr.label(default = Label("@io_bazel_rules_dotnet//:net_context_data"))
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_net"],
    executable = False,
)

def net_import_binary(name, src, deps = []):
    _net_import_binary(name = "%s_exe" % name, deps = deps, src = src)
    exe = ":%s_exe" % name
    dotnet_launcher_gen(name = "%s_launcher" % name, exe = exe)

    native.cc_binary(
        name=name, 
        srcs = [":%s_launcher" % name],
        deps = ["@io_bazel_rules_dotnet//dotnet/tools/runner_net", "@io_bazel_rules_dotnet//dotnet/tools/common"],
        data = [exe],
    )
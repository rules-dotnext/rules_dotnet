load(
    "@io_bazel_rules_dotnet//dotnet/private:providers.bzl",
    "DotnetLibrary",
)

load(
    "@io_bazel_rules_dotnet//dotnet/private:common.bzl",
    "executable_extension",
    "paths",
)


DotnetContext = provider()

def _get_dotnet_runner(context_data, ext):
  for f in context_data._bin.files:
    basename = paths.basename(f.path)
    if basename != "mono" + ext:
      continue
    return f
  fail("Could not find mono executable in dotnet_sdk (bin)")

def _get_dotnet_mcs(context_data):
  for f in context_data._bin.files:
    basename = paths.basename(f.path)
    if basename != "mcs.exe":
      continue
    return f

  for f in context_data._lib.files:
    basename = paths.basename(f.path)
    if basename != "mcs.exe":
      continue
    return f
  fail("Could not find mcs.exe in dotnet_sdk (bin, lib")

def _declare_file(dotnet, path):
  return dotnet.actions.declare_file(path)


def _new_library(dotnet, name=None, deps=None, **kwargs):
  return DotnetLibrary(
      name = dotnet.label.name if not name else name,
      label = dotnet.label,
      deps = deps,
      **kwargs
  )


def dotnet_context(ctx, attr=None):
  toolchain = ctx.toolchains["@io_bazel_rules_dotnet//dotnet:toolchain"]

  if not attr:
    attr = ctx.attr

  context_data = attr._dotnet_context_data 
  ext = ""
  if toolchain.default_dotnetos == "windows":
    ext = ".exe"
  runner = _get_dotnet_runner(context_data, ext)
  mcs = _get_dotnet_mcs(context_data)

  return DotnetContext(
      # Fields
      label = ctx.label,
      toolchain = toolchain,
      actions = ctx.actions,
      binary = toolchain.actions.binary,      
      library = toolchain.actions.library,
      exe_extension = ext,
      runner = runner,
      mcs = mcs,
      declare_file = _declare_file,
      new_library = _new_library,
  )

def _dotnet_context_data(ctx):
  return struct(
      _bin = ctx.attr._bin,
      _lib = ctx.attr._lib
  )

dotnet_context_data = rule(
    _dotnet_context_data,
    attrs = {
        "_bin": attr.label(
            allow_files = True,
            default="@dotnet_sdk//:bin",
        ),
        "_lib": attr.label(
            allow_files = True,
            default="@dotnet_sdk//:lib",
        ),
    },
)
  

load(":dotnet.coverlet.bzl", _coverlet = "coverlet")

def _coverlet_impl(module_ctx):
    _coverlet()
    return module_ctx.extension_metadata(reproducible = True)

coverlet_extension = module_extension(
    implementation = _coverlet_impl,
)

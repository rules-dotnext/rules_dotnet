"""Module extension wrapper for parity app NuGet packages."""

load(":paket.parity.bzl", _parity = "parity")

def _parity_impl(module_ctx):
    _parity()
    return module_ctx.extension_metadata(reproducible = True)

parity_nuget = module_extension(
    implementation = _parity_impl,
)

"""Module extension wrapper for booking validation NuGet packages."""

load(":paket.booking.bzl", _booking = "booking")

def _booking_impl(module_ctx):
    _booking()
    return module_ctx.extension_metadata(reproducible = True)

booking_nuget = module_extension(
    implementation = _booking_impl,
)

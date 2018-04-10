load("@io_bazel_rules_dotnet//dotnet/private:common.bzl", "executable_extension", "bat_extension")

def _dotnet_host_sdk_impl(ctx):
  mono, mcs = _detect_host_sdk(ctx)
  _sdk_build_file(ctx)
  bin = ctx.path(mcs).dirname
  ctx.symlink(bin, "bin")

dotnet_host_sdk = repository_rule(
    implementation = _dotnet_host_sdk_impl, 
    local=True,
)


def _dotnet_download_sdk_impl(ctx):
  if ctx.os.name == 'linux':
    host = "mono_linux_amd64"
  elif ctx.os.name == 'mac os x':
    host = "mono_darwin_amd64"
  elif ctx.os.name.startswith('windows'):
    host = "mono_windows_amd64"
  else:
    fail("Unsupported operating system: " + ctx.os.name)
  sdks = ctx.attr.sdks
  if host not in sdks: fail("Unsupported host {}".format(host))
  filename, sha256 = ctx.attr.sdks[host]
  _sdk_build_file(ctx)
  _remote_sdk(ctx, [filename], ctx.attr.strip_prefix, sha256)

dotnet_download_sdk = repository_rule(
    _dotnet_download_sdk_impl,
    attrs = {
        "sdks": attr.string_list_dict(),
        "urls": attr.string_list(),
        "strip_prefix": attr.string(default = ""),
    },
)

def _dotnet_local_sdk_impl(ctx):
  _sdk_build_file(ctx)
  ctx.symlink(ctx.attr.path + "/bin", "bin")

dotnet_local_sdk = repository_rule(
    _dotnet_local_sdk_impl,
    attrs = {
        "path": attr.string(),
    },
)
'''
def _go_sdk_impl(ctx):
  urls = ctx.attr.urls
  if ctx.attr.url:
    print("DEPRECATED: use urls instead of url on go_sdk, {}".format(ctx.attr.url))
    urls = [ctx.attr.url] + urls
  if urls:
    if ctx.attr.path:
      fail("url and path cannot both be set on go_sdk, got {} and {}".format(urls, ctx.attr.path))
    _sdk_build_file(ctx)
    _remote_sdk(ctx, urls, ctx.attr.strip_prefix, ctx.attr.sha256)
  elif ctx.attr.path:
    print("DEPRECATED: go_sdk with a path, please use go_local_sdk")
    _sdk_build_file(ctx)
    _local_sdk(ctx, ctx.attr.path)
  else:
    print("DEPRECATED: go_sdk without path or urls, please use go_host_sdk")
    path = _detect_host_sdk(ctx)
    _sdk_build_file(ctx)
    _local_sdk(ctx, path)
  _prepare(ctx)

go_sdk = repository_rule(
    implementation = _go_sdk_impl,
    attrs = {
        "path": attr.string(),
        "url": attr.string(),
        "urls": attr.string_list(),
        "strip_prefix": attr.string(default = "go"),
        "sha256": attr.string(),
    },
)
"""See /go/toolchains.rst#go-sdk for full documentation."""

'''
def _remote_sdk(ctx, urls, strip_prefix, sha256):
  ctx.download_and_extract(
      url = urls,
      stripPrefix = strip_prefix,
      sha256 = sha256,
  )

def _sdk_build_file(ctx):
  ctx.file("ROOT")
  ctx.template("BUILD.bazel",
      Label("@io_bazel_rules_dotnet//dotnet/private:BUILD.sdk.bazel"),
      executable = False,
  )


def _detect_host_sdk(ctx):
  mcs = ctx.which("mcs" + bat_extension(ctx))
  if not mcs:
     fail("Failed to find mcs")
  
  mono = ctx.which("mono" + executable_extension(ctx))
  if not mono:
     fail("Failed to find mono")

  return (mono, mcs)


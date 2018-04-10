# Copyright 2016 The Bazel Go Rules Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Toolchain rules used by dotnet.
"""

'''
load("@io_bazel_rules_go//go/private:actions/archive.bzl", "emit_archive")
load("@io_bazel_rules_go//go/private:actions/asm.bzl", "emit_asm")
load("@io_bazel_rules_go//go/private:actions/binary.bzl", "emit_binary")
load("@io_bazel_rules_go//go/private:actions/compile.bzl", "emit_compile")
load("@io_bazel_rules_go//go/private:actions/cover.bzl", "emit_cover")
load("@io_bazel_rules_go//go/private:actions/link.bzl", "emit_link")
load("@io_bazel_rules_go//go/private:actions/pack.bzl", "emit_pack")

'''
def _dotnet_toolchain_impl(ctx):
  return [platform_common.ToolchainInfo(
      name = ctx.label.name,
      default_dotnetimpl = ctx.attr.dotnetimpl,
      default_dotnetos = ctx.attr.dotnetos,
      default_dotnetarch = ctx.attr.dotnetarch,
      actions = struct(
#          pack = emit_pack,
      ),
      flags = struct(
          compile = (),
      ),
  )]

_dotnet_toolchain = rule(
    _dotnet_toolchain_impl,
    attrs = {
        # Minimum requirements to specify a toolchain
        "dotnetimpl": attr.string(mandatory = True),
        "dotnetos": attr.string(mandatory = True),
        "dotnetarch": attr.string(mandatory = True),
    },
)

def dotnet_toolchain(name, host, constraints=[], **kwargs):
  """See dotnet/toolchains.rst#dotnet-toolchain for full documentation."""

  impl, os, arch = host.partition("_")
  host_constraints = constraints + [
    "@io_bazel_rules_dotnet//dotnet/toolchain:" + impl,
    "@io_bazel_rules_dotnet//dotnet/toolchain:" + os,
    "@io_bazel_rules_dotnet//dotnet/toolchain:" + arch,
  ]

  impl_name = name + "-impl"
  _dotnet_toolchain(
      name = impl_name,
      dotnetimpl = impl,
      dotnetos = os,
      dotnetarch = arch,
      tags = ["manual"],
      visibility = ["//visibility:public"],
      **kwargs
  )
  native.toolchain(
      name = name,
      toolchain_type = "@io_bazel_rules_dotnet//dotnet:toolchain",
      exec_compatible_with = host_constraints,
      target_compatible_with = host_constraints,
      toolchain = ":"+impl_name,
  )

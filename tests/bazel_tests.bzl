load("@io_bazel_rules_dotnet//dotnet/private:common.bzl", "env_execute")

# _bazelrc is the bazel.rc file that sets the default options for tests
_bazelrc = """
build --verbose_failures
build --sandbox_debug
build --test_output=errors
build --spawn_strategy=standalone
build --genrule_strategy=standalone

test --test_strategy=standalone
test --nocache_test_results

build:isolate --
build:fetch --fetch=True
"""

# _env_build_template is the template for the bazel test environment repository build file
_env_build_template = """
load("@io_bazel_rules_go//tests:bazel_tests.bzl", "bazel_test_settings")
bazel_test_settings(
  name = "settings",
  bazel = "{bazel}",
  exec_root = "{exec_root}",
  scratch_dir = "{scratch_dir}",
  visibility = ["//visibility:public"],
)
filegroup(
  name = "bazelrc",
  srcs = ["test.bazelrc"],
  visibility = ["//visibility:public"],
)
"""

def _test_environment_impl(ctx):
  # Find bazel
  bazel = ""
  if "BAZEL" in ctx.os.environ:
    bazel = ctx.os.environ["BAZEL"]
  elif "BAZEL_VERSION" in ctx.os.environ:
    home = ctx.os.environ["HOME"]
    bazel = home + "/.bazel/{0}/bin/bazel".format(ctx.os.environ["BAZEL_VERSION"])
  if bazel == "" or not ctx.path(bazel).exists:
    bazel = ctx.which("bazel")

  # Get a temporary directory to use as our scratch workspace
  if ctx.os.name.startswith('windows'):
    scratch_dir = ctx.os.environ["TMP"].replace("\\","/") + "/bazel_go_test"
  else:
    result = env_execute(ctx, ["mktemp", "-d"])
    if result.return_code:
      fail("failed to create temporary directory for bazel tests: {}".format(result.stderr))
    scratch_dir = result.stdout.strip()

  # Work out where we are running so we can find externals
  exec_root, _, _ = str(ctx.path(".")).rpartition("/external/")

  # build the basic environment
  ctx.file("WORKSPACE", 'workspace(name = "{}")'.format(ctx.name))
  ctx.file("BUILD.bazel", _env_build_template.format(
      bazel = bazel,
      exec_root = exec_root,
      scratch_dir = scratch_dir,
  ))
  ctx.file("test.bazelrc", content=_bazelrc)

_test_environment = repository_rule(
    implementation = _test_environment_impl,
    attrs = {},
    environ = [
        "BAZEL",
        "BAZEL_VERSION",
        "HOME",
    ],
)


def test_environment():
  _test_environment(name="bazel_test")

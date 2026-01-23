"NuGet lock file parser tests"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//dotnet/private/rules/nuget:nuget_lock.bzl", "parse_nuget_lock_file")

_TEST_LOCK_CONTENT = """\
{
  "version": 1,
  "dependencies": {
    "net8.0": {
      "Newtonsoft.Json": {
        "type": "Direct",
        "requested": "[13.0.3, )",
        "resolved": "13.0.3",
        "contentHash": "HdGzkoOHnq8YKRZ4qzQ",
        "nupkgSha512": "sha512-abc123"
      },
      "System.Memory": {
        "type": "Transitive",
        "resolved": "4.5.5",
        "contentHash": "abcdef",
        "nupkgSha512": "sha512-def456"
      }
    }
  }
}
"""

_TEST_SOURCES = ["https://api.nuget.org/v3/index.json"]

def _parse_returns_correct_count_test_impl(ctx):
    env = unittest.begin(ctx)
    packages = parse_nuget_lock_file(_TEST_LOCK_CONTENT, _TEST_SOURCES)
    asserts.equals(env, 2, len(packages))
    return unittest.end(env)

parse_returns_correct_count_test = unittest.make(_parse_returns_correct_count_test_impl)

def _parse_package_fields_test_impl(ctx):
    env = unittest.begin(ctx)
    packages = parse_nuget_lock_file(_TEST_LOCK_CONTENT, _TEST_SOURCES)

    # Convert to a dict keyed by lowercase name for stable lookup
    by_name = {pkg["name"].lower(): pkg for pkg in packages}

    # Verify Newtonsoft.Json
    newtonsoft = by_name["newtonsoft.json"]
    asserts.equals(env, "Newtonsoft.Json", newtonsoft["name"])
    asserts.equals(env, "13.0.3", newtonsoft["version"])
    asserts.equals(env, "sha512-abc123", newtonsoft["sha512"])
    asserts.equals(env, _TEST_SOURCES, newtonsoft["sources"])

    # Verify System.Memory
    sysmem = by_name["system.memory"]
    asserts.equals(env, "System.Memory", sysmem["name"])
    asserts.equals(env, "4.5.5", sysmem["version"])
    asserts.equals(env, "sha512-def456", sysmem["sha512"])

    return unittest.end(env)

parse_package_fields_test = unittest.make(_parse_package_fields_test_impl)

def _parse_missing_hash_test_impl(ctx):
    """Packages without nupkgSha512 should get an empty string for sha512."""
    env = unittest.begin(ctx)

    lock_content = """\
{
  "version": 1,
  "dependencies": {
    "net8.0": {
      "SomePackage": {
        "type": "Direct",
        "requested": "[1.0.0, )",
        "resolved": "1.0.0",
        "contentHash": "xyz"
      }
    }
  }
}
"""
    packages = parse_nuget_lock_file(lock_content, _TEST_SOURCES)
    asserts.equals(env, 1, len(packages))

    pkg = packages[0]
    asserts.equals(env, "SomePackage", pkg["name"])
    asserts.equals(env, "1.0.0", pkg["version"])
    asserts.equals(env, "", pkg["sha512"])

    return unittest.end(env)

parse_missing_hash_test = unittest.make(_parse_missing_hash_test_impl)

def _parse_dependencies_per_tfm_test_impl(ctx):
    """Dependencies should be recorded per-TFM."""
    env = unittest.begin(ctx)

    lock_content = """\
{
  "version": 1,
  "dependencies": {
    "net8.0": {
      "MyPkg": {
        "type": "Direct",
        "requested": "[2.0.0, )",
        "resolved": "2.0.0",
        "contentHash": "abc",
        "nupkgSha512": "sha512-hash1",
        "dependencies": {
          "DepA": "1.0.0",
          "DepB": "2.0.0"
        }
      }
    }
  }
}
"""
    packages = parse_nuget_lock_file(lock_content, _TEST_SOURCES)
    asserts.equals(env, 1, len(packages))

    pkg = packages[0]
    asserts.true(env, "net8.0" in pkg["dependencies"])
    asserts.equals(env, sorted(["DepA", "DepB"]), sorted(pkg["dependencies"]["net8.0"]))

    return unittest.end(env)

parse_dependencies_per_tfm_test = unittest.make(_parse_dependencies_per_tfm_test_impl)

def nuget_lock_test_suite(name):
    unittest.suite(
        name,
        parse_returns_correct_count_test,
        parse_package_fields_test,
        parse_missing_hash_test,
        parse_dependencies_per_tfm_test,
    )

# How to Contribute

Want to contribute? Great! First, read this page!

## Formatting

Starlark files should be formatted by
[buildifier](https://github.com/bazelbuild/buildtools/tree/master/buildifier).

## Updating BUILD files

Some targets are generated from sources.
Currently this is just the `bzl_library` targets.
Run `bazel run //:gazelle` to keep them up-to-date.

## Using this as a development dependency of other rules

To override the released version of rules_dotnet with a local checkout,
add a `local_path_override` to the consuming module's `MODULE.bazel`:

```starlark
local_path_override(
    module_name = "rules_dotnet",
    path = "/path/to/your/rules_dotnet",
)
```

## Running tests

To run and build all tests simply run `bazel test //...`
To build and test all examples run `cd examples && bazel test //...`

## Releasing

1. Determine the next release version, following semver (could automate in the future from changelog)
1. Tag the repo and push it (or create a tag in GH UI)
1. Watch the automation run on GitHub actions

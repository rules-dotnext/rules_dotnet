# paket2bazel

`paket2bazel` is a tool for parsing [Paket](https://fsprojects.github.io/Paket/) dependencies files.

Paket fits well with Bazel because it generates a `paket.lock` file that can be used
to deterministically generate Bazel targets for NuGet packages.

## How to use

First you need to set up your `paket.dependencies` and `paket.lock` file. See the [Paket docs](https://fsprojects.github.io/Paket/) on how to get started with Paket.

Then run `paket2bazel` to generate a `.bzl` file with NuGet repository rules:

```sh
bazel run @rules_dotnet//tools/paket2bazel -- \
    --dependencies-file $(pwd)/paket.dependencies \
    --output-folder $(pwd)/deps
```

Load the generated extension in your `MODULE.bazel`:

```starlark
paket_main = use_extension("//:deps/paket.main_extension.bzl", "paket_main_extension")
use_repo(paket_main, "paket.main")
```

Once set up, reference each package by its lowercased name:

```starlark
deps = ["@paket.main//newtonsoft.json"]
```

If you are using groups in your `paket.dependencies` file:

```starlark
deps = ["@paket.groupname//package.name"]
```

A full example can be seen in the `examples/paket` directory in this repository.

load(
    "@rules_dotnet//dotnet:defs.bzl",
    "fsharp_binary",
    "fsharp_library",
    "fsharp_nunit_test",
)

fsharp_binary(
    name = "hello",
    srcs = ["hello.fs"],
    target_frameworks = ["net6.0"],
    deps = [
        ":lib",
        "@FSharp.Core//:FSharp.Core",
    ],
)

fsharp_nunit_test(
    name = "lib_test",
    srcs = ["libtest.fs"],
    target_frameworks = ["net6.0"],
    deps = [
        ":lib",
        "@FSharp.Core//:FSharp.Core",
    ],
)

fsharp_library(
    name = "lib",
    srcs = ["lib.fs"],
    internals_visible_to = ["lib_test"],
    target_frameworks = ["net6.0"],
    deps = ["@FSharp.Core//:FSharp.Core"],
)

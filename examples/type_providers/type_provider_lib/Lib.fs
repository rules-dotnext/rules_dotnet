module Lib
  open FSharp.Data

  type FooJson =
    // NOTE: The file is resolved relative to the WORKSPACE root!
    JsonProvider<"./type_provider_lib/foo.json", SampleIsList=false, InferTypesFromValues=true>

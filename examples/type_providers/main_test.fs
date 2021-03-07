module type_provider

open Lib
open Xunit
open System

[<Fact>]
let ``CheckVersion`` () =
  let json = "{ \"foo\": [ 1, 2, 3 ] }"
  let p = Lib.FooJson.Parse json
  let list = Array.toSeq p.Foo
  Assert.Equal([1;2;3], list)
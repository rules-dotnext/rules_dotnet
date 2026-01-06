/// F# signature file — exercises spec-fsharp #500 (.fsi support).
namespace ParityApp.FSharp

[<Sealed>]
type Calculator =
    static member Add : x:int -> y:int -> int

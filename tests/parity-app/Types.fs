/// F# implementation matching signature — exercises spec-fsharp #500, #315.
namespace ParityApp.FSharp

[<Sealed>]
type Calculator =
    static member Add (x: int) (y: int) = x + y

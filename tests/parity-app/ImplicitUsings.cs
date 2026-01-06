namespace ParityApp;

/// <summary>
/// This file has NO 'using' directives. It compiles only when
/// implicit_usings = True works (spec-correctness #436).
/// Console and String require 'using System;' without implicit usings.
/// </summary>
public static class ImplicitGreeter
{
    public static void Greet(string name) => Console.WriteLine($"Hello, {name}!");
    public static string Format(string s) => String.Concat("[", s, "]");
}

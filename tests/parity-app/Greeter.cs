using System;
using System.Resources;

namespace ParityApp;

/// <summary>
/// Core library exercising: version attribute (#423), resx resources (#466).
/// </summary>
public class Greeter
{
    public static string Hello(string name) => $"Hello, {name}!";

    public static string FromResources()
    {
        var rm = new ResourceManager("ParityApp.Greeter", typeof(Greeter).Assembly);
        return rm.GetString("Greeting") ?? "missing";
    }
}

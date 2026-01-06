using System;
using System.IO;

namespace ParityApp;

/// <summary>
/// Main application — exercises:
///   spec-quick-wins #490 (appsettings directory preservation)
///   spec-quick-wins #526 (appsettings.json available at runtime)
///   spec-correctness #523 (runtime dedup with mixed TFM deps)
/// </summary>
public class Program
{
    public static int Main()
    {
        // Exercise versioned lib (#423)
        Console.WriteLine(Greeter.Hello("Parity"));

        // Exercise resx resources (#466)
        Console.WriteLine(Greeter.FromResources());

        // Exercise F# interop (#315, #500)
        var sum = ParityApp.FSharp.Calculator.Add(2, 3);
        Console.WriteLine($"F# Add: 2+3={sum}");

        // Exercise native interop (#349)
        var nsum = NativeMath.Add(4, 5);
        Console.WriteLine($"Native Add: 4+5={nsum}");

        // Exercise appsettings at runtime (#490, #526)
        // The file must be in runfiles with preserved directory structure
        var appSettings = Path.Combine(
            AppContext.BaseDirectory, "appsettings.json");
        if (!File.Exists(appSettings))
        {
            Console.Error.WriteLine($"FAIL: appsettings.json not found at {appSettings}");
            return 1;
        }

        var devSettings = Path.Combine(
            AppContext.BaseDirectory, "config", "env", "appsettings.Development.json");
        if (!File.Exists(devSettings))
        {
            Console.Error.WriteLine($"FAIL: nested appsettings not found at {devSettings}");
            return 1;
        }

        Console.WriteLine("All runtime checks passed.");
        return 0;
    }
}

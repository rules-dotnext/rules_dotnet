using System;

namespace ParityApp;

/// <summary>
/// Code that passes StyleCop analysis — exercises spec-static-analysis parity.
/// If this compiles with dotnet_analysis_config enforcing StyleCop,
/// then Roslyn analyzer integration works.
/// </summary>
public static class CleanCode
{
    /// <summary>
    /// Returns a value with no analyzer violations.
    /// </summary>
    /// <returns>A clean string.</returns>
    public static string GetValue() => "clean";
}

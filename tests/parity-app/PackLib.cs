namespace ParityApp.Pack;

/// <summary>
/// Library intended to be packed into a .nupkg — exercises spec-publishing #527.
/// If dotnet_pack produces a valid .nupkg from this, pack support works.
/// </summary>
public static class PackableClass
{
    /// <summary>
    /// Returns the library version.
    /// </summary>
    public static string Version => "1.0.0";
}

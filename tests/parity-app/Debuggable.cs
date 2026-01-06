using System;

namespace ParityApp;

/// <summary>
/// Library with pathmap — exercises spec-ide-integration #228.
/// When compiled with pathmap, PDB contains workspace-relative paths
/// so debugger breakpoints work in VS Code / Rider.
/// </summary>
public static class Debuggable
{
    public static int Compute(int x)
    {
        // A debugger should be able to set a breakpoint here
        // and see this file as a workspace-relative path, not a sandbox path.
        var result = x * 2;
        return result;
    }
}

using System;
using System.Runtime.InteropServices;

namespace ParityApp;

/// <summary>
/// P/Invoke consumer — exercises spec-native-interop #349.
/// Calls into the cc_library "native_add" shared library.
/// </summary>
public static class NativeMath
{
    [DllImport("native_add")]
    public static extern int native_add(int a, int b);

    public static int Add(int a, int b) => native_add(a, b);
}

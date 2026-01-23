using System.Runtime.InteropServices;

public static class NativeInterop
{
    [DllImport("native_lib")]
    public static extern int native_add(int a, int b);
}

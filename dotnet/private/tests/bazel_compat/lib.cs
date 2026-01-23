namespace BazelCompat
{
    /// <summary>
    /// Minimal library to verify Bazel compatibility.
    /// Tests that csharp_library builds correctly with
    /// --incompatible_auto_exec_groups support.
    /// </summary>
    public class Greeter
    {
        public static string Hello() => "Hello from BazelCompat";
    }
}

internal static class NUnitShim {
    public static int Main(string[] args) {
        var argsList = new System.Collections.Generic.List<string>(args);

        // XML test output: when Bazel sets XML_OUTPUT_FILE, write NUnit3 results
        var xmlOutputFile = System.Environment.GetEnvironmentVariable("XML_OUTPUT_FILE");
        if (xmlOutputFile != null) {
            argsList.Add("--result=" + xmlOutputFile + ";format=nunit3");
        }

        // Test sharding: TEST_SHARD_STATUS_FILE touch is handled in launcher.
        // NUnitLite doesn't support modulo-based test filtering natively;
        // Bazel sharding primarily splits across test targets.

        return new NUnitLite.AutoRun().Execute(argsList.ToArray());
    }
}

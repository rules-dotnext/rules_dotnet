[<EntryPoint>]
let main argv =
    let argsList = System.Collections.Generic.List<string>(argv)

    // XML test output: when Bazel sets XML_OUTPUT_FILE, write NUnit3 results
    let xmlOutputFile = System.Environment.GetEnvironmentVariable("XML_OUTPUT_FILE")
    if xmlOutputFile <> null then
        argsList.Add("--result=" + xmlOutputFile + ";format=nunit3")

    // Test sharding: TEST_SHARD_STATUS_FILE touch is handled in launcher.
    NUnitLite.AutoRun().Execute(argsList.ToArray())

using CommandLine;

namespace nuget2bazel
{
    [Verb("add", HelpText = "Adds a package to the WORKSPACE and packages.json")]
    public class AddVerb : AddOrUpdateVerb
    {
    }
}
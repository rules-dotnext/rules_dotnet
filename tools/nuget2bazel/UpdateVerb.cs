using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommandLine;

namespace nuget2bazel
{
    [Verb("update", HelpText = "Updates a package in the bazel and config files")]
    public class UpdateVerb : AddOrUpdateVerb
    {
    }
}
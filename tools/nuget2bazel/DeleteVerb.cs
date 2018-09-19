using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommandLine;

namespace nuget2bazel
{
    [Verb("delete", HelpText = "Remove the package from WORKSPACE and packages.json")]
    public class DeleteVerb
    {
        [Value(index: 0,
            Required = true,
            HelpText = "Package id")]
        public string Package { get; set; }

        [Option('p', "path",
            Default = null,
            HelpText = "Path to the directory with the WORKSPACE file")]
        public string RootPath { get; set; }
    }
}

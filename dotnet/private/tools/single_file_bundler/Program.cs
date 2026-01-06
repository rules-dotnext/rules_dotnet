using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.NET.HostModel.Bundle;

namespace SingleFileBundler
{
    public class Program
    {
        public static int Main(string[] args)
        {
            // args: <apphost> <output> <target-rid> <target-framework-version> <manifest-file>
            // manifest-file format: each line is "<relative-path>\t<absolute-path>"
            if (args.Length < 5)
            {
                Console.Error.WriteLine(
                    "Usage: SingleFileBundler <apphost> <output> <rid> <tfm-version> <manifest>");
                return 1;
            }

            string apphostPath = Path.GetFullPath(args[0]);
            string outputPath = Path.GetFullPath(args[1]);
            string rid = args[2];
            string tfmVersion = args[3];
            string manifestPath = Path.GetFullPath(args[4]);

            var targetFrameworkVersion = new Version(tfmVersion);
            // BundleOptions: BundleAllContent bundles managed DLLs, pdbs, config files
            var bundleOptions = BundleOptions.BundleAllContent;

            var bundler = new Bundler(
                hostName: Path.GetFileName(outputPath),
                outputDir: Path.GetDirectoryName(outputPath)!,
                options: bundleOptions,
                targetFrameworkVersion: targetFrameworkVersion,
                macosCodesign: rid.StartsWith("osx"));

            var fileSpecs = new List<FileSpec>();
            foreach (string line in File.ReadAllLines(manifestPath))
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                var parts = line.Split('\t');
                // parts[0] = relative path in bundle, parts[1] = absolute source path
                fileSpecs.Add(new FileSpec(sourcePath: parts[1], bundleRelativePath: parts[0]));
            }

            bundler.GenerateBundle(fileSpecs);
            return 0;
        }
    }
}

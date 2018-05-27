using System;
using System.Collections.Generic;
using System.IO;

namespace genbuild
{
    class Program
    {
        static void Main(string[] args)
        {
            string inputDir = "c:/temp/core/shared/Microsoft.NETCore.App/2.0.7";
            var files = ReadDir(inputDir);
            var index = new Dictionary<string, DllInfo>();
            files.ForEach(x => index.Add(Path.GetFileNameWithoutExtension(x), new DllInfo(x)));
            foreach(var d in index.Values)
            {
                d.GetInfo(index);
            }
            foreach (var d in index.Values)
            {
                d.DumpBazel();
            }
        }

        static List<string> ReadDir(string dir)
        {
            var result = new List<string>();
            foreach(var f in System.IO.Directory.EnumerateFiles(dir))
            {
                if (Path.GetExtension(f) == ".dll")
                {
                    result.Add(f);
                }
            }
            return result;
        }
    }
}

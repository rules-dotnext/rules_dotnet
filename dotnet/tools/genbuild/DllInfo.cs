using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

namespace genbuild
{
    public class DllInfo
    {
        public string Path { get; }
        public bool IsManaged { get; set; }
        public List<DllInfo> Modules { get; }
        public List<DllInfo> References { get; }

        public DllInfo(string path)
        {
            Path = path;
            Modules = new List<DllInfo>();
            References = new List<DllInfo>();
        }

        public void GetInfo(Dictionary<string, DllInfo> index)
        {
            var assembly = GetAssembly();
            if (assembly == null)
            {
                IsManaged = false;
                return;
            }

            IsManaged = true;

            foreach (var m in assembly.GetReferencedAssemblies())
            {
                if (index.ContainsKey(m.Name))
                {
                    var f = index[m.Name];
                    if (References.Count(x => x==f) == 0)
                        References.Add(f);
                }
            }
        }
        public void DumpBazel()
        {
            if (!IsManaged)
                return;

            Console.Write($"core_stdlib(name = \"{System.IO.Path.GetFileNameWithoutExtension(Path)}.dll\"");
            if (References.Count == 0)
            {
                Console.WriteLine(")");
                return;
            }
            Console.WriteLine(", deps = [");
            foreach(var r in References)
            {
                Console.WriteLine($"      \":{System.IO.Path.GetFileNameWithoutExtension(r.Path)}.dll\",");
            }
            Console.WriteLine("    ]");
            Console.WriteLine(")");
        }

        private Assembly GetAssembly()
        {
            try
            {
                var result = Assembly.LoadFile(Path);
                return result;
            }
            catch (Exception)
            {
                return null;
            }
        }
    }
}

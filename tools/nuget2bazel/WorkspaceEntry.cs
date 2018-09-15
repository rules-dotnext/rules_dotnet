using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NuGet.Frameworks;
using NuGet.Packaging;
using NuGet.Packaging.Core;
using NuGet.ProjectManagement;

namespace nuget2bazel
{
    public class WorkspaceEntry
    {
        public WorkspaceEntry()
        {
        }
        public WorkspaceEntry(PackageIdentity identity, string sha256, IEnumerable<PackageDependency> deps,
            IEnumerable<FrameworkSpecificGroup> libs, IEnumerable<FrameworkSpecificGroup> references)
        {
            PackageIdentity = identity;
            Sha256 = sha256;
            Dependencies = deps;

            var coreFramework = NuGetFramework.Parse("netcoreapp2.0");
            var netFramework = NuGetFramework.Parse("net46");
            var monoFramework = NuGetFramework.Parse("net45");

            Core_Files = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(coreFramework, libs)?.Items;
            Net_Files = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(netFramework, libs)?.Items;
            Mono_Files = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(monoFramework, libs)?.Items;

            CoreLib = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(coreFramework, references)?.Items.FirstOrDefault();
            NetLib = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(netFramework, references)?.Items.FirstOrDefault();
            MonoLib = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(monoFramework, references)?.Items.FirstOrDefault();
        }

        public string Generate()
        {
            var sb = new StringBuilder();
            sb.Append($"nuget_package(\n");
            sb.Append($"   name = \"{PackageIdentity.Id.ToLower()}\",\n");
            sb.Append($"   package = \"{PackageIdentity.Id.ToLower()}\",\n");
            sb.Append($"   version = \"{PackageIdentity.Version}\",\n");
            sb.Append($"   sha256 = \"{Sha256}\",\n");
            sb.Append($"   core_lib = \"{CoreLib}\",\n");
            sb.Append($"   net_lib = \"{NetLib}\",\n");
            sb.Append($"   mono_lib = \"{MonoLib}\",\n");
            sb.Append($"   deps = [\n");
            if (Dependencies != null)
            foreach (var s in Dependencies)
                sb.Append($"       \"{s.Id}\",\n");
            sb.Append($"   ],\n");
            sb.Append($"   core_files = [\n");
            if (Core_Files != null)
            foreach (var s in Core_Files)
                sb.Append($"       \"{s}\",\n");
            sb.Append($"   ],\n");
            sb.Append($"   net_files = [\n");
            if (Net_Files != null)
            foreach (var s in Net_Files)
                sb.Append($"       \"{s}\",\n");
            sb.Append($"   ],\n");
            sb.Append($"   mono_files = [\n");
            if (Mono_Files != null)
            foreach (var s in Mono_Files)
                sb.Append($"       \"{s}\",\n");
            sb.Append($"   ],\n");
            sb.Append($")\n");
            return sb.ToString();
        }


        public PackageIdentity PackageIdentity { get; set; }
        public string Sha256 { get; set; }
        public string CoreLib { get; set; }
        public string NetLib { get; set; }
        public string MonoLib { get; set; }
        public IEnumerable<PackageDependency> Dependencies { get; set; }
        public IEnumerable<string> Core_Files { get; set; }
        public IEnumerable<string> Net_Files { get; set; }
        public IEnumerable<string> Mono_Files { get; set; }
    }
}

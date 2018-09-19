using System;
using System.Collections.Generic;
using System.IO;
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
        public WorkspaceEntry(PackageIdentity identity, string sha256, IEnumerable<PackageDependencyGroup> deps,
            IEnumerable<FrameworkSpecificGroup> libs, IEnumerable<FrameworkSpecificGroup> references)
        {
            PackageIdentity = identity;
            Sha256 = sha256;

            var coreFramework = NuGetFramework.Parse("netcoreapp5.0");
            var netFramework = NuGetFramework.Parse("net70");
            var monoFramework = NuGetFramework.Parse("net70");

            Core_Files = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(coreFramework, libs)?.Items;
            Net_Files = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(netFramework, libs)?.Items;
            Mono_Files = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(monoFramework, libs)?.Items;

            var depConverted = deps.Select(x =>
                new FrameworkSpecificGroup(x.TargetFramework, x.Packages.Select(y => y.Id.ToLower())));
            Core_Deps = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(coreFramework, depConverted)?.Items?.Select(x => ToRef(x, "core"));
            Net_Deps = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(netFramework, depConverted)?.Items?.Select(x => ToRef(x, "net"));
            Mono_Deps = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(monoFramework, depConverted)?.Items?.Select(x => ToRef(x, "mono"));

            CoreLib = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(coreFramework, references)?.Items.FirstOrDefault(x => Path.GetExtension(x) == ".dll");
            NetLib = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(netFramework, references)?.Items.FirstOrDefault(x => Path.GetExtension(x) == ".dll");
            MonoLib = MSBuildNuGetProjectSystemUtility.GetMostCompatibleGroup(monoFramework, references)?.Items.FirstOrDefault(x => Path.GetExtension(x) == ".dll");

            if (CoreLib == null)
                CoreLib = Core_Files?.FirstOrDefault(x => Path.GetExtension(x) == ".dll");
            if (NetLib == null)
                NetLib = Net_Files?.FirstOrDefault(x => Path.GetExtension(x) == ".dll");
            if (CoreLib == null)
                CoreLib = NetLib;

            if (MonoLib == null)
                MonoLib = Mono_Files?.FirstOrDefault(x => Path.GetExtension(x) == ".dll");
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

            sb.Append($"   core_deps = [\n");
            if (Core_Deps != null)
            foreach (var s in Core_Deps)
                sb.Append($"       \"{s}\",\n");
            sb.Append($"   ],\n");
            sb.Append($"   net_deps = [\n");
            if (Net_Deps != null)
                foreach (var s in Net_Deps)
                    sb.Append($"       \"{s}\",\n");
            sb.Append($"   ],\n");
            sb.Append($"   mono_deps = [\n");
            if (Mono_Deps != null)
                foreach (var s in Mono_Deps)
                    sb.Append($"       \"{s}\",\n");
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

        private string ToRef(string id, string kind)
        {
            if (SdkList.Dlls.Contains(id.ToLower()))
                return $"@io_bazel_rules_dotnet//dotnet/stdlib.core:{id.ToLower()}.dll";

            return $"@{id.ToLower()}//:{kind}";
        }


        public PackageIdentity PackageIdentity { get; set; }
        public string Sha256 { get; set; }
        public string CoreLib { get; set; }
        public string NetLib { get; set; }
        public string MonoLib { get; set; }
        public IEnumerable<string> Core_Deps { get; set; }
        public IEnumerable<string> Net_Deps { get; set; }
        public IEnumerable<string> Mono_Deps { get; set; }
        public IEnumerable<string> Core_Files { get; set; }
        public IEnumerable<string> Net_Files { get; set; }
        public IEnumerable<string> Mono_Files { get; set; }
    }
}

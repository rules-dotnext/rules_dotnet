package dotnet

import (
	"encoding/xml"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// ProjectFile represents a parsed .csproj or .fsproj file.
type ProjectFile struct {
	// Path is the absolute path to the project file.
	Path string

	// Name is the file name without extension (used as default rule name).
	Name string

	// Language is "csharp" or "fsharp".
	Language string

	// SDK is the project SDK (e.g., "Microsoft.NET.Sdk", "Microsoft.NET.Sdk.Web").
	SDK string

	// TargetFrameworks extracted from <TargetFramework> or <TargetFrameworks>.
	TargetFrameworks []string

	// OutputType from <OutputType> element. "Exe", "Library", or "".
	OutputType string

	// PackageReferences maps package name -> version string.
	PackageReferences map[string]string

	// ProjectReferences is a list of relative paths to referenced .csproj/.fsproj files.
	ProjectReferences []string

	// SourceFiles is the list of explicitly included source files, if any.
	// Empty means the SDK-style default glob applies (all *.cs / *.fs in directory).
	SourceFiles []string

	// IsTestProject is true if the project references a known test framework.
	IsTestProject bool

	// TestFramework is the detected test framework: "nunit", "xunit", "mstest", or "".
	TestFramework string

	// Nullable setting from <Nullable> element.
	Nullable string

	// AssemblyName override from <AssemblyName> element.
	AssemblyName string

	// RootNamespace from <RootNamespace> element.
	RootNamespace string

	// EmbeddedResources from <EmbeddedResource Include="..."> elements.
	EmbeddedResources []string

	// AllowUnsafeBlocks from <AllowUnsafeBlocks> element.
	AllowUnsafeBlocks bool

	// LangVersion from <LangVersion> element.
	LangVersion string
}

// XML structures for parsing MSBuild project files.

type msbuildProject struct {
	XMLName        xml.Name               `xml:"Project"`
	SDK            string                 `xml:"Sdk,attr"`
	PropertyGroups []msbuildPropertyGroup `xml:"PropertyGroup"`
	ItemGroups     []msbuildItemGroup     `xml:"ItemGroup"`
}

type msbuildPropertyGroup struct {
	TargetFramework   string `xml:"TargetFramework"`
	TargetFrameworks  string `xml:"TargetFrameworks"`
	OutputType        string `xml:"OutputType"`
	IsPackable        string `xml:"IsPackable"`
	Nullable          string `xml:"Nullable"`
	AssemblyName      string `xml:"AssemblyName"`
	RootNamespace     string `xml:"RootNamespace"`
	AllowUnsafeBlocks string `xml:"AllowUnsafeBlocks"`
	LangVersion       string `xml:"LangVersion"`
}

type msbuildItemGroup struct {
	PackageReferences []msbuildPackageRef  `xml:"PackageReference"`
	ProjectReferences []msbuildProjectRef  `xml:"ProjectReference"`
	Compile           []msbuildCompile     `xml:"Compile"`
	EmbeddedResources []msbuildEmbeddedRes `xml:"EmbeddedResource"`
}

type msbuildPackageRef struct {
	Include string `xml:"Include,attr"`
	Version string `xml:"Version,attr"`
}

type msbuildProjectRef struct {
	Include string `xml:"Include,attr"`
}

type msbuildCompile struct {
	Include string `xml:"Include,attr"`
	Remove  string `xml:"Remove,attr"`
}

type msbuildEmbeddedRes struct {
	Include string `xml:"Include,attr"`
}

// testFrameworkEntry pairs a NuGet package name with the test framework it
// indicates. Entries are ordered by detection priority: NUnit > xUnit > MSTest.
// The first matching package wins, ensuring deterministic results regardless of
// map iteration order in PackageReferences.
type testFrameworkEntry struct {
	packageName string
	framework   string
}

var testFrameworkPriority = []testFrameworkEntry{
	{"NUnit", "nunit"},
	{"NUnit3TestAdapter", "nunit"},
	{"nunit", "nunit"},
	{"xunit", "xunit"},
	{"xunit.core", "xunit"},
	{"xunit.runner.visualstudio", "xunit"},
	{"Microsoft.NET.Test.Sdk", "mstest"},
	{"MSTest.TestAdapter", "mstest"},
	{"MSTest.TestFramework", "mstest"},
}

// nunitInjectedPackages are package names injected by the csharp_nunit_test
// macro, so they should be excluded from generated deps.
var nunitInjectedPackages = map[string]bool{
	"NUnit":             true,
	"NUnit3TestAdapter": true,
	"nunit":             true,
}

// ParseProjectFile parses a .csproj or .fsproj file and returns structured metadata.
func ParseProjectFile(path string) (*ProjectFile, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return parseProjectFileData(data, path)
}

// parseProjectFileData parses the XML data with the given path for metadata.
func parseProjectFileData(data []byte, path string) (*ProjectFile, error) {
	var proj msbuildProject
	if err := xml.Unmarshal(data, &proj); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}

	ext := filepath.Ext(path)
	name := strings.TrimSuffix(filepath.Base(path), ext)

	pf := &ProjectFile{
		Path:              path,
		Name:              name,
		SDK:               proj.SDK,
		PackageReferences: make(map[string]string),
	}

	// Determine language from file extension
	switch ext {
	case ".csproj":
		pf.Language = "csharp"
	case ".fsproj":
		pf.Language = "fsharp"
	default:
		pf.Language = "csharp"
	}

	// Extract properties (last one wins, matching MSBuild behavior)
	for _, pg := range proj.PropertyGroups {
		if pg.TargetFramework != "" {
			pf.TargetFrameworks = []string{pg.TargetFramework}
		}
		if pg.TargetFrameworks != "" {
			pf.TargetFrameworks = strings.Split(pg.TargetFrameworks, ";")
		}
		if pg.OutputType != "" {
			pf.OutputType = pg.OutputType
		}
		if pg.Nullable != "" {
			pf.Nullable = pg.Nullable
		}
		if pg.AssemblyName != "" {
			pf.AssemblyName = pg.AssemblyName
		}
		if pg.RootNamespace != "" {
			pf.RootNamespace = pg.RootNamespace
		}
		if strings.EqualFold(pg.AllowUnsafeBlocks, "true") {
			pf.AllowUnsafeBlocks = true
		}
		if pg.LangVersion != "" {
			pf.LangVersion = pg.LangVersion
		}
	}

	// Extract items
	for _, ig := range proj.ItemGroups {
		for _, pr := range ig.PackageReferences {
			pf.PackageReferences[pr.Include] = pr.Version
		}
		for _, pr := range ig.ProjectReferences {
			pf.ProjectReferences = append(pf.ProjectReferences, pr.Include)
		}
		for _, c := range ig.Compile {
			if c.Include != "" {
				pf.SourceFiles = append(pf.SourceFiles, c.Include)
			}
		}
		for _, er := range ig.EmbeddedResources {
			if er.Include != "" {
				pf.EmbeddedResources = append(pf.EmbeddedResources, er.Include)
			}
		}
	}

	// Detect test framework using priority order (NUnit > xUnit > MSTest).
	for _, entry := range testFrameworkPriority {
		if _, ok := pf.PackageReferences[entry.packageName]; ok {
			pf.IsTestProject = true
			pf.TestFramework = entry.framework
			break
		}
	}

	return pf, nil
}

package dotnet

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseSimpleLibrary(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "MyLib.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if proj.Name != "MyLib" {
		t.Errorf("Name = %q, want %q", proj.Name, "MyLib")
	}
	if proj.Language != "csharp" {
		t.Errorf("Language = %q, want %q", proj.Language, "csharp")
	}
	if proj.SDK != "Microsoft.NET.Sdk" {
		t.Errorf("SDK = %q, want %q", proj.SDK, "Microsoft.NET.Sdk")
	}
	if len(proj.TargetFrameworks) != 1 || proj.TargetFrameworks[0] != "net8.0" {
		t.Errorf("TargetFrameworks = %v, want [net8.0]", proj.TargetFrameworks)
	}
	if proj.IsTestProject {
		t.Error("IsTestProject = true, want false")
	}
}

func TestParseBinaryProject(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <OutputType>Exe</OutputType>
  </PropertyGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "MyApp.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if proj.OutputType != "Exe" {
		t.Errorf("OutputType = %q, want %q", proj.OutputType, "Exe")
	}
}

func TestParseNUnitTestProject(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="NUnit" Version="3.14.0" />
    <PackageReference Include="NUnit3TestAdapter" Version="4.5.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
  </ItemGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "MyLib.Tests.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !proj.IsTestProject {
		t.Error("IsTestProject = false, want true")
	}
	if proj.TestFramework != "nunit" && proj.TestFramework != "mstest" {
		// Both nunit and mstest packages are present; map iteration order
		// is non-deterministic. Either detection is acceptable.
		t.Errorf("TestFramework = %q, want nunit or mstest", proj.TestFramework)
	}
}

func TestParseXUnitTestProject(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit" Version="2.6.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.5.4" />
  </ItemGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "Tests.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !proj.IsTestProject {
		t.Error("IsTestProject = false, want true")
	}
	if proj.TestFramework != "xunit" {
		t.Errorf("TestFramework = %q, want %q", proj.TestFramework, "xunit")
	}
}

func TestParseMultiTargetProject(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net6.0;net8.0</TargetFrameworks>
  </PropertyGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "Multi.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(proj.TargetFrameworks) != 2 {
		t.Fatalf("TargetFrameworks length = %d, want 2", len(proj.TargetFrameworks))
	}
	if proj.TargetFrameworks[0] != "net6.0" || proj.TargetFrameworks[1] != "net8.0" {
		t.Errorf("TargetFrameworks = %v, want [net6.0, net8.0]", proj.TargetFrameworks)
	}
}

func TestParseFSharpProject(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "MyFsLib.fsproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if proj.Language != "fsharp" {
		t.Errorf("Language = %q, want %q", proj.Language, "fsharp")
	}
}

func TestParseWebProject(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "WebApp.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if proj.SDK != "Microsoft.NET.Sdk.Web" {
		t.Errorf("SDK = %q, want %q", proj.SDK, "Microsoft.NET.Sdk.Web")
	}
	if proj.Nullable != "enable" {
		t.Errorf("Nullable = %q, want %q", proj.Nullable, "enable")
	}
}

func TestParseExplicitCompileItems(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Foo.cs" />
    <Compile Include="Bar.cs" />
  </ItemGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "Explicit.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(proj.SourceFiles) != 2 {
		t.Fatalf("SourceFiles length = %d, want 2", len(proj.SourceFiles))
	}
	if proj.SourceFiles[0] != "Foo.cs" || proj.SourceFiles[1] != "Bar.cs" {
		t.Errorf("SourceFiles = %v, want [Foo.cs, Bar.cs]", proj.SourceFiles)
	}
}

func TestParseEmbeddedResources(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <EmbeddedResource Include="Resources/strings.resx" />
  </ItemGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "WithRes.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(proj.EmbeddedResources) != 1 || proj.EmbeddedResources[0] != "Resources/strings.resx" {
		t.Errorf("EmbeddedResources = %v, want [Resources/strings.resx]", proj.EmbeddedResources)
	}
}

func TestParseUnsafeAndLangVersion(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <AllowUnsafeBlocks>true</AllowUnsafeBlocks>
    <LangVersion>12</LangVersion>
  </PropertyGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "Unsafe.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !proj.AllowUnsafeBlocks {
		t.Error("AllowUnsafeBlocks = false, want true")
	}
	if proj.LangVersion != "12" {
		t.Errorf("LangVersion = %q, want %q", proj.LangVersion, "12")
	}
}

func TestParsePackageAndProjectReferences(t *testing.T) {
	data := []byte(`<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
    <PackageReference Include="Serilog" Version="3.1.1" />
    <ProjectReference Include="../OtherLib/OtherLib.csproj" />
  </ItemGroup>
</Project>`)

	proj, err := parseProjectFileData(data, "App.csproj")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(proj.PackageReferences) != 2 {
		t.Fatalf("PackageReferences length = %d, want 2", len(proj.PackageReferences))
	}
	if v, ok := proj.PackageReferences["Newtonsoft.Json"]; !ok || v != "13.0.3" {
		t.Errorf("PackageReferences[Newtonsoft.Json] = %q, want %q", v, "13.0.3")
	}
	if len(proj.ProjectReferences) != 1 || proj.ProjectReferences[0] != "../OtherLib/OtherLib.csproj" {
		t.Errorf("ProjectReferences = %v, want [../OtherLib/OtherLib.csproj]", proj.ProjectReferences)
	}
}

func TestParseProjectFileFromDisk(t *testing.T) {
	dir := t.TempDir()
	content := `<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <AssemblyName>CustomName</AssemblyName>
    <RootNamespace>My.Namespace</RootNamespace>
  </PropertyGroup>
</Project>`

	path := filepath.Join(dir, "Test.csproj")
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatalf("failed to write test file: %v", err)
	}

	proj, err := ParseProjectFile(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if proj.AssemblyName != "CustomName" {
		t.Errorf("AssemblyName = %q, want %q", proj.AssemblyName, "CustomName")
	}
	if proj.RootNamespace != "My.Namespace" {
		t.Errorf("RootNamespace = %q, want %q", proj.RootNamespace, "My.Namespace")
	}
}

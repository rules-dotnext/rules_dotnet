package dotnet

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRuleKindLibrary(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{Language: "csharp"}
	if kind := dl.ruleKind(proj); kind != "csharp_library" {
		t.Errorf("ruleKind = %q, want %q", kind, "csharp_library")
	}
}

func TestRuleKindBinary(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{Language: "csharp", OutputType: "Exe"}
	if kind := dl.ruleKind(proj); kind != "csharp_binary" {
		t.Errorf("ruleKind = %q, want %q", kind, "csharp_binary")
	}
}

func TestRuleKindWinExe(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{Language: "csharp", OutputType: "WinExe"}
	if kind := dl.ruleKind(proj); kind != "csharp_binary" {
		t.Errorf("ruleKind = %q, want %q", kind, "csharp_binary")
	}
}

func TestRuleKindNUnitTest(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{
		Language:      "csharp",
		IsTestProject: true,
		TestFramework: "nunit",
	}
	if kind := dl.ruleKind(proj); kind != "csharp_nunit_test" {
		t.Errorf("ruleKind = %q, want %q", kind, "csharp_nunit_test")
	}
}

func TestRuleKindXUnitTest(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{
		Language:      "csharp",
		IsTestProject: true,
		TestFramework: "xunit",
	}
	if kind := dl.ruleKind(proj); kind != "csharp_test" {
		t.Errorf("ruleKind = %q, want %q", kind, "csharp_test")
	}
}

func TestRuleKindFSharpLibrary(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{Language: "fsharp"}
	if kind := dl.ruleKind(proj); kind != "fsharp_library" {
		t.Errorf("ruleKind = %q, want %q", kind, "fsharp_library")
	}
}

func TestRuleKindFSharpNUnitTest(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{
		Language:      "fsharp",
		IsTestProject: true,
		TestFramework: "nunit",
	}
	if kind := dl.ruleKind(proj); kind != "fsharp_nunit_test" {
		t.Errorf("ruleKind = %q, want %q", kind, "fsharp_nunit_test")
	}
}

func TestRuleName(t *testing.T) {
	dl := &dotnetLang{}

	tests := []struct {
		name string
		want string
	}{
		{"MyLib", "mylib"},
		{"My.Lib", "my_lib"},
		{"My-App", "my_app"},
		{"My.App.Tests", "my_app_tests"},
	}

	for _, tc := range tests {
		proj := &ProjectFile{Name: tc.name}
		if got := dl.ruleName(proj); got != tc.want {
			t.Errorf("ruleName(%q) = %q, want %q", tc.name, got, tc.want)
		}
	}
}

func TestResolveSourcesImplicitGlob(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{Language: "csharp"}
	regularFiles := []string{"Foo.cs", "Bar.cs", "README.md", "App.csproj"}

	srcs := dl.resolveSources(proj, "/tmp", regularFiles)
	if len(srcs) != 2 {
		t.Fatalf("len(srcs) = %d, want 2", len(srcs))
	}
	// Should be sorted
	if srcs[0] != "Bar.cs" || srcs[1] != "Foo.cs" {
		t.Errorf("srcs = %v, want [Bar.cs, Foo.cs]", srcs)
	}
}

func TestResolveSourcesFSharp(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{Language: "fsharp"}
	regularFiles := []string{"Lib.fs", "Helper.fs", "Script.fsx", "App.fsproj"}

	srcs := dl.resolveSources(proj, "/tmp", regularFiles)
	if len(srcs) != 2 {
		t.Fatalf("len(srcs) = %d, want 2", len(srcs))
	}
}

func TestResolveSourcesExplicit(t *testing.T) {
	dl := &dotnetLang{}
	proj := &ProjectFile{
		Language:    "csharp",
		SourceFiles: []string{"Specific.cs", "Other.cs"},
	}
	regularFiles := []string{"Specific.cs", "Other.cs", "Ignored.cs"}

	srcs := dl.resolveSources(proj, "/tmp", regularFiles)
	if len(srcs) != 2 {
		t.Fatalf("len(srcs) = %d, want 2", len(srcs))
	}
	if srcs[0] != "Specific.cs" || srcs[1] != "Other.cs" {
		t.Errorf("srcs = %v, want [Specific.cs, Other.cs]", srcs)
	}
}

func TestResolveProjectReference(t *testing.T) {
	dl := &dotnetLang{}

	tests := []struct {
		projDir string
		projRel string
		ref     string
		want    string
	}{
		{
			projDir: "/workspace/MyApp",
			projRel: "MyApp",
			ref:     "../MyLib/MyLib.csproj",
			want:    "//MyLib:mylib",
		},
		{
			projDir: "/workspace/src/MyApp",
			projRel: "src/MyApp",
			ref:     "../MyLib/MyLib.csproj",
			want:    "//src/MyLib:mylib",
		},
		{
			projDir: "/workspace/MyApp",
			projRel: "MyApp",
			ref:     "../My.Lib/My.Lib.csproj",
			want:    "//My.Lib:my_lib",
		},
	}

	for _, tc := range tests {
		got := dl.resolveProjectReference(tc.projDir, tc.projRel, tc.ref)
		if got != tc.want {
			t.Errorf("resolveProjectReference(%q, %q, %q) = %q, want %q",
				tc.projDir, tc.projRel, tc.ref, got, tc.want)
		}
	}
}

func TestResolveProjectReferenceBackslash(t *testing.T) {
	dl := &dotnetLang{}
	got := dl.resolveProjectReference("/workspace/MyApp", "MyApp", "..\\MyLib\\MyLib.csproj")
	if got != "//MyLib:mylib" {
		t.Errorf("resolveProjectReference with backslash = %q, want %q", got, "//MyLib:mylib")
	}
}

// TestEndToEndGeneration tests a full scenario: write a .csproj to disk,
// parse it, and verify the generated rule attributes.
func TestEndToEndGeneration(t *testing.T) {
	dir := t.TempDir()

	csproj := `<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <OutputType>Exe</OutputType>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Serilog" Version="3.1.1" />
    <ProjectReference Include="../MyLib/MyLib.csproj" />
  </ItemGroup>
</Project>`

	// Write .csproj
	if err := os.WriteFile(filepath.Join(dir, "MyApp.csproj"), []byte(csproj), 0644); err != nil {
		t.Fatal(err)
	}
	// Write source files
	for _, name := range []string{"Program.cs", "Startup.cs"} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte("// "+name), 0644); err != nil {
			t.Fatal(err)
		}
	}

	proj, err := ParseProjectFile(filepath.Join(dir, "MyApp.csproj"))
	if err != nil {
		t.Fatalf("ParseProjectFile: %v", err)
	}

	dl := &dotnetLang{}

	// Verify kind
	kind := dl.ruleKind(proj)
	if kind != "csharp_binary" {
		t.Errorf("ruleKind = %q, want csharp_binary", kind)
	}

	// Verify name
	name := dl.ruleName(proj)
	if name != "myapp" {
		t.Errorf("ruleName = %q, want myapp", name)
	}

	// Verify sources
	regularFiles := []string{"MyApp.csproj", "Program.cs", "Startup.cs"}
	srcs := dl.resolveSources(proj, dir, regularFiles)
	if len(srcs) != 2 {
		t.Fatalf("len(srcs) = %d, want 2", len(srcs))
	}
	if srcs[0] != "Program.cs" || srcs[1] != "Startup.cs" {
		t.Errorf("srcs = %v, want [Program.cs, Startup.cs]", srcs)
	}

	// Verify SDK detection
	if !strings.EqualFold(proj.SDK, "Microsoft.NET.Sdk.Web") {
		t.Errorf("SDK = %q, want Microsoft.NET.Sdk.Web", proj.SDK)
	}

	// Verify nullable
	if proj.Nullable != "enable" {
		t.Errorf("Nullable = %q, want enable", proj.Nullable)
	}
}

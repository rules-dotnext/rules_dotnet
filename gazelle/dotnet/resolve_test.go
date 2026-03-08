package dotnet

import (
	"testing"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/label"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

func TestResolveNuGetPackages(t *testing.T) {
	dl := &dotnetLang{}
	cfg := newDotnetConfig()
	cfg.nugetRepoName = "nuget"
	c := &config.Config{Exts: map[string]interface{}{dotnetName: cfg}}

	r := rule.NewRule("csharp_library", "mylib")
	imports := &dotnetImports{
		packageRefs: map[string]string{
			"Newtonsoft.Json": "13.0.3",
		},
	}

	dl.Resolve(c, nil, nil, r, imports, label.Label{})

	deps := r.AttrStrings("deps")
	if len(deps) != 1 {
		t.Fatalf("deps length = %d, want 1", len(deps))
	}
	if deps[0] != "@nuget//newtonsoft.json" {
		t.Errorf("deps[0] = %q, want %q", deps[0], "@nuget//newtonsoft.json")
	}
}

func TestResolveOverridesTakesPrecedence(t *testing.T) {
	dl := &dotnetLang{}
	cfg := newDotnetConfig()
	cfg.nugetRepoName = "nuget"
	cfg.resolveOverrides["newtonsoft.json"] = "//third_party:newtonsoft"
	c := &config.Config{Exts: map[string]interface{}{dotnetName: cfg}}

	r := rule.NewRule("csharp_library", "mylib")
	imports := &dotnetImports{
		packageRefs: map[string]string{
			"Newtonsoft.Json": "13.0.3",
		},
	}

	dl.Resolve(c, nil, nil, r, imports, label.Label{})

	deps := r.AttrStrings("deps")
	if len(deps) != 1 {
		t.Fatalf("deps length = %d, want 1", len(deps))
	}
	if deps[0] != "//third_party:newtonsoft" {
		t.Errorf("deps[0] = %q, want %q", deps[0], "//third_party:newtonsoft")
	}
}

func TestResolveNUnitPackagesSkipped(t *testing.T) {
	dl := &dotnetLang{}
	cfg := newDotnetConfig()
	cfg.nugetRepoName = "nuget"
	c := &config.Config{Exts: map[string]interface{}{dotnetName: cfg}}

	r := rule.NewRule("csharp_nunit_test", "mytest")
	imports := &dotnetImports{
		packageRefs: map[string]string{
			"NUnit":             "3.14.0",
			"NUnit3TestAdapter": "4.5.0",
			"Moq":               "4.20.0",
		},
		isNUnitTest: true,
	}

	dl.Resolve(c, nil, nil, r, imports, label.Label{})

	deps := r.AttrStrings("deps")
	if len(deps) != 1 {
		t.Fatalf("deps length = %d, want 1 (only Moq)", len(deps))
	}
	if deps[0] != "@nuget//moq" {
		t.Errorf("deps[0] = %q, want %q", deps[0], "@nuget//moq")
	}
}

func TestResolveProjectReferences(t *testing.T) {
	dl := &dotnetLang{}
	cfg := newDotnetConfig()
	c := &config.Config{Exts: map[string]interface{}{dotnetName: cfg}}

	r := rule.NewRule("csharp_library", "mylib")
	imports := &dotnetImports{
		packageRefs: map[string]string{},
		projectRefs: []string{"../OtherLib/OtherLib.csproj"},
		projDir:     "/workspace/MyApp",
		projRel:     "MyApp",
	}

	dl.Resolve(c, nil, nil, r, imports, label.Label{})

	deps := r.AttrStrings("deps")
	if len(deps) != 1 {
		t.Fatalf("deps length = %d, want 1", len(deps))
	}
	if deps[0] != "//OtherLib:otherlib" {
		t.Errorf("deps[0] = %q, want %q", deps[0], "//OtherLib:otherlib")
	}
}

func TestResolveNilImports(t *testing.T) {
	dl := &dotnetLang{}
	cfg := newDotnetConfig()
	c := &config.Config{Exts: map[string]interface{}{dotnetName: cfg}}

	r := rule.NewRule("csharp_library", "mylib")

	// Should not panic
	dl.Resolve(c, nil, nil, r, nil, label.Label{})
}

func TestResolveSortsDeps(t *testing.T) {
	dl := &dotnetLang{}
	cfg := newDotnetConfig()
	cfg.nugetRepoName = "nuget"
	c := &config.Config{Exts: map[string]interface{}{dotnetName: cfg}}

	r := rule.NewRule("csharp_library", "mylib")
	imports := &dotnetImports{
		packageRefs: map[string]string{
			"Serilog":         "3.1.1",
			"Newtonsoft.Json": "13.0.3",
			"AutoMapper":     "12.0.1",
		},
	}

	dl.Resolve(c, nil, nil, r, imports, label.Label{})

	deps := r.AttrStrings("deps")
	if len(deps) != 3 {
		t.Fatalf("deps length = %d, want 3", len(deps))
	}
	// Deps should be sorted
	for i := 1; i < len(deps); i++ {
		if deps[i-1] > deps[i] {
			t.Errorf("deps not sorted: %v", deps)
			break
		}
	}
}

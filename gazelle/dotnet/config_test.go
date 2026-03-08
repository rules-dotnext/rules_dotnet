package dotnet

import (
	"testing"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

func TestNewDotnetConfigDefaults(t *testing.T) {
	cfg := newDotnetConfig()
	if !cfg.extensionEnabled {
		t.Error("extensionEnabled default should be true")
	}
	if cfg.defaultTargetFramework != "net9.0" {
		t.Errorf("defaultTargetFramework = %q, want %q", cfg.defaultTargetFramework, "net9.0")
	}
	if cfg.nugetRepoName != "paket.rules_dotnet_nuget_packages" {
		t.Errorf("nugetRepoName = %q, want %q", cfg.nugetRepoName, "paket.rules_dotnet_nuget_packages")
	}
	if cfg.generationMode != "project" {
		t.Errorf("generationMode = %q, want %q", cfg.generationMode, "project")
	}
	if cfg.resolveOverrides == nil {
		t.Error("resolveOverrides should be initialized")
	}
}

func TestCloneIsolatesOverrides(t *testing.T) {
	cfg := newDotnetConfig()
	cfg.resolveOverrides["foo"] = "//bar"

	cloned := cfg.clone()
	cloned.resolveOverrides["baz"] = "//qux"

	if _, ok := cfg.resolveOverrides["baz"]; ok {
		t.Error("clone mutation leaked to original")
	}
}

func TestConfigureExtensionDirective(t *testing.T) {
	dl := &dotnetLang{}
	c := &config.Config{Exts: make(map[string]interface{})}

	// Initial configure — extension enabled by default
	dl.Configure(c, "", nil)
	cfg := getDotnetConfig(c)
	if !cfg.extensionEnabled {
		t.Fatal("extensionEnabled should be true by default")
	}

	// Disable via directive
	f := &rule.File{
		Directives: []rule.Directive{
			{Key: "dotnet_extension", Value: "disabled"},
		},
	}
	dl.Configure(c, "sub", f)
	cfg = getDotnetConfig(c)
	if cfg.extensionEnabled {
		t.Error("extensionEnabled should be false after disabled directive")
	}

	// Re-enable via directive
	f = &rule.File{
		Directives: []rule.Directive{
			{Key: "dotnet_extension", Value: "enabled"},
		},
	}
	dl.Configure(c, "sub/re", f)
	cfg = getDotnetConfig(c)
	if !cfg.extensionEnabled {
		t.Error("extensionEnabled should be true after enabled directive")
	}
}

func TestConfigureTargetFramework(t *testing.T) {
	dl := &dotnetLang{}
	c := &config.Config{Exts: make(map[string]interface{})}

	f := &rule.File{
		Directives: []rule.Directive{
			{Key: "dotnet_default_target_framework", Value: "net8.0"},
		},
	}
	dl.Configure(c, "", f)
	cfg := getDotnetConfig(c)
	if cfg.defaultTargetFramework != "net8.0" {
		t.Errorf("defaultTargetFramework = %q, want %q", cfg.defaultTargetFramework, "net8.0")
	}
}

func TestConfigureNugetRepoName(t *testing.T) {
	dl := &dotnetLang{}
	c := &config.Config{Exts: make(map[string]interface{})}

	f := &rule.File{
		Directives: []rule.Directive{
			{Key: "dotnet_nuget_repo_name", Value: "nuget"},
		},
	}
	dl.Configure(c, "", f)
	cfg := getDotnetConfig(c)
	if cfg.nugetRepoName != "nuget" {
		t.Errorf("nugetRepoName = %q, want %q", cfg.nugetRepoName, "nuget")
	}
}

func TestConfigureResolveOverride(t *testing.T) {
	dl := &dotnetLang{}
	c := &config.Config{Exts: make(map[string]interface{})}

	f := &rule.File{
		Directives: []rule.Directive{
			{Key: "resolve", Value: "dotnet Newtonsoft.Json //third_party:newtonsoft"},
		},
	}
	dl.Configure(c, "", f)
	cfg := getDotnetConfig(c)

	if lbl, ok := cfg.resolveOverrides["newtonsoft.json"]; !ok || lbl != "//third_party:newtonsoft" {
		t.Errorf("resolveOverrides[newtonsoft.json] = %q, want %q", lbl, "//third_party:newtonsoft")
	}
}

func TestConfigureResolveIgnoresOtherLanguages(t *testing.T) {
	dl := &dotnetLang{}
	c := &config.Config{Exts: make(map[string]interface{})}

	f := &rule.File{
		Directives: []rule.Directive{
			{Key: "resolve", Value: "go github.com/foo/bar //vendor/bar"},
		},
	}
	dl.Configure(c, "", f)
	cfg := getDotnetConfig(c)

	if len(cfg.resolveOverrides) != 0 {
		t.Errorf("resolveOverrides should be empty for non-dotnet resolve, got %v", cfg.resolveOverrides)
	}
}

func TestConfigureInheritance(t *testing.T) {
	dl := &dotnetLang{}
	c := &config.Config{Exts: make(map[string]interface{})}

	// Set parent config
	f := &rule.File{
		Directives: []rule.Directive{
			{Key: "dotnet_nuget_repo_name", Value: "nuget"},
			{Key: "dotnet_default_target_framework", Value: "net8.0"},
		},
	}
	dl.Configure(c, "", f)

	// Child directory with no directives inherits parent
	dl.Configure(c, "sub", nil)
	cfg := getDotnetConfig(c)
	if cfg.nugetRepoName != "nuget" {
		t.Errorf("inherited nugetRepoName = %q, want %q", cfg.nugetRepoName, "nuget")
	}
	if cfg.defaultTargetFramework != "net8.0" {
		t.Errorf("inherited defaultTargetFramework = %q, want %q", cfg.defaultTargetFramework, "net8.0")
	}
}

func TestKnownDirectives(t *testing.T) {
	dl := &dotnetLang{}
	directives := dl.KnownDirectives()

	expected := map[string]bool{
		"dotnet_extension":                 false,
		"dotnet_default_target_framework":  false,
		"dotnet_nuget_repo_name":           false,
		"dotnet_generation_mode":           false,
		"resolve":                          false,
	}

	for _, d := range directives {
		if _, ok := expected[d]; ok {
			expected[d] = true
		}
	}

	for name, found := range expected {
		if !found {
			t.Errorf("KnownDirectives() missing %q", name)
		}
	}
}

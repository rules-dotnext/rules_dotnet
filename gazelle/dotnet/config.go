package dotnet

import (
	"flag"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

// dotnetConfig holds configuration for the dotnet Gazelle extension.
type dotnetConfig struct {
	// defaultTargetFramework is used when a .csproj does not specify one.
	defaultTargetFramework string

	// nugetRepoName is the Bazel repository name for NuGet packages.
	nugetRepoName string

	// generationMode controls how rules are generated.
	// "project" (default): parse .csproj files
	generationMode string
}

func newDotnetConfig() *dotnetConfig {
	return &dotnetConfig{
		defaultTargetFramework: "net8.0",
		nugetRepoName:         "paket.rules_dotnet_nuget_packages",
		generationMode:        "project",
	}
}

func (cfg *dotnetConfig) clone() *dotnetConfig {
	c := *cfg
	return &c
}

func getDotnetConfig(c *config.Config) *dotnetConfig {
	cfg, ok := c.Exts[dotnetName]
	if !ok {
		return nil
	}
	return cfg.(*dotnetConfig)
}

// RegisterFlags implements config.Configurer.
func (*dotnetLang) RegisterFlags(fs *flag.FlagSet, cmd string, c *config.Config) {}

// CheckFlags implements config.Configurer.
func (*dotnetLang) CheckFlags(fs *flag.FlagSet, c *config.Config) error { return nil }

// KnownDirectives implements config.Configurer.
func (*dotnetLang) KnownDirectives() []string {
	return []string{
		"dotnet_default_target_framework",
		"dotnet_nuget_repo_name",
		"dotnet_generation_mode",
	}
}

// Configure implements config.Configurer.
func (*dotnetLang) Configure(c *config.Config, rel string, f *rule.File) {
	cfg := getDotnetConfig(c)
	if cfg == nil {
		cfg = newDotnetConfig()
		c.Exts[dotnetName] = cfg
	} else {
		cfg = cfg.clone()
		c.Exts[dotnetName] = cfg
	}
	if f == nil {
		return
	}
	for _, d := range f.Directives {
		switch d.Key {
		case "dotnet_default_target_framework":
			cfg.defaultTargetFramework = d.Value
		case "dotnet_nuget_repo_name":
			cfg.nugetRepoName = d.Value
		case "dotnet_generation_mode":
			cfg.generationMode = d.Value
		}
	}
}

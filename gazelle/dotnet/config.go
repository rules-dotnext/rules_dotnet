package dotnet

import (
	"flag"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

// dotnetConfig holds configuration for the dotnet Gazelle extension.
type dotnetConfig struct {
	// extensionEnabled controls whether the extension generates rules.
	// Set to false via "# gazelle:dotnet_extension disabled".
	extensionEnabled bool

	// defaultTargetFramework is used when a .csproj does not specify one.
	defaultTargetFramework string

	// nugetRepoName is the Bazel repository name for NuGet packages.
	nugetRepoName string

	// generationMode controls how rules are generated.
	// "project" (default): parse .csproj files
	generationMode string

	// resolveOverrides maps lowercased NuGet package names to Bazel labels.
	// Set via "# gazelle:resolve dotnet <package> <label>".
	resolveOverrides map[string]string
}

func newDotnetConfig() *dotnetConfig {
	return &dotnetConfig{
		extensionEnabled:       true,
		defaultTargetFramework: "net9.0",
		nugetRepoName:         "paket.rules_dotnet_nuget_packages",
		generationMode:        "project",
		resolveOverrides:       make(map[string]string),
	}
}

func (cfg *dotnetConfig) clone() *dotnetConfig {
	c := *cfg
	c.resolveOverrides = make(map[string]string, len(cfg.resolveOverrides))
	for k, v := range cfg.resolveOverrides {
		c.resolveOverrides[k] = v
	}
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
		"dotnet_extension",
		"dotnet_default_target_framework",
		"dotnet_nuget_repo_name",
		"dotnet_generation_mode",
		"resolve",
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
		case "dotnet_extension":
			switch d.Value {
			case "disabled":
				cfg.extensionEnabled = false
			case "enabled":
				cfg.extensionEnabled = true
			}
		case "dotnet_default_target_framework":
			cfg.defaultTargetFramework = d.Value
		case "dotnet_nuget_repo_name":
			cfg.nugetRepoName = d.Value
		case "dotnet_generation_mode":
			cfg.generationMode = d.Value
		case "resolve":
			// Parse "# gazelle:resolve dotnet <package> <label>"
			parts := strings.Fields(d.Value)
			if len(parts) >= 3 && parts[0] == "dotnet" {
				cfg.resolveOverrides[strings.ToLower(parts[1])] = parts[2]
			}
		}
	}
}

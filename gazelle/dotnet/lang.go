// Package dotnet implements a Gazelle language extension for .NET projects.
// It parses .csproj and .fsproj files to generate BUILD.bazel files with
// csharp_library, csharp_binary, csharp_test, and related rules.
package dotnet

import (
	"fmt"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

const dotnetName = "dotnet"

type dotnetLang struct{}

// NewLanguage returns a new Gazelle language extension for .NET.
func NewLanguage() language.Language {
	return &dotnetLang{}
}

// Name returns the name of this language extension.
func (*dotnetLang) Name() string { return dotnetName }

// Kinds returns the rule kinds that this extension can generate.
func (*dotnetLang) Kinds() map[string]rule.KindInfo {
	return map[string]rule.KindInfo{
		"csharp_library": {
			MatchAttrs:    []string{"srcs"},
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true, "nullable": true, "langversion": true,
				"project_sdk": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"csharp_binary": {
			MatchAny:      true,
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true, "nullable": true, "langversion": true,
				"project_sdk": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"csharp_test": {
			MatchAny:      true,
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"csharp_nunit_test": {
			MatchAny:      true,
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"fsharp_library": {
			MatchAttrs:    []string{"srcs"},
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"fsharp_binary": {
			MatchAny:      true,
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"fsharp_test": {
			MatchAny:      true,
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
		"fsharp_nunit_test": {
			MatchAny:      true,
			NonEmptyAttrs: map[string]bool{"srcs": true, "deps": true},
			MergeableAttrs: map[string]bool{
				"srcs": true, "deps": true, "target_frameworks": true,
				"resources": true,
			},
			ResolveAttrs: map[string]bool{"deps": true},
		},
	}
}

// Loads returns the .bzl files providing the rule kinds we generate.
// Deprecated in favor of ApparentLoads, but kept for non-bzlmod compatibility.
func (*dotnetLang) Loads() []rule.LoadInfo {
	return []rule.LoadInfo{
		{
			Name: "@rules_dotnet//dotnet:defs.bzl",
			Symbols: []string{
				"csharp_binary",
				"csharp_library",
				"csharp_nunit_test",
				"csharp_test",
				"fsharp_binary",
				"fsharp_library",
				"fsharp_nunit_test",
				"fsharp_test",
			},
		},
	}
}

// ApparentLoads implements ModuleAwareLanguage for bzlmod support.
func (*dotnetLang) ApparentLoads(moduleToApparentName func(string) string) []rule.LoadInfo {
	rdName := moduleToApparentName("rules_dotnet")
	if rdName == "" {
		rdName = "rules_dotnet"
	}
	return []rule.LoadInfo{
		{
			Name: fmt.Sprintf("@%s//dotnet:defs.bzl", rdName),
			Symbols: []string{
				"csharp_binary",
				"csharp_library",
				"csharp_nunit_test",
				"csharp_test",
				"fsharp_binary",
				"fsharp_library",
				"fsharp_nunit_test",
				"fsharp_test",
			},
		},
	}
}

// Fix is a no-op; no deprecated rule forms to fix yet.
func (*dotnetLang) Fix(c *config.Config, f *rule.File) {}

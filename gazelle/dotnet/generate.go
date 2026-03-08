package dotnet

import (
	"log"
	"path/filepath"
	"sort"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

// GenerateRules scans each directory for .csproj/.fsproj files and generates
// corresponding Bazel rules.
func (dl *dotnetLang) GenerateRules(args language.GenerateArgs) language.GenerateResult {
	cfg := getDotnetConfig(args.Config)
	if cfg != nil && !cfg.extensionEnabled {
		return language.GenerateResult{}
	}
	var gen []*rule.Rule
	var empty []*rule.Rule
	var imports []interface{}

	// Find project files in this directory
	var projectFiles []string
	for _, f := range args.RegularFiles {
		if strings.HasSuffix(f, ".csproj") || strings.HasSuffix(f, ".fsproj") {
			projectFiles = append(projectFiles, f)
		}
	}

	if len(projectFiles) == 0 {
		return language.GenerateResult{}
	}

	for _, projFileName := range projectFiles {
		projPath := filepath.Join(args.Dir, projFileName)
		proj, err := ParseProjectFile(projPath)
		if err != nil {
			log.Printf("gazelle/dotnet: error parsing %s: %v", projPath, err)
			continue
		}

		// Determine the rule kind
		kind := dl.ruleKind(proj)

		// Determine source files
		srcs := dl.resolveSources(proj, args.Dir, args.RegularFiles)

		// Determine target frameworks
		targetFrameworks := proj.TargetFrameworks
		if len(targetFrameworks) == 0 {
			targetFrameworks = []string{cfg.defaultTargetFramework}
		}

		// Build the rule
		r := rule.NewRule(kind, dl.ruleName(proj))
		r.SetAttr("srcs", srcs)
		r.SetAttr("target_frameworks", targetFrameworks)

		// Set optional attributes
		if proj.Nullable != "" {
			r.SetAttr("nullable", strings.ToLower(proj.Nullable))
		}
		if proj.AllowUnsafeBlocks {
			r.SetAttr("allow_unsafe_blocks", true)
		}
		if proj.LangVersion != "" {
			r.SetAttr("langversion", proj.LangVersion)
		}
		if strings.EqualFold(proj.SDK, "Microsoft.NET.Sdk.Web") {
			r.SetAttr("project_sdk", "web")
		}
		if len(proj.EmbeddedResources) > 0 {
			r.SetAttr("resources", proj.EmbeddedResources)
		}

		// deps are resolved later in Resolve(); store import metadata
		importData := &dotnetImports{
			packageRefs:   proj.PackageReferences,
			projectRefs:   proj.ProjectReferences,
			projDir:       args.Dir,
			projRel:       args.Rel,
			isNUnitTest:   kind == "csharp_nunit_test" || kind == "fsharp_nunit_test",
			testFramework: proj.TestFramework,
		}

		gen = append(gen, r)
		imports = append(imports, importData)
	}

	return language.GenerateResult{
		Gen:     gen,
		Empty:   empty,
		Imports: imports,
	}
}

// ruleKind determines the Bazel rule kind to generate for a project file.
func (dl *dotnetLang) ruleKind(proj *ProjectFile) string {
	prefix := proj.Language // "csharp" or "fsharp"

	if proj.IsTestProject {
		if proj.TestFramework == "nunit" {
			return prefix + "_nunit_test"
		}
		return prefix + "_test"
	}

	if strings.EqualFold(proj.OutputType, "Exe") ||
		strings.EqualFold(proj.OutputType, "WinExe") {
		return prefix + "_binary"
	}

	return prefix + "_library"
}

// ruleName derives a Bazel-friendly rule name from a project file.
func (dl *dotnetLang) ruleName(proj *ProjectFile) string {
	name := proj.Name
	// Replace dots and hyphens with underscores for Bazel compatibility
	name = strings.ReplaceAll(name, ".", "_")
	name = strings.ReplaceAll(name, "-", "_")
	return strings.ToLower(name)
}

// resolveSources determines the source files for a project.
func (dl *dotnetLang) resolveSources(proj *ProjectFile, dir string, regularFiles []string) []string {
	// If the .csproj explicitly lists Compile items, use those
	if len(proj.SourceFiles) > 0 {
		return proj.SourceFiles
	}

	// SDK-style projects implicitly glob all source files in the directory.
	var ext string
	switch proj.Language {
	case "csharp":
		ext = ".cs"
	case "fsharp":
		ext = ".fs"
	}

	var srcs []string
	for _, f := range regularFiles {
		if strings.HasSuffix(f, ext) {
			srcs = append(srcs, f)
		}
	}
	sort.Strings(srcs)
	return srcs
}

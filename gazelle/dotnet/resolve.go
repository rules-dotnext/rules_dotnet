package dotnet

import (
	"fmt"
	"log"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/label"
	"github.com/bazelbuild/bazel-gazelle/repo"
	"github.com/bazelbuild/bazel-gazelle/resolve"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

// dotnetImports stores dependency metadata gathered during GenerateRules,
// passed to Resolve via GenerateResult.Imports.
type dotnetImports struct {
	packageRefs   map[string]string // NuGet package name -> version
	projectRefs   []string          // Relative paths to referenced .csproj/.fsproj
	projDir       string            // Absolute path to the project directory
	projRel       string            // Repo-relative path to the project directory
	isNUnitTest   bool              // True if this is a *_nunit_test rule
	testFramework string            // Detected test framework
}

// Imports returns the import specs for indexing. Each generated rule is
// indexed by its package path + rule name so ProjectReferences can find it.
func (*dotnetLang) Imports(c *config.Config, r *rule.Rule, f *rule.File) []resolve.ImportSpec {
	if r.Kind() == "" {
		return nil
	}
	return []resolve.ImportSpec{{
		Lang: dotnetName,
		Imp:  path.Join(f.Pkg, r.Name()),
	}}
}

// Embeds returns nil; .NET rules do not have an embed concept.
func (*dotnetLang) Embeds(r *rule.Rule, from label.Label) []label.Label {
	return nil
}

// Resolve populates the deps attribute of a generated rule by mapping
// PackageReferences to NuGet labels and ProjectReferences to Bazel labels.
func (dl *dotnetLang) Resolve(
	c *config.Config,
	ix *resolve.RuleIndex,
	rc *repo.RemoteCache,
	r *rule.Rule,
	importsRaw interface{},
	from label.Label,
) {
	if importsRaw == nil {
		return
	}
	imports := importsRaw.(*dotnetImports)
	cfg := getDotnetConfig(c)

	var deps []string

	// 1. Resolve PackageReferences to NuGet labels
	for pkgName := range imports.packageRefs {
		// Skip NUnit framework packages when generating nunit_test rules,
		// since the macro injects them automatically.
		if imports.isNUnitTest && nunitInjectedPackages[pkgName] {
			continue
		}

		normalizedName := strings.ToLower(pkgName)

		// Check for user-specified resolve override first.
		if override, ok := cfg.resolveOverrides[normalizedName]; ok {
			deps = append(deps, override)
			continue
		}

		// Convert NuGet package name to Bazel label.
		// rules_dotnet convention: @<repo>//<lowercase_package_name>
		dep := fmt.Sprintf("@%s//%s", cfg.nugetRepoName, normalizedName)
		deps = append(deps, dep)
	}

	// 2. Resolve ProjectReferences to Bazel labels
	for _, projRef := range imports.projectRefs {
		lbl := dl.resolveProjectReference(imports.projDir, imports.projRel, projRef)
		if lbl != "" {
			deps = append(deps, lbl)
		}
	}

	sort.Strings(deps)

	if len(deps) > 0 {
		r.SetAttr("deps", deps)
	}
}

// resolveProjectReference converts a relative .csproj path like
// "../OtherProject/OtherProject.csproj" into a Bazel label like
// "//path/to/OtherProject:otherproject".
func (dl *dotnetLang) resolveProjectReference(projDir, projRel, ref string) string {
	// ProjectReference paths use backslashes on Windows; normalize.
	// filepath.ToSlash is a no-op on Linux, so replace explicitly.
	ref = strings.ReplaceAll(ref, "\\", "/")

	// Resolve relative to the project directory
	absRef := filepath.Join(projDir, ref)
	absRef = filepath.Clean(absRef)

	// Extract the directory and project name
	refDir := filepath.Dir(absRef)
	refBase := filepath.Base(absRef)
	refName := strings.TrimSuffix(refBase, filepath.Ext(refBase))
	refName = strings.ReplaceAll(refName, ".", "_")
	refName = strings.ReplaceAll(refName, "-", "_")
	refName = strings.ToLower(refName)

	// Compute repo-relative path for the referenced project's directory.
	var workspaceRoot string
	if projRel == "" {
		workspaceRoot = projDir
	} else {
		workspaceRoot = strings.TrimSuffix(projDir, projRel)
		workspaceRoot = strings.TrimRight(workspaceRoot, "/")
	}
	relRef, err := filepath.Rel(workspaceRoot, refDir)
	if err != nil {
		log.Printf("gazelle/dotnet: cannot resolve project reference %s: %v", ref, err)
		return ""
	}
	relRef = filepath.ToSlash(relRef)

	if relRef == "." {
		return ":" + refName
	}

	return fmt.Sprintf("//%s:%s", relRef, refName)
}

"Providers for analysis configuration"

DotnetAnalysisConfigInfo = provider(
    doc = "Configuration for Roslyn analyzer enforcement across all .NET targets.",
    fields = {
        "analyzer_files": "depset[File]: Analyzer DLL files to pass via /analyzer:",
        "global_configs": "list[File]: .globalconfig / .editorconfig files to pass via /analyzerconfig:",
        "treat_warnings_as_errors": "bool: Whether to treat all warnings as errors",
        "warnings_as_errors": "list[string]: Specific diagnostic IDs to treat as errors",
        "warnings_not_as_errors": "list[string]: Specific diagnostic IDs to exempt from warnaserror",
        "suppressed_diagnostics": "list[string]: Diagnostic IDs to suppress entirely via /nowarn:",
        "warning_level": "int: Warning level (0-5), or -1 for unset",
    },
)

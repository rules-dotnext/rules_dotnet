startup --windows_enable_symlinks
common --enable_runfiles
common --incompatible_strict_action_env
common --test_output=errors
common --incompatible_disallow_empty_glob

# Verbose failure output
common --verbose_failures

# Remote execution — activate with --config=remote
# Set endpoint and credentials in .bazelrc.user:
#   build:remote --remote_executor=grpcs://your-endpoint:port
#   build:remote --remote_cache=grpcs://your-cache:port
#   build:remote --remote_header=x-buildbuddy-api-key=YOUR_KEY
build:remote --jobs=50
build:remote --remote_timeout=600
# .NET SDK needs glibc 2.27+ and GLIBCXX_3.4.22+
build:remote --remote_default_exec_properties=container-image=docker://mcr.microsoft.com/dotnet/runtime-deps:8.0
{{#RULES_PYTHON}}
# Hermetic Python bootstrap for py_binary tools on RE workers
build:remote --@rules_python//python/config_settings:bootstrap_impl=script
{{/RULES_PYTHON}}

# Profiling — activate with --config=profile
build:profile --noslim_profile
build:profile --experimental_profile_include_target_label
build:profile --experimental_profile_include_primary_output

# Load user-specific settings (gitignored)
try-import %workspace%/.bazelrc.user

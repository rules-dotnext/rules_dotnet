@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem Usage of rlocation function:
rem        call :rlocation <runfile_path> <abs_path>
rem        The rlocation function maps the given <runfile_path> to its absolute
rem        path and stores the result in a variable named <abs_path>.
rem        This function fails if the <runfile_path> doesn't exist in manifest
rem        file.
:: Start of rlocation
goto :rlocation_end
:rlocation
if "%~2" equ "" (
  echo>&2 ERROR: Expected two arguments for rlocation function.
  exit 1
)
if "%RUNFILES_MANIFEST_ONLY%" neq "1" (
  set %~2=%~1
  exit /b 0
)
if exist "%RUNFILES_DIR%" (
  set RUNFILES_MANIFEST_FILE=%RUNFILES_DIR%_manifest
)
if "%RUNFILES_MANIFEST_FILE%" equ "" (
  set RUNFILES_MANIFEST_FILE=%~f0.runfiles\MANIFEST
)
if not exist "%RUNFILES_MANIFEST_FILE%" (
  set RUNFILES_MANIFEST_FILE=%~f0.runfiles_manifest
)
set MF=%RUNFILES_MANIFEST_FILE:/=\%
if not exist "%MF%" (
  echo>&2 ERROR: Manifest file %MF% does not exist.
  exit 1
)
set runfile_path=%~1
for /F "tokens=2* usebackq" %%i in (`%SYSTEMROOT%\system32\findstr.exe /l /c:"!runfile_path! " "%MF%"`) do (
  set abs_path=%%i
)
if "!abs_path!" equ "" (
  echo>&2 ERROR: !runfile_path! not found in runfiles manifest
  exit 1
)
set %~2=!abs_path!
exit /b 0
:rlocation_end
:: End of rlocation

set RUNFILES_MANIFEST_ONLY=1
set DOTNET_MULTILEVEL_LOOKUP=false
set DOTNET_NOLOGO=1
set DOTNET_CLI_TELEMETRY_OPTOUT=1

set dotnet_executable="TEMPLATED_dotnet"
call :rlocation "TEMPLATED_dotnet" dotnet_executable
for %%F in (%dotnet_executable%) do set DOTNET_ROOT=%%~dpF

call :rlocation "TEMPLATED_executable" run_script

rem #349 — P/Invoke native library search path
for %%F in (!run_script!) do set NATIVE_LIB_DIR=%%~dpF
set PATH=!NATIVE_LIB_DIR!;!PATH!

set args=%*
rem Escape double quotes in args
if defined args (
  set args=!args:"=\"!
)

rem NOTE: Unlike the Linux sh launcher, we do NOT cd to the assembly directory.
rem The sh launcher runs from the execroot/sandbox working directory, and the
rem runtimeconfig.json probing paths are relative to that. Changing the working
rem directory breaks: (1) deps.json assembly resolution via probing paths, and
rem (2) relative output paths when the binary is used as a tool.

rem Test sharding: signal shard awareness to Bazel
if defined TEST_SHARD_STATUS_FILE (
  type nul > "!TEST_SHARD_STATUS_FILE!"
)

rem Coverage support: when Bazel sets COVERAGE_DIR, use coverlet.console
rem TEMPLATED_coverlet_console is substituted by expand_template:
rem   - For test rules: the rlocation path of the coverlet dotnet_tool launcher
rem   - For binary rules: "NONE"
if defined COVERAGE_DIR (
  if "TEMPLATED_coverlet_console" neq "NONE" (
    call :rlocation "TEMPLATED_coverlet_console" coverlet_console
    rem Coverlet instruments DLLs in-place; Bazel outputs are read-only.
    rem Copy assembly + PDB to a writable temp directory.
    set COV_DIR=%TEMP%\coverlet_%RANDOM%
    mkdir "!COV_DIR!"
    for %%F in ("!run_script!") do set run_script_dir=%%~dpF
    copy /Y "!run_script_dir!*.dll" "!COV_DIR!" >nul 2>&1
    copy /Y "!run_script_dir!*.pdb" "!COV_DIR!" >nul 2>&1
    copy /Y "!run_script_dir!*.deps.json" "!COV_DIR!" >nul 2>&1
    copy /Y "!run_script_dir!*.runtimeconfig.json" "!COV_DIR!" >nul 2>&1
    for %%F in ("!run_script!") do set COV_ASSEMBLY=!COV_DIR!\%%~nxF
    "!coverlet_console!" "!COV_ASSEMBLY!" --target "!dotnet_executable!" --targetargs "exec !COV_ASSEMBLY! !args!" --include-test-assembly --exclude-assemblies-without-sources None --output "!COVERAGE_OUTPUT_FILE!" --format lcov
    set COV_EXIT=!ERRORLEVEL!
    rmdir /s /q "!COV_DIR!" >nul 2>&1
    exit /b !COV_EXIT!
  )
)

"!dotnet_executable!" exec "!run_script!" !args!

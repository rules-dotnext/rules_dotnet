@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

::
: This wrapper script is used because the C#/F# compilers both embed absolute paths
: into their outputs and those paths are not deterministic. The compilers also
: allow overriding these paths using pathmaps. Since the paths can not be known
: at analysis time we need to override them at execution time.
::

set DOTNET_EXECUTABLE=%1
set COMPILER=%2
for %%F in ("%COMPILER%") do set COMPILER_BASENAME=%%~nxF

set PATHMAP_FLAG=-pathmap

:: Needed because unfortunately the F# compiler uses a different flag name
if %COMPILER_BASENAME% == fsc.dll set PATHMAP_FLAG=--pathmap

set PATHMAP=%PATHMAP_FLAG%:"%cd%=."

:: --- spec-razor-blazor: editorconfig rewriting (#249) ---
:: Razor source generator requires absolute paths in analyzerconfig section headers.
:: Rewrite sentinel values in any referenced editorconfig files.
set RESP_FILE=
for %%A in (%*) do (
  set "ARG=%%~A"
  if "!ARG:~0,1!" == "@" (
    set "RESP_FILE=!ARG:~1!"
  )
)

if defined RESP_FILE if exist "!RESP_FILE!" (
  for /f "usebackq tokens=*" %%L in ("!RESP_FILE!") do (
    set "LINE=%%L"
    if "!LINE:~0,16!" == "/analyzerconfig:" (
      set "CONFIG_FILE=!LINE:~16!"
      if exist "!CONFIG_FILE!" (
        findstr /c:"__RAZOR_FILE__:" "!CONFIG_FILE!" >nul 2>&1 && (
          set "TEMP_CONFIG=!CONFIG_FILE!.resolved"
          (
            for /f "usebackq delims=" %%R in ("!CONFIG_FILE!") do (
              set "CFGLINE=%%R"
              :: Check for __RAZOR_FILE__ sentinel
              echo !CFGLINE! | findstr /c:"__RAZOR_FILE__:" >nul 2>&1 && (
                set "CFGLINE=!CFGLINE:__RAZOR_FILE__=%cd%/!"
              )
              :: Check for __RAZOR_B64__ sentinel — base64 encoding requires PowerShell
              echo !CFGLINE! | findstr /c:"__RAZOR_B64__:" >nul 2>&1 && (
                for /f "tokens=1,* delims=:" %%X in ("!CFGLINE:__RAZOR_B64__:=!") do (
                  set "B64PREFIX=%%X"
                  set "B64PATH=%%Y"
                  for /f %%B in ('powershell -NoProfile -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('!B64PATH!'))"') do (
                    set "CFGLINE=!B64PREFIX!:%%B"
                  )
                )
              )
              echo !CFGLINE!
            )
          ) > "!TEMP_CONFIG!"
          move /y "!TEMP_CONFIG!" "!CONFIG_FILE!" >nul
        )
      )
    )
  )
)
:: --- end spec-razor-blazor: #249 ---

shift
set args=%1
:loop
shift
if [%1]==[] goto afterloop
set args=%args% %1
goto loop
:afterloop

rem Escape \ and * in args before passsing it with double quote
if defined args (
  set args=!args:\=\\\\!
  set args=!args:"=\"!
)

"%DOTNET_EXECUTABLE%" %args% %PATHMAP%

@echo off
setlocal

rem Resolve this script's directory so we can find clean-sandbox.bat reliably
set "SCRIPT_DIR=%~dp0"
setx SANDBOX_ENV = "NZ"

rem Run the clean step
if exist "%SCRIPT_DIR%cleanup-sandbox.bat" (
  call "%SCRIPT_DIR%cleanup-sandbox.bat"
) else (
  echo ERROR: clean-sandbox.bat not found in "%SCRIPT_DIR%".
  exit /b 1
)

if errorlevel 1 (
  echo ERROR: Clean step failed. Aborting.
  exit /b %errorlevel%
)

rem Handle optional flag
if /I "%~1"=="--no-dart" (
  echo Running: npx ampx sandbox
  npx ampx sandbox
) else (
  echo Running: npx ampx sandbox --outputs-format dart --outputs-out-dir lib
  npx ampx sandbox --outputs-format dart --outputs-out-dir lib
)

set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
  echo Build failed with exit code %ERR%.
)
exit /b %ERR%
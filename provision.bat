@echo off
REM VELTEIN one-click provisioner for Windows. Double-click to run.
setlocal
set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%BASH%" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not exist "%BASH%" (
  echo Git Bash not found. Install Git for Windows ^(https://git-scm.com^).
  pause
  exit /b 1
)
"%BASH%" "%~dp0scripts\provision.sh"
echo.
pause

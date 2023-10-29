@echo off
Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\install.ps1

set PS_EXIT_CODE=%errorlevel%
echo Exit Code PowerShell: %PS_EXIT_CODE%
exit /b %PS_EXIT_CODE%
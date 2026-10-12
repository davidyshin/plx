@echo off
if not exist "%~dp0Install-Friends.ps1" (
  echo Extract the entire PlxTogether-Friends.zip first. Do not run this file from inside the ZIP.
  echo Open the extracted folder, then run Install-Friends.cmd beside Install-Friends.ps1 and the AddOns folder.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Friends.ps1"
pause

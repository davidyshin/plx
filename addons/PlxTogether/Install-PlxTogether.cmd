@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-PlxTogether.ps1"
if errorlevel 1 echo Installation failed. If access was denied, right-click this file and choose Run as administrator.
pause

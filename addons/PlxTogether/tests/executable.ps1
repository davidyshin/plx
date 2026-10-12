$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$output = Join-Path $project 'dist\installer'
& "$project\Build-Installer.ps1" -OutputDirectory $output
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$logo = Join-Path $project '..\..\public\paddington-bear-logo.png'
& $compiler /nologo /target:exe /main:InstallerArguments "/out:$output\ArgumentTests.exe" /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/resource:$logo,PlxTogether.Logo" "$project\installer\Setup.cs" "$PSScriptRoot\InstallerArguments.cs"
if ($LASTEXITCODE -ne 0) { throw 'Argument test compilation failed' }
& "$output\ArgumentTests.exe"
if ($LASTEXITCODE -ne 0) { throw 'Argument tests failed' }
$exe = Join-Path $output 'PlxTogether-Setup.exe'
$assembly = [Reflection.AssemblyName]::GetAssemblyName($exe)
if ($assembly.Version.ToString() -ne '0.5.0.0') { throw 'Incorrect executable version' }
$data = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($exe))
if (-not $data.Contains('requireAdministrator') -or -not $data.Contains('PlxTogether.Logo')) { throw 'Installer is missing its elevation manifest or logo resource' }
Write-Host 'Executable checks passed: compilation, version, elevation manifest, logo resource.'

param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist\installer'))
$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe' }
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework C# compiler was not found.' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$logo = Join-Path $PSScriptRoot '..\..\public\paddington-bear-logo.png'
$exe = Join-Path $OutputDirectory 'PlxTogether-Setup.exe'
& $compiler /nologo /target:winexe /optimize+ "/out:$exe" /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/win32manifest:$PSScriptRoot\installer\app.manifest" "/resource:$logo,PlxTogether.Logo" "$PSScriptRoot\installer\Setup.cs"
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
Write-Host "Built executable installer: $exe"

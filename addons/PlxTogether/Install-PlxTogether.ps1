$ErrorActionPreference = 'Stop'
$plxSource = Join-Path $PSScriptRoot 'addon\PlxTogether'
$plxGame = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_'
$plxAddons = Join-Path $plxGame 'Interface\AddOns'
$plxTarget = Join-Path $plxAddons 'PlxTogether'
if (-not (Test-Path -LiteralPath $plxGame -PathType Container)) { throw "Forever beta was not found at $plxGame" }
if (-not (Test-Path -LiteralPath (Join-Path $plxSource 'PlxTogether.toc'))) { throw 'Keep this installer next to the addon folder.' }
if (Test-Path -LiteralPath $plxTarget) {
    $plxBackup = Join-Path $PSScriptRoot ('install-backups\PlxTogether-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $plxBackup -Force | Out-Null
    Get-ChildItem -LiteralPath $plxTarget -Force | Copy-Item -Destination $plxBackup -Recurse -Force
    Write-Host "Existing addon backed up to $plxBackup"
}
New-Item -ItemType Directory -Path $plxAddons -Force | Out-Null
New-Item -ItemType Directory -Path $plxTarget -Force | Out-Null
Get-ChildItem -LiteralPath $plxSource -File | Copy-Item -Destination $plxTarget -Force
foreach ($plxFile in Get-ChildItem -LiteralPath $plxSource -File) {
    $plxInstalled = Join-Path $plxTarget $plxFile.Name
    if ((Get-FileHash -LiteralPath $plxFile.FullName).Hash -ne (Get-FileHash -LiteralPath $plxInstalled).Hash) {
        throw "Verification failed: $($plxFile.Name)"
    }
}
Write-Host "Installed and verified PlxTogether in $plxTarget" -ForegroundColor Green
if (Test-Path -LiteralPath (Join-Path $plxAddons 'HordeTogether')) {
    Write-Host 'Disable the old HordeTogether addon in the character-selection AddOns menu.' -ForegroundColor Yellow
}
Write-Host 'Restart WoW if this is a new addon. Otherwise type /reload.'
Write-Host 'Then use /plx guide for help or /plx demo to try it solo.'

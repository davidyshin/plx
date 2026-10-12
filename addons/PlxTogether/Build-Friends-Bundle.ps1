param([string]$QuestieZip)
$ErrorActionPreference = 'Stop'
$output = Join-Path $PSScriptRoot 'dist'
$stage = Join-Path $output ([Guid]::NewGuid().ToString('N'))
$package = Join-Path $stage 'PlxTogether-Friends'
New-Item -ItemType Directory -Path "$package\AddOns", "$package\ThirdParty" -Force | Out-Null
if (-not $QuestieZip) {
    $QuestieZip = Join-Path $stage 'Questie.zip'
    Invoke-WebRequest 'https://github.com/Questie/Questie/releases/download/bundle%2Fv12.0.4%2Bv1.0.5/Questie-v12.0.4%2Bv1.0.5.zip' -OutFile $QuestieZip
}
$expected = '7fb156b8814fe734f4fb382fed9fcdcc6b7b9394e2b2d72a57fdc52522fe0b9c'
if ((Get-FileHash -LiteralPath $QuestieZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Questie checksum mismatch. No bundle was published.'
}
Expand-Archive -LiteralPath $QuestieZip -DestinationPath "$package\AddOns"
foreach ($folder in @('Questie', 'QuestieDB')) {
    if (-not (Test-Path -LiteralPath "$package\AddOns\$folder" -PathType Container)) { throw "Upstream package missing $folder" }
}
Copy-Item -LiteralPath "$PSScriptRoot\addon\PlxTogether" -Destination "$package\AddOns" -Recurse
Copy-Item -LiteralPath "$PSScriptRoot\Install-Friends.ps1", "$PSScriptRoot\Install-Friends.cmd", "$PSScriptRoot\FRIENDS-INSTALL.md" -Destination $package
# Keep the upstream source, build scripts and license alongside the unmodified addons.
Invoke-WebRequest 'https://github.com/Questie/Questie/archive/29f066c.zip' -OutFile "$package\ThirdParty\Questie-source-29f066c.zip"
Invoke-WebRequest 'https://github.com/Questie/QuestieDB/archive/e0a6eaa.zip' -OutFile "$package\ThirdParty\QuestieDB-source-e0a6eaa.zip"
Invoke-WebRequest 'https://www.gnu.org/licenses/gpl-3.0.txt' -OutFile "$package\ThirdParty\GPL-3.0.txt"
@'
Questie 12.0.4 and QuestieDB 1.0.5, unmodified official bundle.
Copyright belongs to the upstream authors. Upstream notices are preserved.
Questie project license: GNU GPL version 3.
https://www.curseforge.com/wow/addons/questie/license
https://github.com/Questie/Questie/releases/tag/bundle/v12.0.4+v1.0.5
Source archives and build scripts are included alongside the addons.
PlxTogether is an independent addon, not an official Questie product.
'@ | Set-Content -LiteralPath "$package\ThirdParty\NOTICE.txt" -Encoding UTF8
$zip = Join-Path $output 'PlxTogether-Friends.zip'
Compress-Archive -LiteralPath $package -DestinationPath $zip -Force
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  PlxTogether-Friends.zip" | Set-Content -LiteralPath "$output\SHA256SUMS.txt" -Encoding ASCII
Write-Host "Ready: $zip"

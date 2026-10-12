param([string]$QuestieZip)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Download([string]$Url, [string]$Destination) {
    Write-Host "Downloading $([IO.Path]::GetFileName($Destination)) ..."
    & curl.exe --fail --location --show-error --silent --connect-timeout 20 --max-time 180 --speed-limit 1024 --speed-time 30 --retry 1 --retry-delay 2 --output "$Destination.part" $Url
    if ($LASTEXITCODE -ne 0) { throw "Download failed or timed out: $Url (curl exit $LASTEXITCODE). No complete bundle was published." }
    if ((Get-Item -LiteralPath "$Destination.part").Length -eq 0) { throw "Empty download: $Url" }
    Move-Item -LiteralPath "$Destination.part" -Destination $Destination -Force
    Write-Host "Downloaded $([math]::Round((Get-Item -LiteralPath $Destination).Length / 1MB, 1)) MiB."
}
$output = Join-Path $PSScriptRoot 'dist'
$stage = Join-Path $output ([Guid]::NewGuid().ToString('N'))
$package = Join-Path $stage 'PlxTogether-Friends'
New-Item -ItemType Directory -Path "$package\AddOns", "$package\ThirdParty" -Force | Out-Null
if (-not $QuestieZip) {
    $QuestieZip = Join-Path $stage 'Questie.zip'
    Download 'https://github.com/Questie/Questie/releases/download/bundle%2Fv12.0.4%2Bv1.0.5/Questie-v12.0.4%2Bv1.0.5.zip' $QuestieZip
}
Write-Host 'Checking the official Questie checksum ...'
$expected = '7fb156b8814fe734f4fb382fed9fcdcc6b7b9394e2b2d72a57fdc52522fe0b9c'
if ((Get-FileHash -LiteralPath $QuestieZip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Questie checksum mismatch. No bundle was published.'
}
Write-Host 'Extracting Questie and QuestieDB ...'
[IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path -LiteralPath $QuestieZip).Path, "$package\AddOns")
foreach ($folder in @('Questie', 'QuestieDB')) {
    if (-not (Test-Path -LiteralPath "$package\AddOns\$folder" -PathType Container)) { throw "Upstream package missing $folder" }
}
Copy-Item -LiteralPath "$PSScriptRoot\addon\PlxTogether" -Destination "$package\AddOns" -Recurse
Copy-Item -LiteralPath "$PSScriptRoot\Install-Friends.ps1", "$PSScriptRoot\Install-Friends.cmd", "$PSScriptRoot\FRIENDS-INSTALL.md" -Destination $package
& "$PSScriptRoot\Build-Installer.ps1" -OutputDirectory $package
# Keep the upstream source, build scripts and license alongside the unmodified addons.
Download 'https://codeload.github.com/Questie/Questie/zip/29f066c' "$package\ThirdParty\Questie-source-29f066c.zip"
Download 'https://codeload.github.com/Questie/QuestieDB/zip/e0a6eaa' "$package\ThirdParty\QuestieDB-source-e0a6eaa.zip"
foreach ($source in Get-ChildItem -LiteralPath "$package\ThirdParty" -Filter '*.zip') {
    $archive = [IO.Compression.ZipFile]::OpenRead($source.FullName)
    try { if ($archive.Entries.Count -eq 0) { throw "Empty source archive: $($source.Name)" } } finally { $archive.Dispose() }
}
Download 'https://www.gnu.org/licenses/gpl-3.0.txt' "$package\ThirdParty\GPL-3.0.txt"
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
Write-Host 'Creating the complete friends ZIP ...'
$temporaryZip = Join-Path $stage 'complete.zip'
[IO.Compression.ZipFile]::CreateFromDirectory($package, $temporaryZip, [IO.Compression.CompressionLevel]::Fastest, $true)
Move-Item -LiteralPath $temporaryZip -Destination $zip -Force
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  PlxTogether-Friends.zip" | Set-Content -LiteralPath "$output\SHA256SUMS.txt" -Encoding ASCII
Write-Host "Ready: $zip"

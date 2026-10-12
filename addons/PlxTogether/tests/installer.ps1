$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path $project ('dist\installer-test-' + [Guid]::NewGuid().ToString('N'))
$client = Join-Path $fixture 'client'
$payload = Join-Path $fixture 'package'
New-Item -ItemType Directory -Path $client, "$payload\AddOns\PlxTogether", "$payload\AddOns\Questie", "$payload\AddOns\QuestieDB" -Force | Out-Null
Set-Content -LiteralPath "$client\WowB.exe" -Value 'fixture only'
Set-Content -LiteralPath "$payload\AddOns\PlxTogether\PlxTogether.toc" -Value '## Version: fixture-v1'
Set-Content -LiteralPath "$payload\AddOns\Questie\Questie.toc" -Value 'fixture Questie'
Set-Content -LiteralPath "$payload\AddOns\QuestieDB\QuestieDB.toc" -Value 'fixture QuestieDB'
Copy-Item -LiteralPath "$project\Install-Friends.ps1" -Destination $payload
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$payload\Install-Friends.ps1" -ClientPath $client
if ($LASTEXITCODE -ne 0) { throw 'Fresh installation failed' }
$installed = "$client\Interface\AddOns\PlxTogether\PlxTogether.toc"
if ((Get-Content -LiteralPath $installed -Raw).Trim() -ne '## Version: fixture-v1') { throw 'Incorrect installed contents' }
Set-Content -LiteralPath "$payload\AddOns\PlxTogether\PlxTogether.toc" -Value '## Version: fixture-v2'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$payload\Install-Friends.ps1" -ClientPath $client
if ($LASTEXITCODE -ne 0) { throw 'Update installation failed' }
$backupFiles = @(Get-ChildItem -LiteralPath "$payload\Backups" -Filter PlxTogether.toc -Recurse)
if ($backupFiles.Count -ne 1 -or (Get-Content -LiteralPath $backupFiles[0].FullName -Raw).Trim() -ne '## Version: fixture-v1') { throw 'Previous installation was not backed up correctly' }
if ((Get-Content -LiteralPath $installed -Raw).Trim() -ne '## Version: fixture-v2') { throw 'Update did not install' }
$invalid = Join-Path $fixture 'not-a-client'
New-Item -ItemType Directory -Path $invalid | Out-Null
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$payload\Install-Friends.ps1" -ClientPath $invalid
if ($LASTEXITCODE -eq 0 -or (Test-Path -LiteralPath "$invalid\Interface")) { throw 'Invalid game folder should fail before writing' }
$sourceOnly = Join-Path $fixture 'source-only'
New-Item -ItemType Directory -Path $sourceOnly | Out-Null
Copy-Item -LiteralPath "$project\Install-Friends.ps1" -Destination $sourceOnly
$message = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$sourceOnly\Install-Friends.ps1" -ClientPath $client
if ($LASTEXITCODE -eq 0 -or ($message -join ' ') -notmatch 'not the complete installer package') { throw 'Source-only ZIP should explain the missing package before asking for a game folder' }
Write-Host 'Installer integration checks passed: beta executable, fresh install, verified update, backup, invalid-client and source-only rejection.'
exit 0

param([string]$ClientPath)
$ErrorActionPreference = 'Stop'
try {
    $packageRoot = $PSScriptRoot
    if ((Split-Path $PSScriptRoot -Leaf) -eq 'Support') { $packageRoot = Split-Path $PSScriptRoot -Parent }
    $source = Join-Path $packageRoot 'AddOns'
    if (-not (Test-Path -LiteralPath "$source\PlxTogether\PlxTogether.toc") -or -not (Test-Path -LiteralPath "$source\Questie") -or -not (Test-Path -LiteralPath "$source\QuestieDB")) {
        throw 'This is not the complete installer package. Download PlxTogether-Friends.zip from https://github.com/davidyshin/plx/releases/tag/plxtogether-v0.6.0 (not Source code), extract the whole ZIP, and run the installer beside its AddOns folder. If using the source repository, first run Build-Friends-Bundle.ps1, then extract dist\PlxTogether-Friends.zip.'
    }
    if (-not $ClientPath) {
        $default = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_'
        $answer = Read-Host "Forever client folder (Enter for $default)"
        $ClientPath = if ($answer) { $answer.Trim('"') } else { $default }
    }
    $client = (Resolve-Path -LiteralPath $ClientPath).Path
    $executables = @('WowB.exe', 'Wow.exe', 'WowClassic.exe')
    $found = @($executables | Where-Object { Test-Path -LiteralPath (Join-Path $client $_) })
    if (-not $found.Count) { throw 'A WoW executable was not found. Choose your Forever client folder.' }
    $running = Get-Process -Name WowB,Wow,WowClassic -ErrorAction SilentlyContinue
    if ($running) { throw 'Close World of Warcraft before installing.' }
    $addons = Join-Path $client 'Interface\AddOns'
    $folders = @(Get-ChildItem -LiteralPath $source -Directory)
    New-Item -ItemType Directory -Path $addons -Force | Out-Null
    $backup = Join-Path $packageRoot ('Backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N'))
    foreach ($folder in $folders) {
        $target = Join-Path $addons $folder.Name
        if (Test-Path -LiteralPath $target) {
            New-Item -ItemType Directory -Path $backup -Force | Out-Null
            Copy-Item -LiteralPath $target -Destination $backup -Recurse -Force
        }
    }
    foreach ($folder in $folders) {
        Copy-Item -LiteralPath $folder.FullName -Destination $addons -Recurse -Force
        foreach ($file in Get-ChildItem -LiteralPath $folder.FullName -File -Recurse) {
            $relative = $file.FullName.Substring($folder.FullName.Length + 1)
            $installed = Join-Path (Join-Path $addons $folder.Name) $relative
            if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $installed).Hash) { throw "Verification failed: $installed" }
        }
    }
    Write-Host 'Installed and verified PlxTogether + Questie. Enable them in the character-selection AddOns list. Type /plx demo to preview solo.' -ForegroundColor Green
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception -is [System.UnauthorizedAccessException]) {
        Write-Host 'Windows denied access. Run PlxTogether-Setup.exe and approve the Windows prompt. Manual installation is described in README.txt.'
    }
    exit 1
}

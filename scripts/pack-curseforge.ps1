# Builds a CurseForge-ready zip: BanterCombat/<addon files> at the archive root.
# Usage: powershell -ExecutionPolicy Bypass -File scripts/pack-curseforge.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$addon = Join-Path $root "BanterCombat"
$toc = Join-Path $addon "BanterCombat.toc"

if (-not (Test-Path $toc)) {
  throw "Missing BanterCombat.toc"
}

$version = $null
Get-Content $toc | ForEach-Object {
  if ($_ -match '^##\s*Version:\s*(.+)\s*$') {
    $version = $Matches[1].Trim()
  }
}
if (-not $version) {
  throw "Could not read ## Version from BanterCombat.toc"
}

$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$zipName = "BanterCombat-$version.zip"
$zipPath = Join-Path $dist $zipName
if (Test-Path $zipPath) {
  Remove-Item -Force $zipPath
}

$stage = Join-Path $dist "_stage"
if (Test-Path $stage) {
  Remove-Item -Recurse -Force $stage
}
$stageAddon = Join-Path $stage "BanterCombat"
New-Item -ItemType Directory -Force -Path $stageAddon | Out-Null

$excludeDirs = @('.git', '.agents', 'docs')
Get-ChildItem -Path $addon -Force | ForEach-Object {
  if ($excludeDirs -contains $_.Name) { return }
  Copy-Item -Path $_.FullName -Destination (Join-Path $stageAddon $_.Name) -Recurse -Force
}

# CurseForge / Minion expect BanterCombat/ at zip root — no Interface/AddOns wrapper.
Compress-Archive -Path $stageAddon -DestinationPath $zipPath -Force
Remove-Item -Recurse -Force $stage

Write-Host "Created $zipPath"
Write-Host "Upload this file on CurseForge → Upload Files (Classic Era / your listed clients)."
Write-Host "Zip root must show: BanterCombat/BanterCombat.toc"

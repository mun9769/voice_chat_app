# Waits for the latest GitHub Actions iOS build to finish, then downloads the ipa into .\builds
# Usage: .\get_ipa.ps1
$ErrorActionPreference = 'Stop'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
Set-Location $PSScriptRoot

$runId = & $gh run list --workflow ios.yml --limit 1 --json databaseId -q '.[0].databaseId'
Write-Host "Build run $runId - waiting for it to finish..."
& $gh run watch $runId --exit-status --interval 20
if ($LASTEXITCODE -ne 0) { Write-Host 'Build failed.'; exit 1 }

$out = Join-Path $PSScriptRoot 'builds'
New-Item -ItemType Directory -Force $out | Out-Null
Remove-Item (Join-Path $out 'voice_chat_app.ipa') -ErrorAction SilentlyContinue
& $gh run download $runId -n voice_chat_app-ipa -D $out
Write-Host "Done: $out\voice_chat_app.ipa"

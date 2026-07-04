# get the guest network adapter alias -> state (Set-VmNetwork reads it back)

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$ifAlias = (Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name
if (-not $ifAlias) { $ifAlias = (Get-NetAdapter -Physical | Select-Object -First 1).Name }
if (-not $ifAlias) { Write-Host "No physical network adapter in guest."; exit 1 }

Write-Host "<<set::state.vm.interfaceAlias=$ifAlias>>"
Write-Host "Guest adapter: $ifAlias"

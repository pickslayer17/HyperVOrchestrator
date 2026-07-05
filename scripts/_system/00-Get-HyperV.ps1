# host: is the Hyper-V role present/usable -> "true" | "false"
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$present = $false
$feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($feature -and $feature.State -eq 'Enabled') { $present = $true }
if (-not $present -and (Get-Command Get-VM -ErrorAction SilentlyContinue)) { $present = $true }

if ($present) { "true" } else { "false" }

# Apply every registry tweak from the shared list: telemetry/privacy off, focus
# thieves silenced, Edge tamed, update/sleep/OneDrive backing values, Explorer QoL.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject:scriptHelpers/RegistryHelpers.ps1>>
<<inject:scriptData/RegistryTweaks.ps1>>

Set-RegTweaks -Tweaks $RegistryTweaks

Write-Host "Applied $($RegistryTweaks.Count) registry tweaks."

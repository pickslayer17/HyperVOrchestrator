# Apply every registry tweak from the shared list: telemetry/privacy off, focus
# thieves silenced, Edge tamed, update/sleep/OneDrive backing values, Explorer QoL.
# Runs as TestUser (admin), NOT SYSTEM: HKCU tweaks must land in TestUser's hive, and
# under a SYSTEM task they would silently go to the SYSTEM profile instead.
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/RegistryTweaks.ps1>>

Set-MissingRegTweaks -Tweaks $RegistryTweaks

Write-Host "Registry tweaks applied."

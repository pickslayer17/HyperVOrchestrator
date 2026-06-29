# exit 2 = every registry tweak already applied ; exit 0 = at least one missing.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject:scriptHelpers/RegistryHelpers.ps1>>
<<inject:scriptData/RegistryTweaks.ps1>>

# smoke: HKCU must be loaded for the user we run as (per-user keys live there)
if (-not (Test-Path "HKCU:\Software")) {
    Write-Host "smoke fail: HKCU hive not available."
    return 1
}

# done? verify EVERY entry in the shared list — no representative sampling.
$missing = Get-MissingRegTweak -Tweaks $RegistryTweaks
if ($missing) {
    Write-Host "todo: $($missing.Path)\$($missing.Name) != $($missing.Value)."
    return 0
}

Write-Host "already done: all $($RegistryTweaks.Count) registry tweaks applied."
return 2

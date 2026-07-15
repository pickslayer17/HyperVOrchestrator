# exit 2 = every registry tweak already applied ; exit 0 = at least one missing.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/RegistryTweaks.ps1>>

# smoke: HKCU must be loaded for the user we run as (per-user keys live there)
if (-not (Test-Path "HKCU:\Software")) {
    Write-Host "smoke fail: HKCU hive not available."
    exit 1
}

# Only list what is actually missing (needs setting); count the rest.
$missingTweaks = [System.Collections.Generic.List[string]]::new()
$appliedCount = 0
foreach ($tweak in $RegistryTweaks) {
    if (Test-RegValue -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value) {
        $appliedCount++
    } else {
        $missingTweaks.Add("$($tweak.Path)\$($tweak.Name)")
    }
}

if ($missingTweaks.Count -gt 0) {
    Write-Host "$appliedCount applied, $($missingTweaks.Count) missing (need setting):"
    $missingTweaks | ForEach-Object { Write-Host "  $_" }
    exit 0
}
Write-Host "already done: all $($RegistryTweaks.Count) registry tweaks applied."
exit 2

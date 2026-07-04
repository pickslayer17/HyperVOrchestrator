# exit 2 = every registry tweak already applied ; exit 0 = at least one missing.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/RegistryTweaks.ps1>>

# smoke: HKCU must be loaded for the user we run as (per-user keys live there)
if (-not (Test-Path "HKCU:\Software")) {
    Write-Host "smoke fail: HKCU hive not available."
    return 1
}

# Only list what is actually missing (needs setting); count the rest.
$missing = [System.Collections.Generic.List[string]]::new()
$appliedCount = 0
foreach ($t in $RegistryTweaks) {
    if (Test-RegValue -Path $t.Path -Name $t.Name -Value $t.Value) {
        $appliedCount++
    } else {
        $missing.Add("$($t.Path)\$($t.Name)")
    }
}

if ($missing.Count -gt 0) {
    Write-Host "$appliedCount applied, $($missing.Count) missing (need setting):"
    $missing | ForEach-Object { Write-Host "  $_" }
    return 0
}
Write-Host "already done: all $($RegistryTweaks.Count) registry tweaks applied."
return 2

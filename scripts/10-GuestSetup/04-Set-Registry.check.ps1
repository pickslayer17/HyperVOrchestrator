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

# Collect a per-item report; print it only if there is work to do, otherwise one line.
$report = [System.Collections.Generic.List[string]]::new()
$needsWork = $false
foreach ($t in $RegistryTweaks) {
    $key = "$($t.Path)\$($t.Name)"
    if (Test-RegValue -Path $t.Path -Name $t.Name -Value $t.Value) {
        $report.Add("'$key': applied")
    } else {
        $report.Add("'$key': missing (needs to be set)")
        $needsWork = $true
    }
}

if ($needsWork) {
    $report | ForEach-Object { Write-Host $_ }
    return 0
}
Write-Host "already done: all $($RegistryTweaks.Count) registry tweaks applied."
return 2

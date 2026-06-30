# return 2 = services disabled + sleep off + footprint trimmed ; 0 = work to do.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/Services.ps1>>

# smoke: the services we intend to disable must exist on this OS
foreach ($s in $ServicesToDisable) {
    if ($s -eq 'dmwappushservice') { continue }  # optional on some builds
    if (-not (Get-Service -Name $s -ErrorAction Stop)) {
        Write-Host "smoke fail: service '$s' not found on this OS."
        return 1
    }
}

# Collect a per-item report; print it only if there is work to do, otherwise one line.
$report = [System.Collections.Generic.List[string]]::new()
$needsWork = $false

foreach ($s in $ServicesToDisable) {
    if (Test-ServiceDisabled -Name $s) {
        $report.Add("'$s': disabled")
    } else {
        $report.Add("'$s': enabled (needs disabling)")
        $needsWork = $true
    }
}

foreach ($r in $ServiceRegStart) {
    $key = "$($r.Path)\$($r.Name)"
    if (Test-RegValue -Path $r.Path -Name $r.Name -Value $r.Value) {
        $report.Add("'$key': applied")
    } else {
        $report.Add("'$key': missing (needs to be set)")
        $needsWork = $true
    }
}

if (Test-NoSleepTimeouts)        { $report.Add("'sleep timeouts': off") }        else { $report.Add("'sleep timeouts': still set (needs disabling)"); $needsWork = $true }
if (Test-PageFileFixed)          { $report.Add("'page file': fixed") }            else { $report.Add("'page file': not fixed (needs fixing)"); $needsWork = $true }
if (Test-ReservedStorageDisabled){ $report.Add("'reserved storage': disabled") } else { $report.Add("'reserved storage': enabled (needs disabling)"); $needsWork = $true }

if ($needsWork) {
    $report | ForEach-Object { Write-Host $_ }
    return 0
}
Write-Host "already done: services disabled, sleep off, footprint trimmed."
return 2

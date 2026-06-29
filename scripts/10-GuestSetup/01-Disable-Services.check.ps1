# return 2 = services disabled + sleep off + footprint trimmed ; 0 = work to do.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject:scriptHelpers/SystemHelpers.ps1>>
<<inject:scriptHelpers/RegistryHelpers.ps1>>
<<inject:scriptData/Services.ps1>>

# smoke: the services we intend to disable must exist on this OS
foreach ($s in $ServicesToDisable) {
    if ($s -eq 'dmwappushservice') { continue }  # optional on some builds
    if (-not (Get-Service -Name $s -ErrorAction SilentlyContinue)) {
        Write-Host "smoke fail: service '$s' not found on this OS."
        return 1
    }
}

# done? every service Disabled
foreach ($s in $ServicesToDisable) {
    if (-not (Test-ServiceDisabled -Name $s)) { Write-Host "todo: service '$s' not Disabled."; return 0 }
}

# done? DoSvc registry start value applied
foreach ($r in $ServiceRegStart) {
    if (-not (Test-RegValue -Path $r.Path -Name $r.Name -Value $r.Value)) {
        Write-Host "todo: $($r.Path)\$($r.Name) not set."; return 0
    }
}

# done? no sleep timeouts, page file fixed, reserved storage off
if (-not (Test-NoSleepTimeouts))        { Write-Host "todo: sleep/idle timeouts still set."; return 0 }
if (-not (Test-PageFileFixed))          { Write-Host "todo: page file not fixed."; return 0 }
if (-not (Test-ReservedStorageDisabled)){ Write-Host "todo: reserved storage not disabled."; return 0 }

Write-Host "already done: services disabled, sleep off, footprint trimmed."
return 2

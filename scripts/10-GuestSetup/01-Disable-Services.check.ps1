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

# Only list what still needs doing; count what's already done.
$todo = [System.Collections.Generic.List[string]]::new()
$doneCount = 0

foreach ($s in $ServicesToDisable) {
    if (Test-ServiceDisabled -Name $s) { $doneCount++ } else { $todo.Add("service $s (enable->disable)") }
}
foreach ($r in $ServiceRegStart) {
    if (Test-RegValue -Path $r.Path -Name $r.Name -Value $r.Value) { $doneCount++ } else { $todo.Add("reg $($r.Path)\$($r.Name)") }
}
if (Test-NoSleepTimeouts)        { $doneCount++ } else { $todo.Add("sleep timeouts") }
if (Test-PageFileFixed)          { $doneCount++ } else { $todo.Add("page file") }
if (Test-ReservedStorageDisabled){ $doneCount++ } else { $todo.Add("reserved storage") }

if ($todo.Count -gt 0) {
    Write-Host "$doneCount done, $($todo.Count) need work:"
    $todo | ForEach-Object { Write-Host "  $_" }
    return 0
}
Write-Host "already done: services disabled, sleep off, footprint trimmed."
return 2

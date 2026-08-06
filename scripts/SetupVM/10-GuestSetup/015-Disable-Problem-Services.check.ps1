# exit 2 = all problem services disabled (Start=4) ; 0 = work to do ; 1 = OS mismatch.
# These go via registry so we verify Start=4 directly, not StartMode (ACL blocks Set-Service).

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptData/ProblemServices.ps1>>

$todo = [System.Collections.Generic.List[string]]::new()
$doneCount = 0

foreach ($service in $ProblemServices) {
    $start = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$service" -Name Start -ErrorAction SilentlyContinue).Start
    if ($null -eq $start) {
        Write-Host "smoke fail: service '$service' not found on this OS."
        exit 1
    }
    if ($start -eq 4) { $doneCount++ } else { $todo.Add("$service (Start=$start, want 4)") }
}

if ($todo.Count -gt 0) {
    Write-Host "$doneCount done, $($todo.Count) need work:"
    $todo | ForEach-Object { Write-Host "  $_" }
    exit 0
}
Write-Host "already done: all problem services Start=4."
exit 2

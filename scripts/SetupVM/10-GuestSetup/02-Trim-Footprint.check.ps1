# exit 2 = sleep off + page file fixed + reserved storage disabled ; 0 = work to do.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>

# Only list what still needs doing; count what's already done.
$todo = [System.Collections.Generic.List[string]]::new()
$doneCount = 0

if (Test-NoSleepTimeouts)         { $doneCount++ } else { $todo.Add("sleep timeouts") }
if (Test-PageFileFixed)           { $doneCount++ } else { $todo.Add("page file") }
if (Test-ReservedStorageDisabled) { $doneCount++ } else { $todo.Add("reserved storage") }

if ($todo.Count -gt 0) {
    Write-Host "$doneCount done, $($todo.Count) need work:"
    $todo | ForEach-Object { Write-Host "  $_" }
    return 0
}
Write-Host "already done: sleep off, footprint trimmed."
return 2

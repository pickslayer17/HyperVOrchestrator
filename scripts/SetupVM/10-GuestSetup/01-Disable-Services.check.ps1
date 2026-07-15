# exit 2 = services disabled + reg start applied ; 0 = work to do.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/Services.ps1>>

# smoke: the services we intend to disable must exist on this OS
foreach ($service in $ServicesToDisable) {
    if ($service -eq 'dmwappushservice') { continue }  # optional on some builds
    if (-not (Get-Service -Name $service -ErrorAction Stop)) {
        Write-Host "smoke fail: service '$service' not found on this OS."
        exit 1
    }
}

# Only list what still needs doing; count what's already done.
$todo = [System.Collections.Generic.List[string]]::new()
$doneCount = 0

foreach ($service in $ServicesToDisable) {
    if (Test-ServiceDisabled -Name $service) { $doneCount++ } else { $todo.Add("service $service (enable->disable)") }
}
foreach ($registryEntry in $ServiceRegStart) {
    if (Test-RegValue -Path $registryEntry.Path -Name $registryEntry.Name -Value $registryEntry.Value) { $doneCount++ } else { $todo.Add("reg $($registryEntry.Path)\$($registryEntry.Name)") }
}

if ($todo.Count -gt 0) {
    Write-Host "$doneCount done, $($todo.Count) need work:"
    $todo | ForEach-Object { Write-Host "  $_" }
    exit 0
}
Write-Host "already done: services disabled, reg start applied."
exit 2

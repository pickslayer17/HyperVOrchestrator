# Hard-disable update/telemetry services that survive a normal disable and get revived
# on reboot by WaaSMedicSvc. Runs as SYSTEM (registry Start=4 + process kill), because
# these services deny Set-Service even to admins. See scriptData/ProblemServices.ps1.

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptData/ProblemServices.ps1>>

foreach ($service in $ProblemServices) {
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\$service" /v Start /t REG_DWORD /d 4 /f | Out-Null
    Stop-Service $service -Force -ErrorAction SilentlyContinue
    $serviceInfo = Get-CimInstance Win32_Service -Filter "Name='$service'" -ErrorAction SilentlyContinue
    if ($serviceInfo -and $serviceInfo.ProcessId -gt 0) {
        Stop-Process -Id $serviceInfo.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Write-Host "'$service': Start=4 (disabled), process killed"
}

Write-Host "Problem services disabled."

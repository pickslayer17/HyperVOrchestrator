$ScriptTarget = "Host"
# check для 00-Set-HostNetwork: нужны админ-права и Hyper-V модуль.
# exit 0 = можно запускать основной скрипт.

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Not running as Administrator."
    exit 1
}
if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Host "Hyper-V PowerShell module not available."
    exit 1
}

Write-Host "Host ready for network setup."
exit 0

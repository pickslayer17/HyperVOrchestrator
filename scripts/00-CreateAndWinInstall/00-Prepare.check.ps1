$ScriptTarget = "Host"
# check для 00-Prepare: без Hyper-V и админ-прав вся цепочка бессмысленна.
# exit 0 = можно запускать основной скрипт.

# Админ?
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Not running as Administrator."
    exit 1
}

# Hyper-V модуль доступен?
if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
    Write-Host "Hyper-V PowerShell module not available."
    exit 1
}

Write-Host "Host ready for prepare."
exit 0

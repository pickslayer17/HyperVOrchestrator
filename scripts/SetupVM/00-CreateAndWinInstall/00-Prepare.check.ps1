# require admin + hyper-v

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host "Not running as Administrator."; exit 1 }
if (-not (Get-Module -ListAvailable -Name Hyper-V)) { Write-Host "Hyper-V module not available."; exit 1 }

Write-Host "Host ready for prepare."
exit 0

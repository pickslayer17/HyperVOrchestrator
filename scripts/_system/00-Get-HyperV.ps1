# host: is the Hyper-V role present/usable -> "true" | "false"
# checks for the Hyper-V PowerShell module (installed with the role) instead of
# Get-WindowsOptionalFeature -Online, which spins up DISM and can hang for minutes.
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$present = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)

if ($present) { "true" } else { "false" }

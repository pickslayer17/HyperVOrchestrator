$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$officeApp = "@@state.vm.officeApp@@".Trim()
$value = [System.Environment]::GetEnvironmentVariable($officeApp, "Machine")

if ($value -eq "True") {
    Write-Host "environment variable already set: $officeApp=True"
    exit 2
}
Write-Host "environment variable not set."
exit 0

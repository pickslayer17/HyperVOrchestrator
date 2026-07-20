$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$officeApp = "@@state.vm.officeApp@@".Trim()
if (-not $officeApp) { throw "office app is empty" }

[System.Environment]::SetEnvironmentVariable($officeApp, "True", "Machine")

Write-Host "environment variable set: $officeApp=True (Machine)"

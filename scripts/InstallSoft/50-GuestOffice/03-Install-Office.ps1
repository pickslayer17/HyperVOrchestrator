$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestOfficeDir@@"
$process = Start-Process -FilePath (Join-Path $guestDir "setup.exe") -ArgumentList '/configure',(Join-Path $guestDir "configuration.xml") -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "setup.exe /configure failed with exit $($process.ExitCode)" }
Write-Host "Office installed (exit 0)."

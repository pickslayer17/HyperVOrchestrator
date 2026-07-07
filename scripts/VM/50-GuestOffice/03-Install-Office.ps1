$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$process = Start-Process -FilePath 'C:\office_cache\setup.exe' -ArgumentList '/configure','C:\office_cache\configuration.xml' -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "setup.exe /configure failed with exit $($process.ExitCode)" }
Write-Host "Office installed (exit 0)."

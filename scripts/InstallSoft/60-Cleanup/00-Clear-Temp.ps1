# clear temp files + dism component cleanup

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

function Remove-CleanupPath {
	param([Parameter(Mandatory)][string]$Path)

	if (-not (Test-Path -Path $Path)) { return }
	try {
		Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
	} catch {
		Write-Warning "Failed to remove '$Path': $($_.Exception.Message)"
	}
}

dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
$dismExitCode = $LASTEXITCODE
if ($dismExitCode -notin @(0, 3010)) {
	throw "DISM component cleanup failed with exit code $dismExitCode."
}

@(
	'C:\Windows\SoftwareDistribution\Download\*'
	'C:\Windows\Temp\*'
	"$env:LOCALAPPDATA\Temp\*"
	'C:\Windows\Prefetch\*'
	'C:\office_cache'
) | ForEach-Object { Remove-CleanupPath -Path $_ }

Write-Host "Cleanup done."

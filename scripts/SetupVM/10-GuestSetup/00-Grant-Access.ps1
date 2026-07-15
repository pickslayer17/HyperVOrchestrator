# Grant the test user full control over C: — foundation for everything that
# follows (later steps write into protected locations).

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

# /C keeps going past locked files. Only DumpStack.log.tmp is expected to be locked
# on a fresh VM and is ignored; ANY other failure is real and fails the step.
$ErrorActionPreference = "Continue"
$icaclsOutput = icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /C /Q 2>&1 | ForEach-Object { "$_" }
$icaclsExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"
$dumpStackErrors = @($icaclsOutput | Where-Object { $_ -match 'DumpStack\.log\.tmp' })
$realErrors = @($icaclsOutput | Where-Object {
    $_ -match '^\s*"?[A-Za-z]:\\' -and $_ -notmatch 'DumpStack\.log\.tmp'
})
if ($realErrors) {
    $realErrors | ForEach-Object { Write-Host $_ }
    throw "icacls failed on files other than DumpStack.log.tmp."
}
if ($icaclsExitCode -ne 0 -and $dumpStackErrors.Count -eq 0) {
    $icaclsOutput | ForEach-Object { Write-Host $_ }
    throw "icacls failed with exit code $icaclsExitCode."
}
Write-Host "$vmUser has full control over C:\"

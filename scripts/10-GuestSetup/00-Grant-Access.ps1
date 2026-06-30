# Grant the test user full control over C: — foundation for everything that
# follows (later steps write into protected locations).

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

# /C keeps going past locked files. Only DumpStack.log.tmp is expected to be locked
# on a fresh VM and is ignored; ANY other failure is real and fails the step.
$out = icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /C /Q 2>&1
$realErrors = $out | Where-Object { $_ -match 'Failed' -and $_ -notmatch 'DumpStack\.log\.tmp' }
if ($realErrors) {
    $realErrors | ForEach-Object { Write-Host $_ }
    throw "icacls failed on files other than DumpStack.log.tmp."
}
Write-Host "$vmUser has full control over C:\"

# Grant the test user full control over C: — foundation for everything that
# follows (later steps write into protected locations).

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

$ErrorActionPreference = "Continue"
icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /Q 2>&1 | Out-Null
$icaclsExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

$accessControlList = Get-Acl "C:\"
$fullControlAccess = $accessControlList.Access | Where-Object {
    $_.IdentityReference -like "*\$vmUser" -and
    $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl -and
    $_.AccessControlType -eq 'Allow'
}
if (-not $fullControlAccess) { throw "icacls did not grant FullControl on C:\ (exit $icaclsExitCode)." }
Write-Host "$vmUser has full control over C:\"

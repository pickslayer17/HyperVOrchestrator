# exit 2 = user already has FullControl on C: ; exit 0 = needs granting.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

# smoke: the account we are about to grant must actually exist
if (-not (Get-LocalUser -Name $vmUser -ErrorAction SilentlyContinue)) {
    Write-Host "smoke fail: local user '$vmUser' does not exist."
    return 1
}

# done? the user already holds FullControl over C:\ (inheritance flags included)
$acl = Get-Acl "C:\"
$has = $acl.Access | Where-Object {
    $_.IdentityReference -like "*\$vmUser" -and
    $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl -and
    $_.AccessControlType -eq 'Allow'
}
if ($has) { Write-Host "already done: $vmUser has FullControl on C:\"; return 2 }

return 0

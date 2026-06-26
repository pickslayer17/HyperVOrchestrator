# grant user full access to C:

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /Q
Write-Host "$vmUser has full access to C:\"

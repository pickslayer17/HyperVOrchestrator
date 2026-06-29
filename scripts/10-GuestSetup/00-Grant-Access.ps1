# Grant the test user full control over C: — foundation for everything that
# follows (later steps write into protected locations).

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /Q
Write-Host "$vmUser has full control over C:\"

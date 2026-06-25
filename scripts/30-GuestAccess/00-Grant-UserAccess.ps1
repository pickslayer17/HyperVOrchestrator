#:target vm
# 00 - Дать пользователю full access на C:\ внутри ВМ.
#
# Перенесено из setup_access/user_full_access.ps1.
# #:target vm -> оркестратор заворачивает в Invoke-Command -VMName сам.

$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /Q
Write-Host "$vmUser has full access to C:\"

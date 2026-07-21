$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/RebootHelpers.ps1>>

Invoke-GuestReboot

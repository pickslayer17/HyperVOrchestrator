# host: name of the existing NAT, or "" if none
$ErrorActionPreference = "Stop"

$natName = ""
$natEntry = Get-NetNat -ErrorAction SilentlyContinue | Select-Object -First 1
if ($natEntry) { $natName = $natEntry.Name }
"$natName"

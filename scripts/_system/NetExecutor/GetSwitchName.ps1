# host: name of the internal (NAT-backed) switch, or "" if none
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = ""
$internalSwitch = Get-VMSwitch -SwitchType Internal -ErrorAction SilentlyContinue | Select-Object -First 1
if ($internalSwitch) { $switchName = $internalSwitch.Name }
"$switchName"

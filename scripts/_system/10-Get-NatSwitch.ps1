# host: name of the NAT-backed internal switch, or "" if none
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = ""
$natEntry = Get-NetNat -ErrorAction SilentlyContinue | Select-Object -First 1
if ($natEntry) {
    $internalSwitch = Get-VMSwitch -SwitchType Internal -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($internalSwitch) { $switchName = $internalSwitch.Name }
}

"$switchName"

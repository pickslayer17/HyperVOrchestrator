# host: name of the NAT-backed internal switch, or "" if none
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$name = ""
$nat = Get-NetNat -ErrorAction SilentlyContinue | Select-Object -First 1
if ($nat) {
    $sw = Get-VMSwitch -SwitchType Internal -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sw) { $name = $sw.Name }
}

"$name"

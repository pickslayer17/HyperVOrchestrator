# Temporary stopper: hard-fails so a full run halts after guest setup.
# Remove once the later suites are wired in.
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmHost = "@@vm.host@@"

Start-Process vmconnect -ArgumentList $vmHost, $vmName
throw "STOP: intentional halt after guest setup."

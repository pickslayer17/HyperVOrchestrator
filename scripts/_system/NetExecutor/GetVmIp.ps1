$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$ip = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue |
      Select-Object -First 1 -ExpandProperty IPAddresses |
      Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } |
      Select-Object -First 1
"$ip"

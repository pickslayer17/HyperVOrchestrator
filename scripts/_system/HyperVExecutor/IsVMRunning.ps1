param(
	[string]$VmName
)
$ErrorActionPreference = "Stop"

$vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if ($vm -and $vm.State -eq 'Running') { "true" } else { "false" }

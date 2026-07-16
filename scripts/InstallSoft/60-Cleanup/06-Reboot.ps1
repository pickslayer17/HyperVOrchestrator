$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"

$vm = Get-VM -Name $vmName
if ($vm.State -eq 'Running') {
	Write-Host "Restarting VM..."
	Restart-VM -VM $vm -Force
} elseif ($vm.State -in @('Off', 'Saved')) {
	Write-Host "Starting VM..."
	Start-VM -VM $vm
} elseif ($vm.State -eq 'Paused') {
	Write-Host "Resuming VM..."
	Resume-VM -VM $vm
} else {
	throw "VM '$vmName' cannot be restarted from state '$($vm.State)'."
}
Write-Host "VM power transition issued."

# create gen2 vm from vhdx, with tpm

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$memoryGb = @@vm.memoryGb@@
$cpuCount = @@vm.cpuCount@@
$vhdPath = Join-Path "@@paths.vmDir@@" "$vmName.vhdx"

Write-Host "Creating VM..."
New-VM -Name $vmName -MemoryStartupBytes $memoryGb -Generation 2 -VHDPath $vhdPath
Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true -MinimumBytes 1GB -MaximumBytes $memoryGb
Set-VMProcessor -VMName $vmName -Count $cpuCount
Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
Enable-VMTPM -VMName $vmName
Write-Host "VM created with TPM."

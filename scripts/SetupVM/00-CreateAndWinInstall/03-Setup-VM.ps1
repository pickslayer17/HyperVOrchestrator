# configure vm: dynamic memory, video, basic enhanced session

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$videoWidth = @@vm.videoWidth@@
$videoHeight = @@vm.videoHeight@@
$memoryGb = @@vm.memoryGb@@

Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 1GB -MaximumBytes $memoryGb
Set-VMVideo -VMName $vmName -HorizontalResolution $videoWidth -VerticalResolution $videoHeight -ResolutionType Single
$transport = if ([enum]::GetNames([Microsoft.HyperV.PowerShell.EnhancedSessionTransportType]) -contains 'None') { 'None' } else { 'VMBus' }
Set-VM -VMName $vmName -EnhancedSessionTransportType $transport

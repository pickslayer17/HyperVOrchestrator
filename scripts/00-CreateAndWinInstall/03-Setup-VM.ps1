# configure vm: dynamic memory, video, basic enhanced session

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$videoWidth = @@vm.videoWidth@@
$videoHeight = @@vm.videoHeight@@
$memoryGb = @@vm.memoryGb@@

Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 1GB -MaximumBytes $memoryGb
Set-VMVideo -VMName $vmName -HorizontalResolution $videoWidth -VerticalResolution $videoHeight -ResolutionType Single
Set-VM -VMName $vmName -EnhancedSessionTransportType <<ver::5=None,7=VMBus>>

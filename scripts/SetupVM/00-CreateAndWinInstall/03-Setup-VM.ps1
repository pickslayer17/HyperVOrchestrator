# configure vm: dynamic memory, video, basic enhanced session

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$videoWidth = @@vm.videoWidth@@
$videoHeight = @@vm.videoHeight@@
$memoryGb = @@vm.memoryGb@@

Set-VMHost -EnableEnhancedSessionMode $false
Write-Host "Host EnableEnhancedSessionMode: $((Get-VMHost).EnableEnhancedSessionMode)"

Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 1GB -MaximumBytes $memoryGb
Set-VMVideo -VMName $vmName -HorizontalResolution $videoWidth -VerticalResolution $videoHeight -ResolutionType Single
$transportParam = (Get-Command Set-VM).Parameters['EnhancedSessionTransportType'].ParameterType
$transportEnum = if ($transportParam.IsGenericType) { $transportParam.GetGenericArguments()[0] } else { $transportParam }
$transport = if ([enum]::GetNames($transportEnum) -contains 'None') { 'None' } else { 'VMBus' }
Write-Host "EnhancedSessionTransportType: available=[$([enum]::GetNames($transportEnum) -join ', ')], selected=$transport"
Set-VM -VMName $vmName -EnhancedSessionTransportType $transport
Write-Host "VM '$vmName' configured: memory=$($memoryGb/1GB)GB, video=${videoWidth}x${videoHeight}, transport=$transport"
Write-Host ""
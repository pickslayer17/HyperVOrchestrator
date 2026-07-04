# prepare host: verify iso/unattend, wipe old vm + vhdx

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$windowsIso = "@@paths.windowsIso@@"
$unattendXml = "@@paths.unattendXml@@"
$vhdPath = Join-Path "@@paths.vmDir@@" "$vmName.vhdx"

if (-not (Test-Path $windowsIso)) { throw "Windows ISO not found: $windowsIso" }
if (-not (Test-Path $unattendXml)) { throw "autounattend.xml not found: $unattendXml" }

$existingVm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if ($existingVm) {
    Write-Host "Removing existing VM '$vmName'..."
    if ($existingVm.State -ne 'Off') { Stop-VM -Name $vmName -Force }
    Remove-VM -Name $vmName -Force
}
if (Test-Path $vhdPath) {
    Dismount-VHD -Path $vhdPath -ErrorAction SilentlyContinue
    Remove-Item $vhdPath -Force
}

Write-Host "Prepared. VHDX path: $vhdPath"

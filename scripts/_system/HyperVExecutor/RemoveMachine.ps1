param(
	[string]$VmName,
	[string]$VmDir
)
$ErrorActionPreference = "Stop"

$vhdPath = Join-Path $VmDir "$VmName.vhdx"

$existingVm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if ($existingVm) {
	if ($existingVm.State -ne 'Off') { Stop-VM -Name $VmName -Force }
	Remove-VM -Name $VmName -Force
}
if (Test-Path $vhdPath) {
	Dismount-VHD -Path $vhdPath -ErrorAction SilentlyContinue
	Remove-Item $vhdPath -Force
}

Write-Host "Removed VM '$VmName' and VHDX: $vhdPath"

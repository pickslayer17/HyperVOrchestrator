# 02 - Создать ВМ из готового VHDX: Gen2, 4GB RAM, 4 vCPU, TPM.
#
# Перенесено из CreateVM_DISM.ps1 (секция 5).

$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ ===
$vmName = "TestRunner"
$vmPath = "D:\VMs"
$vhdPath = "$vmPath\$vmName.vhdx"

# === СОЗДАТЬ VM ===
Write-Host "Creating VM..."
New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 2 -VHDPath $vhdPath
Set-VMProcessor -VMName $vmName -Count 4
Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
Enable-VMTPM -VMName $vmName
Write-Host "VM created with TPM."

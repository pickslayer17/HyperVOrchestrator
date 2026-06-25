# 02 - Создать ВМ из готового VHDX: Gen2, RAM/CPU из конфига, TPM.
#
# Перенесено из CreateVM_DISM.ps1 (секция 5).
# Значения подменяет оркестратор из конфига перед выполнением.

$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ (из конфига) ===
$vmName = "@@vm.name@@"
$memoryGb = @@vm.memoryGb@@
$cpuCount = @@vm.cpuCount@@
# VHDX = директория ВМ из конфига + имя ВМ + .vhdx
$vhdPath = Join-Path "@@paths.vmDir@@" "$vmName.vhdx"

# === СОЗДАТЬ VM ===
Write-Host "Creating VM..."
New-VM -Name $vmName -MemoryStartupBytes (${memoryGb}GB) -Generation 2 -VHDPath $vhdPath
Set-VMProcessor -VMName $vmName -Count $cpuCount
Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
Enable-VMTPM -VMName $vmName
Write-Host "VM created with TPM."

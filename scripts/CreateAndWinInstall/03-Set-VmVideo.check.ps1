# check для 03-Set-VmVideo: ВМ должна существовать и быть ВЫКЛЮЧЕНА —
# Set-VMVideo не применяется к запущенной машине.
# exit 0 = можно запускать основной скрипт.

$vmName = "TestRunner"

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) {
    Write-Host "VM '$vmName' not found (run 02-Create-Vm first)."
    exit 1
}
if ($vm.State -ne 'Off') {
    Write-Host "VM '$vmName' is $($vm.State) — must be Off to set video."
    exit 1
}

Write-Host "VM exists and is Off."
exit 0

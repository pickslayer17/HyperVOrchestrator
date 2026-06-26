$ScriptTarget = "Host"
# 03 - Зафиксировать видео ВМ: разрешение из конфига, отключить Enhanced Session
#      (всегда Basic Session). Нужно для стабильной работы FlaUI / UI Automation.
#
# Перенесено из before_setup/SETUP_HYPERV.ps1.
# Применяется на ВЫКЛЮЧЕННОЙ ВМ — поэтому идёт до запуска (04-Start-Vm).
# Значения подменяет оркестратор из конфига перед выполнением.

$vmName = "@@vm.name@@"
$videoWidth = @@vm.videoWidth@@
$videoHeight = @@vm.videoHeight@@

Set-VMVideo -VMName $vmName -HorizontalResolution $videoWidth -VerticalResolution $videoHeight -ResolutionType Single
Set-VM -VMName $vmName -EnhancedSessionTransportType None

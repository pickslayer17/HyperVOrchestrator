# 03 - Зафиксировать видео ВМ: разрешение 1920x1080, отключить Enhanced Session
#      (всегда Basic Session). Нужно для стабильной работы FlaUI / UI Automation.
#
# Перенесено из before_setup/SETUP_HYPERV.ps1.
# Применяется на ВЫКЛЮЧЕННОЙ ВМ — поэтому идёт до запуска (04-Start-Vm).

Set-VMVideo -VMName "TestRunner" -HorizontalResolution 1920 -VerticalResolution 1080 -ResolutionType Single
Set-VM -VMName "TestRunner" -EnhancedSessionTransportType None

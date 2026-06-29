# Services to disable + the WU policy that backs the update kill.
# Consumed by 01-Disable-Services .ps1 (set) and .check.ps1 (verify), one source.

# wlms = Windows License Monitoring Service. On an offline EnterpriseEval guest the
# initial activation grace expires (~3 days) and wlms.exe starts shutting the VM down
# hourly. Disabling it stops the shutdowns; Office (ClickToRun/OSPP) is unaffected.
$ServicesToDisable = @('wuauserv', 'WSearch', 'SysMain', 'DiagTrack', 'dmwappushservice', 'wlms')

# DoSvc (Delivery Optimization) is killed via registry Start=4, not Set-Service,
# so it is listed separately for the registry path that owns it.
$ServiceRegStart = @(
    @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\DoSvc'; Name = 'Start'; Value = 4; Type = 'DWord' }
)

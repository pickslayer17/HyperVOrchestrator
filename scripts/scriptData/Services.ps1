# Services to disable + the WU policy that backs the update kill.
# Consumed by 01-Disable-Services .ps1 (set) and .check.ps1 (verify), one source.

$ServicesToDisable = @('wuauserv', 'WSearch', 'SysMain', 'DiagTrack', 'dmwappushservice')

# DoSvc and wlms have service ACLs that deny Set-Service even for admins, so they go
# via registry Start=4. wlms: kills the hourly shutdown on an offline EnterpriseEval guest.
$ServiceRegStart = @(
    @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\DoSvc'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\wlms'; Name = 'Start'; Value = 4; Type = 'DWord' }
)

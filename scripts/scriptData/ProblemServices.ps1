# Update/telemetry services that Windows revives after a reboot even when disabled the
# normal way. WaaSMedicSvc is the key one: it "repairs" (re-enables) the others on boot,
# so it must be disabled too. All have service ACLs that deny Set-Service even for admins,
# so they go via registry Start=4 and must be killed/disabled under SYSTEM.
# Consumed by 015-Disable-Problem-Services .ps1 (set) and .check.ps1 (verify), one source.

$ProblemServices = @('wuauserv', 'DoSvc', 'UsoSvc', 'WaaSMedicSvc', 'BITS')

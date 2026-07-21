# Guest reboot helper (injected by the engine). Host-side: fires a SYSTEM scheduled
# task inside the guest that runs `shutdown /r` (fire and forget), then confirms the
# reboot actually took by waiting for the guest to FULLY go down (Hyper-V heartbeat
# loses contact) — not just a session blip, so the next step never catches the stale
# pre-reboot session. Falls back to a hard Restart-VM if the guest never goes down.

function Invoke-GuestReboot {
    $VmName = "@@state.vm.name@@"
    $VmUser = "@@credentials.user@@"
    $VmPassword = "@@credentials.password@@"
    $DownTimeoutSeconds = 90
    $credential = New-Object System.Management.Automation.PSCredential($VmUser, (ConvertTo-SecureString $VmPassword -AsPlainText -Force))
    $stamp = { (Get-Date -Format 'HH:mm:ss') }

    $vm = Get-VM -Name $VmName
    if ($vm.State -in @('Off', 'Saved')) { Write-Host "Starting VM..."; Start-VM -VM $vm; return }
    if ($vm.State -eq 'Paused') { Write-Host "Resuming VM..."; Resume-VM -VM $vm; return }
    if ($vm.State -ne 'Running') { throw "VM '$VmName' cannot be rebooted from state '$($vm.State)'." }

    Write-Host "[$(& $stamp)] issuing guest reboot via SYSTEM task (fire and forget)..."
    $session = New-PSSession -VMName $VmName -Credential $credential
    Invoke-Command -Session $session -ScriptBlock {
        Set-Content -Path 'C:\Windows\Temp\reboot.cmd' -Value "shutdown /r /t 0 /f`r`n" -Encoding ASCII
        $action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c C:\Windows\Temp\reboot.cmd'
        $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName 'DoReboot' -Action $action -Principal $principal -Force | Out-Null
        Start-ScheduledTask -TaskName 'DoReboot'
    }
    Remove-PSSession $session -ErrorAction SilentlyContinue

    # Wait for the guest to FULLY go down: heartbeat loses contact (or state leaves Running).
    # 'Ok*' heartbeat = Windows still up (incl. the "Restarting" screen); NoContact/empty = gone.
    Write-Host "[$(& $stamp)] waiting for guest to go fully down (heartbeat)..."
    $deadline = (Get-Date).AddSeconds($DownTimeoutSeconds)
    $down = $false
    while ((Get-Date) -lt $deadline) {
        $v = Get-VM -Name $VmName
        $hb = "$($v.Heartbeat)"
        if ($v.State -ne 'Running' -or $hb -notlike 'Ok*') {
            Write-Host "[$(& $stamp)] guest down (state=$($v.State) heartbeat=$hb) — reboot confirmed"
            $down = $true; break
        }
        Start-Sleep -Seconds 1
    }

    if (-not $down) {
        Write-Host "[$(& $stamp)] guest never went down within ${DownTimeoutSeconds}s — forcing Restart-VM"
        Restart-VM -Name $VmName -Force
    }
    Write-Host "[$(& $stamp)] reboot confirmed."
}

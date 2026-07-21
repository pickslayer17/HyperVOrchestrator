# Guest reboot helper (injected by the engine). Host-side: fires a SYSTEM scheduled
# task inside the guest that runs `shutdown /r` (fire and forget), then confirms the
# reboot actually started by watching the guest session drop. Falls back to a hard
# Restart-VM if the graceful reboot does not take within the timeout.

function Invoke-GuestReboot {
    $VmName = "@@state.vm.name@@"
    $VmUser = "@@credentials.user@@"
    $VmPassword = "@@credentials.password@@"
    $ConfirmTimeoutSeconds = 15
    $credential = New-Object System.Management.Automation.PSCredential($VmUser, (ConvertTo-SecureString $VmPassword -AsPlainText -Force))
    $vmUserPattern = [regex]::Escape($VmUser)
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

    Write-Host "[$(& $stamp)] waiting for guest session to drop..."
    $deadline = (Get-Date).AddSeconds($ConfirmTimeoutSeconds)
    $down = $false
    while ((Get-Date) -lt $deadline) {
        $job = Start-Job { param($n, $c) Invoke-Command -VMName $n -Credential $c -ScriptBlock { query session } } -ArgumentList $VmName, $credential
        if (Wait-Job $job -Timeout 3) {
            $out = Receive-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            if ($out -notmatch $vmUserPattern) { Write-Host "[$(& $stamp)] session gone — reboot confirmed"; $down = $true; break }
            Write-Host "[$(& $stamp)] session still alive"
        } else {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            Write-Host "[$(& $stamp)] guest not responding — reboot confirmed"; $down = $true; break
        }
        Start-Sleep -Seconds 1
    }

    if (-not $down) {
        Write-Host "[$(& $stamp)] graceful reboot did not take within ${ConfirmTimeoutSeconds}s — forcing Restart-VM"
        Restart-VM -Name $VmName -Force
    }
    Write-Host "[$(& $stamp)] reboot issued."
}

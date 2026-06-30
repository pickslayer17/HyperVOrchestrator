# Wait until the VM is powered on AND the user session is open (autologon finished).
# Host-side: VM power state comes from Get-VM; the session check runs `query session`
# inside the guest over PSDirect, each attempt capped at 8s so a hung call (VM still
# booting) is killed and retried instead of blocking forever.
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmUser = "@@credentials.user@@"
$cred = New-Object System.Management.Automation.PSCredential(
    $vmUser,
    (ConvertTo-SecureString "@@credentials.password@@" -AsPlainText -Force))

function Now { (Get-Date -Format 'HH:mm:ss') }

# --- 1) wait for VM power on (1 min hard cap) ---
$poweredOn = $false
$deadline = (Get-Date).AddMinutes(1)
while ((Get-Date) -lt $deadline) {
    $state = (Get-VM -VMName $vmName).State
    Write-Host "[$(Now)] VM state: $state"
    if ($state -eq 'Running') { Write-Host "[$(Now)] VM is on"; $poweredOn = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $poweredOn) { Write-Host "[$(Now)] TIMEOUT: VM did not power on within 1 min"; exit 1 }

# --- 2) wait for the user session (10 min cap, query session inside guest, 8s per attempt) ---
$deadline = (Get-Date).AddMinutes(10)
$found = $false
while ((Get-Date) -lt $deadline) {
    $job = Start-Job { param($n, $c) Invoke-Command -VMName $n -Credential $c -ScriptBlock { query session } } -ArgumentList $vmName, $cred
    if (Wait-Job $job -Timeout 8) {
        $out = Receive-Job $job -ErrorAction SilentlyContinue
        if ($out -match $vmUser) {
            Write-Host "[$(Now)] $vmUser session found"
            Remove-Job $job -Force
            $found = $true
            break
        }
        Write-Host "[$(Now)] query ok, $vmUser not yet"
    } else {
        Write-Host "[$(Now)] query hung, killing and retrying"
    }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

if (-not $found) { Write-Host "[$(Now)] TIMEOUT: $vmUser session not open within 10 min"; exit 1 }

# office archive present + vm running/reachable

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName        = "@@vm.name@@"
$vmUser        = "@@credentials.user@@"
$vmPass        = "@@credentials.password@@"
$officeArchive = "@@paths.officeArchive@@"

if (-not (Test-Path $officeArchive)) { Write-Host "Office archive not found: $officeArchive"; exit 1 }

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) { Write-Host "VM '$vmName' not found."; exit 1 }
if ($vm.State -ne 'Running') { Write-Host "VM '$vmName' is $($vm.State) — must be Running."; exit 1 }

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))
try {
    Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock { $true } -ErrorAction Stop | Out-Null
} catch {
    Write-Host "PSDirect to '$vmName' failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Office archive present and VM reachable."
exit 0

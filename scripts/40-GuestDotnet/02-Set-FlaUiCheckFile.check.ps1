# check для 02-Set-FlaUiCheckFile: ВМ запущена, доступна по PSDirect,
# и проект FlaUI уже создан (его делает 01).
# exit 0 = можно запускать основной скрипт.

$vmName      = "@@vm.name@@"
$vmUser      = "@@credentials.user@@"
$vmPass      = "@@credentials.password@@"
$desktop     = "C:\Users\@@credentials.user@@\Desktop"
$projectName = "@@flaui.projectName@@"

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) { Write-Host "VM '$vmName' not found."; exit 1 }
if ($vm.State -ne 'Running') { Write-Host "VM '$vmName' is $($vm.State) — must be Running."; exit 1 }

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))
try {
    $ok = Invoke-Command -VMName $vmName -Credential $cred -ArgumentList $desktop, $projectName -ScriptBlock {
        param($desktop, $projectName)
        Test-Path "$desktop\$projectName\$projectName.csproj"
    } -ErrorAction Stop
} catch {
    Write-Host "PSDirect to '$vmName' failed: $($_.Exception.Message)"
    exit 1
}
if (-not $ok) { Write-Host "FlaUI project not found in VM (run 01-New-FlaUiProject first)."; exit 1 }

Write-Host "VM reachable and FlaUI project present."
exit 0

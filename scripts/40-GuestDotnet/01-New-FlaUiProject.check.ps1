# check для 01-New-FlaUiProject: ВМ запущена, доступна по PSDirect, и в ней есть dotnet.
# exit 0 = можно запускать основной скрипт.

$vmName     = "@@vm.name@@"
$vmUser     = "@@credentials.user@@"
$vmPass     = "@@credentials.password@@"
$installDir = "@@paths.dotnetInstallDir@@"

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) { Write-Host "VM '$vmName' not found."; exit 1 }
if ($vm.State -ne 'Running') { Write-Host "VM '$vmName' is $($vm.State) — must be Running."; exit 1 }

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))
try {
    $ok = Invoke-Command -VMName $vmName -Credential $cred -ArgumentList $installDir -ScriptBlock {
        param($installDir)
        Test-Path "$installDir\dotnet.exe"
    } -ErrorAction Stop
} catch {
    Write-Host "PSDirect to '$vmName' failed: $($_.Exception.Message)"
    exit 1
}
if (-not $ok) { Write-Host "dotnet.exe not found in VM (run 00-Install-DotNet first)."; exit 1 }

Write-Host "VM reachable and dotnet present."
exit 0

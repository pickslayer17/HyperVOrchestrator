$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName        = "@@state.vm.name@@"
$vmUser        = "@@credentials.user@@"
$vmPassword    = "@@credentials.password@@"
$officeArchive = "@@paths.officeArchive@@"
$setupExe      = Join-Path (Split-Path -Parent $officeArchive) "setup.exe"

if (-not (Test-Path $officeArchive)) { throw "Office archive not found: $officeArchive" }
if (-not (Test-Path $setupExe)) { throw "setup.exe not found: $setupExe" }

$credential = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPassword -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $credential

$guestDir = "@@paths.guestOfficeDir@@"
Invoke-Command -Session $session -ArgumentList $guestDir -ScriptBlock { param($d) New-Item -ItemType Directory -Path $d -Force | Out-Null }
Copy-Item -ToSession $session -Path $officeArchive -Destination (Join-Path $guestDir "Office.zip") -Force
Copy-Item -ToSession $session -Path $setupExe -Destination (Join-Path $guestDir "setup.exe") -Force

Remove-PSSession $session
Write-Host "Office archive + setup.exe copied to $guestDir."

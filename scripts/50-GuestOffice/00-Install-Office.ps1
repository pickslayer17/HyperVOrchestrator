# deploy office: copy zip to vm, extract into Program Files

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName        = "@@vm.name@@"
$vmUser        = "@@credentials.user@@"
$vmPass        = "@@credentials.password@@"
$officeArchive = "@@paths.officeArchive@@"

if (-not (Test-Path $officeArchive)) { throw "Office archive not found: $officeArchive" }

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $cred

Write-Host "Copying Office archive to VM..."
Copy-Item -ToSession $session -Path $officeArchive -Destination "C:\office.zip"

Write-Host "Extracting..."
Invoke-Command -Session $session -ScriptBlock {
    Expand-Archive -Path "C:\office.zip" -DestinationPath "C:\Program Files" -Force
    Remove-Item "C:\office.zip" -Force
}

Remove-PSSession $session
Write-Host "Office deployed."

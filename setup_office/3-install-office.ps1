$ErrorActionPreference = "Stop"
. "$PSScriptRoot\params.ps1"

$cred = New-Object System.Management.Automation.PSCredential($VMUser, (ConvertTo-SecureString $VMPassword -AsPlainText -Force))
$session = New-PSSession -VMName $VMName -Credential $cred

Write-Host "Copying Office archive to VM..."
Copy-Item -ToSession $session -Path "$PSScriptRoot\office.zip" -Destination "C:\office.zip"

Write-Host "Extracting..."
Invoke-Command -Session $session -ScriptBlock {
    Expand-Archive -Path "C:\office.zip" -DestinationPath "C:\Program Files" -Force
    Remove-Item "C:\office.zip" -Force
}

Remove-PSSession $session
Write-Host "Office deployed."
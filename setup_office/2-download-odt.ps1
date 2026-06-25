$ErrorActionPreference = "Stop"
. "$PSScriptRoot\params.ps1"

$cred = New-Object System.Management.Automation.PSCredential($VMUser, (ConvertTo-SecureString $VMPassword -AsPlainText -Force))

Invoke-Command -VMName $VMName -Credential $cred -ScriptBlock {
    param($dir)
    Invoke-WebRequest -Uri "https://officecdn.microsoft.com/pr/wsus/setup.exe" -OutFile "$dir\setup.exe"
    Write-Host "ODT downloaded to $dir\setup.exe"
} -ArgumentList $VMOdtDir
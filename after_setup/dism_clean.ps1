$cred = New-Object System.Management.Automation.PSCredential("TestUser", (ConvertTo-SecureString "Test1234!" -AsPlainText -Force))
Invoke-Command -VMName "TestRunner" -Credential $cred -ScriptBlock {
    dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
    dism /online /Disable-Feature /FeatureName:Windows-Defender /Remove
    dism /online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /Remove
    Write-Host "Done."
}
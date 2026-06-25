$cred = New-Object System.Management.Automation.PSCredential("TestUser", (ConvertTo-SecureString "Test1234!" -AsPlainText -Force))
Invoke-Command -VMName "TestRunner" -Credential $cred -ScriptBlock {
    icacls "C:\" /grant "TestUser:(OI)(CI)F" /T /Q
    Write-Host "TestUser has full access to C:\"
}
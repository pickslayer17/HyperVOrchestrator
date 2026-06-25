$cred = New-Object System.Management.Automation.PSCredential("TestUser", (ConvertTo-SecureString "Test1234!" -AsPlainText -Force))

Invoke-Command -VMName "TestRunner" -Credential $cred -ScriptBlock {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    $projectDir = "C:\Users\TestUser\Desktop\FlaUICheck"
    if (Test-Path $projectDir) { Remove-Item $projectDir -Recurse -Force }
    mkdir $projectDir -Force
    cd $projectDir
    
    dotnet new console --framework net10.0
    
    # Сменить таргет на net10.0-windows
    $csproj = "$projectDir\FlaUICheck.csproj"
    (Get-Content $csproj) -replace 'net10.0', 'net10.0-windows' | Set-Content $csproj
    
    dotnet add package FlaUI.UIA3
    dotnet build
    
    Write-Host "FlaUI project ready at $projectDir"
}
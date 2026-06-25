$cred = New-Object System.Management.Automation.PSCredential("TestUser", (ConvertTo-SecureString "Test1234!" -AsPlainText -Force))

Invoke-Command -VMName "TestRunner" -Credential $cred -ScriptBlock {
    # === 1. Скачать dotnet-install скрипт ===
    $installScript = "C:\Users\TestUser\Desktop\dotnet-install.ps1"
    Invoke-WebRequest -Uri "https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.ps1" -OutFile $installScript
    
    # === 2. Установить .NET 10 SDK ===
    powershell -ExecutionPolicy Bypass -File $installScript -Channel 10.0 -Quality GA -InstallDir "C:\Program Files\dotnet"
    
    # === 3. Прописать PATH ===
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($machinePath -notlike "*dotnet*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$machinePath;C:\Program Files\dotnet", "Machine")
    }
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    # === 4. Проверить ===
    & "C:\Program Files\dotnet\dotnet.exe" --version
    
    Write-Host "dotnet SDK installed."
}
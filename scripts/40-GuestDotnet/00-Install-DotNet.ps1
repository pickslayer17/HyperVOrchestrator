# 00 - Установить .NET SDK внутри ВМ через официальный dotnet-install скрипт,
#      прописать в machine PATH.
#
# Перенесено из setup_dotnet/setup_dotnet.ps1.
# VM-side: выполняется ВНУТРИ ВМ через Invoke-Command -VMName -Credential.

$ErrorActionPreference = "Stop"

$vmName     = "@@vm.name@@"
$vmUser     = "@@credentials.user@@"
$vmPass     = "@@credentials.password@@"
$desktop    = "C:\Users\@@credentials.user@@\Desktop"
$installDir = "@@paths.dotnetInstallDir@@"
$channel    = "@@dotnet.channel@@"
$quality    = "@@dotnet.quality@@"
$scriptUrl  = "@@dotnet.installScriptUrl@@"

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))

Invoke-Command -VMName $vmName -Credential $cred -ArgumentList $desktop, $installDir, $channel, $quality, $scriptUrl -ScriptBlock {
    param($desktop, $installDir, $channel, $quality, $scriptUrl)

    # === 1. Скачать dotnet-install скрипт ===
    $installScript = "$desktop\dotnet-install.ps1"
    Invoke-WebRequest -Uri $scriptUrl -OutFile $installScript

    # === 2. Установить .NET SDK ===
    powershell -ExecutionPolicy Bypass -File $installScript -Channel $channel -Quality $quality -InstallDir $installDir

    # === 3. Прописать PATH ===
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($machinePath -notlike "*dotnet*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$machinePath;$installDir", "Machine")
    }
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

    # === 4. Проверить ===
    & "$installDir\dotnet.exe" --version

    Write-Host "dotnet SDK installed."
}

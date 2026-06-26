$ScriptTarget = "VM"
# 00 - Установить .NET SDK внутри ВМ через официальный dotnet-install скрипт,
#      прописать в machine PATH.
#
# Перенесено из setup_dotnet/setup_dotnet.ps1.
# $ScriptTarget = "VM" -> оркестратор заворачивает в Invoke-Command -VMName сам.

$ErrorActionPreference = "Stop"

$desktop    = "C:\Users\@@credentials.user@@\Desktop"
$installDir = "@@paths.dotnetInstallDir@@"
$channel    = "@@dotnet.channel@@"
$quality    = "@@dotnet.quality@@"
$scriptUrl  = "@@dotnet.installScriptUrl@@"

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

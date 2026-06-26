# install .net sdk in guest, add to machine PATH

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$desktop    = "C:\Users\@@credentials.user@@\Desktop"
$installDir = "@@paths.dotnetInstallDir@@"
$channel    = "@@dotnet.channel@@"
$quality    = "@@dotnet.quality@@"
$scriptUrl  = "@@dotnet.installScriptUrl@@"

# download installer
$installScript = "$desktop\dotnet-install.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $installScript

# install sdk
powershell -ExecutionPolicy Bypass -File $installScript -Channel $channel -Quality $quality -InstallDir $installDir

# machine PATH
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($machinePath -notlike "*dotnet*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$machinePath;$installDir", "Machine")
}
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

& "$installDir\dotnet.exe" --version
Write-Host "dotnet SDK installed."

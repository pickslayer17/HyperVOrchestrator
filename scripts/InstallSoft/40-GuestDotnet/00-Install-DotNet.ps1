# install .net sdk in guest, add to machine PATH

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$installDir = "@@paths.dotnetInstallDir@@"
$channel    = "@@dotnet.version@@"
$scriptUrl  = "@@dotnet.installScriptUrl@@"

# download installer
$installScript = "$env:TEMP\dotnet-install.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $installScript

# install sdk
powershell -ExecutionPolicy Bypass -File $installScript -Channel $channel -InstallDir $installDir

# machine PATH
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
if (($machinePath -split ";") -notcontains $installDir) {
    [System.Environment]::SetEnvironmentVariable("PATH", "$machinePath;$installDir", "Machine")
}
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

& "$installDir\dotnet.exe" --version
Write-Host "dotnet SDK installed."




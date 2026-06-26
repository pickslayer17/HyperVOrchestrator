# create flaui console project in guest, build

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$desktop       = "C:\Users\@@credentials.user@@\Desktop"
$projectName   = "@@flaui.projectName@@"
$baseFramework = "@@flaui.baseFramework@@"
$framework     = "@@flaui.targetFramework@@"
$package       = "@@flaui.package@@"

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

$projectDir = "$desktop\$projectName"
if (Test-Path $projectDir) { Remove-Item $projectDir -Recurse -Force }
mkdir $projectDir -Force
cd $projectDir

# create on base framework, retarget to windows
dotnet new console --framework $baseFramework
$csproj = "$projectDir\$projectName.csproj"
(Get-Content $csproj) -replace [regex]::Escape($baseFramework), $framework | Set-Content $csproj

dotnet add package $package
dotnet build

Write-Host "FlaUI project ready at $projectDir"

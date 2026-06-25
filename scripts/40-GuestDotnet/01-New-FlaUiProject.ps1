#:target vm
# 01 - Создать FlaUI проект внутри ВМ: dotnet new console, сменить таргет на
#      windows-framework, добавить пакет FlaUI, собрать.
#
# Перенесено из setup_dotnet/create_flaui_project.ps1.
# #:target vm -> оркестратор заворачивает в Invoke-Command -VMName сам.

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

# Создать проект на базовом таргете, затем сменить на windows-вариант
dotnet new console --framework $baseFramework
$csproj = "$projectDir\$projectName.csproj"
(Get-Content $csproj) -replace [regex]::Escape($baseFramework), $framework | Set-Content $csproj

dotnet add package $package
dotnet build

Write-Host "FlaUI project ready at $projectDir"

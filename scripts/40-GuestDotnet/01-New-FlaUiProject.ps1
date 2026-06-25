# 01 - Создать FlaUI проект внутри ВМ: dotnet new console, сменить таргет на
#      windows-framework, добавить пакет FlaUI, собрать.
#
# Перенесено из setup_dotnet/create_flaui_project.ps1.
# VM-side: выполняется ВНУТРИ ВМ через Invoke-Command -VMName -Credential.

$ErrorActionPreference = "Stop"

$vmName      = "@@vm.name@@"
$vmUser      = "@@credentials.user@@"
$vmPass      = "@@credentials.password@@"
$desktop       = "C:\Users\@@credentials.user@@\Desktop"
$projectName   = "@@flaui.projectName@@"
$baseFramework = "@@flaui.baseFramework@@"
$framework     = "@@flaui.targetFramework@@"
$package       = "@@flaui.package@@"

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))

Invoke-Command -VMName $vmName -Credential $cred -ArgumentList $desktop, $projectName, $baseFramework, $framework, $package -ScriptBlock {
    param($desktop, $projectName, $baseFramework, $framework, $package)

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
}

# Использование:
#   .\1-prepare-config.ps1 -Include Excel,Word
#   .\1-prepare-config.ps1 -Include Excel,Word,PowerPoint,Outlook

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Access","Excel","Groove","Lync","OneDrive","OneNote","Outlook","PowerPoint","Publisher","Teams","Bing","Word")]
    [string[]]$Include
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Params.ps1"

$cred = New-Object System.Management.Automation.PSCredential($VMUser, (ConvertTo-SecureString $VMPassword -AsPlainText -Force))

# === 1. Создать папку на VM ===
Invoke-Command -VMName $VMName -Credential $cred -ScriptBlock {
    param($dir)
    mkdir $dir -Force
} -ArgumentList $VMOdtDir

# === 2. Прочитать шаблон, убрать ExcludeApp для выбранных ===
$xml = Get-Content "$PSScriptRoot\config.xml" -Raw
foreach ($app in $Include) {
    $xml = $xml -replace ".*<ExcludeApp ID=`"$app`"\s*/>\s*\r?\n", ""
}

# === 3. Записать временный файл и закинуть на VM ===
$tempConfig = "$PSScriptRoot\config_final.xml"
Set-Content -Path $tempConfig -Value $xml

Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface" -ErrorAction SilentlyContinue
Copy-VMFile -VMName $VMName -SourcePath $tempConfig -DestinationPath "$VMOdtDir\config.xml" -FileSource Host -Force
Remove-Item $tempConfig -Force

Write-Host "Config ready. Apps to install: $($Include -join ', ')"
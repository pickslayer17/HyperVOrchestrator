$ScriptTarget = "Host"
# 00 - Установить Office распаковкой готового архива (office.zip) в C:\Program Files
#      внутри ВМ. Это НЕ ODT — это закэшированный готовый Office (быстро, без скачивания 4 ГБ).
#
# Перенесено из setup_office/3-install-office.ps1.
# VM-side: копируем архив с хоста в ВМ через PSSession, распаковываем внутри.
#
# !!! ВНИМАНИЕ (проверить):
# Оригинал брал office.zip из $PSScriptRoot. Здесь — из конфига paths.officeArchive
# (хостовый путь). Целевая папка распаковки C:\Program Files — гостевой системный путь,
# оставлена как есть. Убедись, что paths.officeArchive в local.config.json задан.

$ErrorActionPreference = "Stop"

$vmName       = "@@vm.name@@"
$vmUser       = "@@credentials.user@@"
$vmPass       = "@@credentials.password@@"
$officeArchive = "@@paths.officeArchive@@"

if (-not (Test-Path $officeArchive)) { throw "Office archive not found: $officeArchive" }

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $cred

Write-Host "Copying Office archive to VM..."
Copy-Item -ToSession $session -Path $officeArchive -Destination "C:\office.zip"

Write-Host "Extracting..."
Invoke-Command -Session $session -ScriptBlock {
    Expand-Archive -Path "C:\office.zip" -DestinationPath "C:\Program Files" -Force
    Remove-Item "C:\office.zip" -Force
}

Remove-PSSession $session
Write-Host "Office deployed."

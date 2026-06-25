$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Params.ps1"

# === 1. Прочитать шаблон ===
$xml = Get-Content "$PSScriptRoot\config.xml" -Raw

# === 2. Вставить прокси ===
$xmlDoc = [xml]$xml
$appSettings = $xmlDoc.CreateElement("AppSettings")
$setup = $xmlDoc.CreateElement("Setup")
$setup.SetAttribute("Name", "ProxyAddress")
$setup.SetAttribute("Value", $VMProxy)
$appSettings.AppendChild($setup)
$xmlDoc.Configuration.AppendChild($appSettings)
$xml = $xmlDoc.OuterXml
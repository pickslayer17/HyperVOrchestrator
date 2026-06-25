#:target vm
# check для 01-New-FlaUiProject: в ВМ должен быть установлен dotnet (его ставит 00).
# throw -> оркестратор пометит check провалившимся и не запустит основной шаг.
$installDir = "@@paths.dotnetInstallDir@@"
if (-not (Test-Path "$installDir\dotnet.exe")) { throw "dotnet.exe not found in VM (run 00-Install-DotNet first)." }
Write-Host "dotnet present in VM."

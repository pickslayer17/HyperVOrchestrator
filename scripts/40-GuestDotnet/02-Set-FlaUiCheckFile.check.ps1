$ScriptTarget = "VM"
# check для 02-Set-FlaUiCheckFile: в ВМ должен быть создан FlaUI-проект (его делает 01).
# throw -> оркестратор пометит check провалившимся и не запустит основной шаг.
$desktop     = "C:\Users\@@credentials.user@@\Desktop"
$projectName = "@@flaui.projectName@@"
if (-not (Test-Path "$desktop\$projectName\$projectName.csproj")) { throw "FlaUI project not found in VM (run 01-New-FlaUiProject first)." }
Write-Host "FlaUI project present in VM."

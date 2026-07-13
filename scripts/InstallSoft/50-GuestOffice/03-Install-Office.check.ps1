$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$wanted = @("@@office.apps@@".Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$exeByApp = @{
    Word       = 'WINWORD.EXE'
    Excel      = 'EXCEL.EXE'
    PowerPoint = 'POWERPNT.EXE'
    Outlook    = 'OUTLOOK.EXE'
    Access     = 'MSACCESS.EXE'
    Publisher  = 'MSPUB.EXE'
    OneNote    = 'ONENOTE.EXE'
}
$root = 'C:\Program Files\Microsoft Office\root\Office16'

$missing = @()
foreach ($app in $wanted) {
    $exe = $exeByApp[$app]
    if (-not $exe -or -not (Test-Path (Join-Path $root $exe))) { $missing += $app }
}

if ($missing.Count -eq 0) {
    Write-Host "Office apps installed: $($wanted -join ', ')"
    exit 2
}
Write-Host "missing: $($missing -join ', ')"
exit 0

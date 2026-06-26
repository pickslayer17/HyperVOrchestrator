# dism cleanup + remove defender / ie

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /online /Disable-Feature /FeatureName:Windows-Defender /Remove
dism /online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /Remove
Write-Host "Done."

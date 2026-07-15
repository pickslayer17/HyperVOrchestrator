# host: is the Hyper-V role present/usable -> "true" | "false"
$ErrorActionPreference = "Stop"

$hyperVPresent = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)
if ($hyperVPresent) { "true" } else { "false" }

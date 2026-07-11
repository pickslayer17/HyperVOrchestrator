# host: is the Hyper-V role present/usable -> "true" | "false"
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$hyperVPresent = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)
if ($hyperVPresent) { "true" } else { "false" }

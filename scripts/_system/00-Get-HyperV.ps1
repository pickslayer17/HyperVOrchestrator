# host: is the Hyper-V role present/usable -> "true" | "false"
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$present = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)

if ($present) { "true" } else { "false" }

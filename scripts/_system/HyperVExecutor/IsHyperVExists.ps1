# host: is the Hyper-V role present/usable -> "true" | "false"
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$hyperVPresent = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)
if ($hyperVPresent) { "true" } else { "false" }

param(
    [string]$Ip
)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$pingAlive = Test-Connection -ComputerName $Ip -Count 1 -Quiet -ErrorAction SilentlyContinue
$neighbor = Get-NetNeighbor -IPAddress $Ip -ErrorAction SilentlyContinue |
            Where-Object { $_.State -in 'Reachable', 'Stale', 'Permanent' }

if ($pingAlive -or $neighbor) { "false" } else { "true" }

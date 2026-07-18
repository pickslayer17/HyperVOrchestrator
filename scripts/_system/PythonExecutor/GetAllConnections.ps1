# host: python agent connections -> json { proxy: [..], dns: [{listen, target}], active }
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"

$proxy = @()
$dns = @()
$active = 0

$output = & python "$serverScript" get_connections 2>$null
if ($LASTEXITCODE -eq 0) {
    foreach ($line in $output) {
        $line = "$line".Trim()
        if ($line -like "proxy:*") {
            $proxy += $line.Substring(6).Trim()
        }
        elseif ($line -like "dns:*") {
            $rest = $line.Substring(4).Trim()
            $arrow = $rest.IndexOf('->')
            if ($arrow -ge 0) {
                $listen = $rest.Substring(0, $arrow).Trim()
                $target = $rest.Substring($arrow + 2).Trim()
                $dns += [pscustomobject]@{ listen = $listen; target = $target }
            }
        }
        elseif ($line -like "active:*") {
            [int]::TryParse($line.Substring(7).Trim(), [ref]$active) | Out-Null
        }
    }
}

[pscustomobject]@{ proxy = @($proxy); dns = @($dns); active = $active } | ConvertTo-Json -Depth 4

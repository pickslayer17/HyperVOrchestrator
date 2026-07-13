$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$alive = & python "$serverScript" is_alive 2>$null
if ($LASTEXITCODE -ne 0) { "false"; return }
"$alive".Trim()

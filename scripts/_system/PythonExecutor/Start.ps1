$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
& python "$serverScript" start

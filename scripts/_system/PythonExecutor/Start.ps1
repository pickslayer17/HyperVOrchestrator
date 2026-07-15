$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
& python "$serverScript" start

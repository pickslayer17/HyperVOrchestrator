$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if ($dotnet) {
    Write-Host "dotnet found: $(& dotnet --version)"
    exit 2
}
Write-Host "dotnet not found."
exit 0

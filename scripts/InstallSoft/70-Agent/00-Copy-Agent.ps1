$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$vmUser     = "@@credentials.user@@"
$vmPassword = "@@credentials.password@@"
$agentDir   = "@@agent.dir@@"
$agentZip   = "@@paths.agentZip@@"

if (-not (Test-Path $agentZip)) { throw "agent zip not found: $agentZip" }

$credential = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPassword -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $credential

Invoke-Command -Session $session -ArgumentList $agentDir -ScriptBlock {
    param($dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
$vmZip = Invoke-Command -Session $session -ArgumentList $agentDir -ScriptBlock { param($dir) Join-Path $dir "agent.zip" }
Copy-Item -ToSession $session -Path $agentZip -Destination $vmZip -Force

Invoke-Command -Session $session -ArgumentList $agentDir -ScriptBlock {
    param($dir)
    $zip = Join-Path $dir "agent.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dir)
    Remove-Item $zip -Force
}

Remove-PSSession $session
Write-Host "agent copied to VM and extracted to $agentDir."

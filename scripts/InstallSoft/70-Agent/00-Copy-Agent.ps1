$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$vmUser     = "@@credentials.user@@"
$vmPassword = "@@credentials.password@@"
$version    = "@@agent.version@@"
$agentDir   = "@@agent.dir@@"
$artifacts  = "@@paths.agentArtifacts@@"

$url = "https://download.agent.dev.azure.com/agent/$version/vsts-agent-win-x64-$version.zip"
$zip = Join-Path $artifacts "agent.zip"

New-Item -ItemType Directory -Path $artifacts -Force | Out-Null
if (-not (Test-Path $zip)) {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
}

$credential = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPassword -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $credential

Invoke-Command -Session $session -ArgumentList $agentDir -ScriptBlock {
    param($dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
$vmZip = Invoke-Command -Session $session -ArgumentList $agentDir -ScriptBlock { param($dir) Join-Path $dir "agent.zip" }
Copy-Item -ToSession $session -Path $zip -Destination $vmZip -Force

Invoke-Command -Session $session -ArgumentList $agentDir -ScriptBlock {
    param($dir)
    $zip = Join-Path $dir "agent.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dir)
    Remove-Item $zip -Force
}

Remove-PSSession $session
Write-Host "agent binaries downloaded to $artifacts and extracted to $agentDir on VM."

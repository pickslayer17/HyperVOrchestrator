$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$vmUser     = "@@credentials.user@@"
$vmPassword = "@@credentials.password@@"
$setupSource = Join-Path "@@paths.singboxArtifacts@@" "..\winsdk\winsdksetup.exe"
$setupSource = [System.IO.Path]::GetFullPath($setupSource)

if (-not (Test-Path $setupSource)) { throw "winsdksetup.exe not found: $setupSource" }

$credential = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPassword -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $credential

Invoke-Command -Session $session -ScriptBlock { New-Item -ItemType Directory -Path 'C:\winsdk' -Force | Out-Null }
Copy-Item -ToSession $session -Path $setupSource -Destination 'C:\winsdk\winsdksetup.exe' -Force

Invoke-Command -Session $session -ScriptBlock {
    $proc = Start-Process -FilePath 'C:\winsdk\winsdksetup.exe' -ArgumentList '/features','OptionId.NetFxSoftwareDevelopmentKit','/quiet','/norestart' -Wait -PassThru
    if ($proc.ExitCode -ne 0) { throw "winsdksetup failed (exit $($proc.ExitCode))" }

    $binDir = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin"
    $target = Join-Path $binDir "NETFX 4.8 Tools"
    if (-not (Test-Path (Join-Path $target "mage.exe"))) {
        $installed = Get-ChildItem $binDir -Directory -Filter "NETFX*Tools" -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName "mage.exe") } | Select-Object -First 1
        if (-not $installed) { throw "no NETFX Tools folder with mage.exe found under $binDir" }
        Copy-Item -Path $installed.FullName -Destination $target -Recurse -Force
    }

    $mage = Join-Path $target "mage.exe"
    if (-not (Test-Path $mage)) { throw "mage.exe not found after install: $mage" }
    Write-Host "Windows SDK NETFX tools installed; mage.exe present at '4.8 Tools'."
}

Remove-PSSession $session
Write-Host "Windows SDK setup copied and installed on VM."

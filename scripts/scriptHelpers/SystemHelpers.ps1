# Service / power / appx / feature helpers shared by set- and check-scripts
# (injected by the engine before interpolation).

# --- Processes ---

# Kill a process by image name. A missing process is fine (write a note and move on);
# any other taskkill failure is a real error and rethrown.
function Stop-ProcessHard {
    param([Parameter(Mandatory)][string]$ImageName)
    $taskkillOutput = taskkill /f /im $ImageName 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "killed $ImageName"; return }
    if ($taskkillOutput -match 'not found') { Write-Host "$ImageName not running, skipped"; return }
    throw "taskkill $ImageName failed: $taskkillOutput"
}

# --- Services ---

function Disable-ServiceHard {
    param([Parameter(Mandatory)][string]$Name)
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $service) { return }
    Set-Service -Name $Name -StartupType Disabled
    if ($service.Status -ne 'Stopped') { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
}

# True if the service is absent (nothing to do) OR set to Disabled start mode.
function Test-ServiceDisabled {
    param([Parameter(Mandatory)][string]$Name)
    $service = Get-CimInstance Win32_Service -Filter "Name='$Name'" -ErrorAction SilentlyContinue
    if (-not $service) { return $true }
    return ($service.StartMode -eq 'Disabled')
}

# --- Sleep / power ---

# True if every idle timeout on the active scheme (AC) is 0 (never).
function Test-NoSleepTimeouts {
    $idleTimeoutSettings = @('STANDBYIDLE', 'HIBERNATEIDLE', 'VIDEOIDLE', 'DISKIDLE')
    foreach ($idleSetting in $idleTimeoutSettings) {
        $subgroup = switch ($idleSetting) {
            'STANDBYIDLE'   { 'SUB_SLEEP' }
            'HIBERNATEIDLE' { 'SUB_SLEEP' }
            'VIDEOIDLE'     { 'SUB_VIDEO' }
            'DISKIDLE'      { 'SUB_DISK' }
        }
        $powercfgOutput = powercfg /query SCHEME_CURRENT $subgroup $idleSetting 2>$null
        $acPowerSetting = ($powercfgOutput | Select-String 'Current AC Power Setting Index')
        if (-not $acPowerSetting) { continue }
        if ($acPowerSetting.ToString() -notmatch '0x0+\s*$') { return $false }
    }
    return $true
}

# --- Page file ---

# True if a fixed page file is configured (InitialSize == MaximumSize, non-zero).
function Test-PageFileFixed {
    $pageFileSetting = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
    if (-not $pageFileSetting) { return $false }
    foreach ($pageFile in @($pageFileSetting)) {
        if ($pageFile.InitialSize -eq 0 -or $pageFile.InitialSize -ne $pageFile.MaximumSize) { return $false }
    }
    return $true
}

# --- Reserved storage ---

function Test-ReservedStorageDisabled {
    $dismOutput = (dism /online /Get-ReservedStorageState 2>$null) -join "`n"
    return ($dismOutput -match 'Disabled')
}

# --- Appx ---

# Remove a package for all users and drop it from provisioning.
function Remove-AppxByWildcard {
    param([Parameter(Mandatory)][string]$Match)
    Get-AppxPackage -Name "*$Match*" -AllUsers -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -Like "*$Match*" |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# True if no installed package matches (provisioning may linger; installed is the
# signal that matters for runtime behaviour).
function Test-AppxAbsent {
    param([Parameter(Mandatory)][string]$Match)
    return -not (Get-AppxPackage -Name "*$Match*" -AllUsers -ErrorAction SilentlyContinue)
}

# --- Optional features ---

function Test-FeatureRemoved {
    param([Parameter(Mandatory)][string]$Name)
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction SilentlyContinue
    if (-not $feature) { return $true }            # feature not present at all
    return ($feature.State -eq 'Disabled')
}

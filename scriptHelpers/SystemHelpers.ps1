# Service / power / appx / feature helpers shared by set- and check-scripts
# (injected by the engine before interpolation).

# --- Processes ---

# Kill a process by image name. A missing process is fine (write a note and move on);
# any other taskkill failure is a real error and rethrown.
function Stop-ProcessHard {
    param([Parameter(Mandatory)][string]$ImageName)
    $out = taskkill /f /im $ImageName 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "killed $ImageName"; return }
    if ($out -match 'not found') { Write-Host "$ImageName not running, skipped"; return }
    throw "taskkill $ImageName failed: $out"
}

# --- Services ---

function Disable-ServiceHard {
    param([Parameter(Mandatory)][string]$Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { return }
    Set-Service -Name $Name -StartupType Disabled
    if ($svc.Status -ne 'Stopped') { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
}

# True if the service is absent (nothing to do) OR set to Disabled start mode.
function Test-ServiceDisabled {
    param([Parameter(Mandatory)][string]$Name)
    $svc = Get-CimInstance Win32_Service -Filter "Name='$Name'" -ErrorAction SilentlyContinue
    if (-not $svc) { return $true }
    return ($svc.StartMode -eq 'Disabled')
}

# --- Sleep / power ---

# True if every idle timeout on the active scheme (AC) is 0 (never).
function Test-NoSleepTimeouts {
    $subs = @('STANDBYIDLE', 'HIBERNATEIDLE', 'VIDEOIDLE', 'DISKIDLE')
    foreach ($s in $subs) {
        $sub = switch ($s) {
            'STANDBYIDLE'   { 'SUB_SLEEP' }
            'HIBERNATEIDLE' { 'SUB_SLEEP' }
            'VIDEOIDLE'     { 'SUB_VIDEO' }
            'DISKIDLE'      { 'SUB_DISK' }
        }
        $out = powercfg /query SCHEME_CURRENT $sub $s 2>$null
        $ac = ($out | Select-String 'Current AC Power Setting Index')
        if (-not $ac) { continue }
        if ($ac.ToString() -notmatch '0x0+\s*$') { return $false }
    }
    return $true
}

# --- Page file ---

# True if a fixed page file is configured (InitialSize == MaximumSize, non-zero).
function Test-PageFileFixed {
    $pf = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
    if (-not $pf) { return $false }
    foreach ($p in @($pf)) {
        if ($p.InitialSize -eq 0 -or $p.InitialSize -ne $p.MaximumSize) { return $false }
    }
    return $true
}

# --- Reserved storage ---

function Test-ReservedStorageDisabled {
    $out = (dism /online /Get-ReservedStorageState 2>$null) -join "`n"
    return ($out -match 'Disabled')
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
    $f = Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction SilentlyContinue
    if (-not $f) { return $true }            # feature not present at all
    return ($f.State -eq 'Disabled')
}

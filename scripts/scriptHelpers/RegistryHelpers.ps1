# Registry set/verify helpers shared by set- and check-scripts (injected by the
# engine). Paths are reg.exe-style (HKLM\.., HKCU\..); these helpers translate
# them to the PowerShell provider form.

function ConvertTo-PsRegPath {
    param([Parameter(Mandatory)][string]$RegExePath)
    $psRegPath = $RegExePath -replace '^HKLM\\', 'HKLM:\' `
                     -replace '^HKCU\\', 'HKCU:\' `
                     -replace '^HKCR\\', 'HKCR:\' `
                     -replace '^HKU\\',  'HKU:\'
    return $psRegPath
}

# Write one value, creating the key if needed. $Type is reg.exe-style (DWord etc).
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [string]$Type = 'DWord'
    )
    $psRegPath = ConvertTo-PsRegPath $Path
    if (-not (Test-Path $psRegPath)) { New-Item -Path $psRegPath -Force | Out-Null }
    New-ItemProperty -Path $psRegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# True if the value exists and equals the expected value.
function Test-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value
    )
    $psRegPath = ConvertTo-PsRegPath $Path
    $currentValue = (Get-ItemProperty -Path $psRegPath -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($null -eq $currentValue) { return $false }
    return ([int]$currentValue -eq [int]$Value)
}

# Apply a whole list of @{Path;Name;Value;Type} entries.
# Apply only the entries not already at the target value; logs each one it touches.
function Set-MissingRegTweaks {
    param([Parameter(Mandatory)][array]$Tweaks)
    foreach ($tweak in $Tweaks) {
        if (Test-RegValue -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value) { continue }
        Write-Host "'$($tweak.Path)\$($tweak.Name)': missing (setting to $($tweak.Value))"
        Set-RegValue -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -Type $tweak.Type
    }
}

# Return the first entry that is NOT yet applied, or $null if all match.
function Get-MissingRegTweak {
    param([Parameter(Mandatory)][array]$Tweaks)
    foreach ($tweak in $Tweaks) {
        if (-not (Test-RegValue -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value)) { return $tweak }
    }
    return $null
}

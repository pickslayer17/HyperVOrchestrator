# Registry set/verify helpers shared by set- and check-scripts (injected by the
# engine). Paths are reg.exe-style (HKLM\.., HKCU\..); these helpers translate
# them to the PowerShell provider form.

function ConvertTo-PsRegPath {
    param([Parameter(Mandatory)][string]$RegExePath)
    $p = $RegExePath -replace '^HKLM\\', 'HKLM:\' `
                     -replace '^HKCU\\', 'HKCU:\' `
                     -replace '^HKCR\\', 'HKCR:\' `
                     -replace '^HKU\\',  'HKU:\'
    return $p
}

# Write one value, creating the key if needed. $Type is reg.exe-style (DWord etc).
function Set-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [string]$Type = 'DWord'
    )
    $ps = ConvertTo-PsRegPath $Path
    if (-not (Test-Path $ps)) { New-Item -Path $ps -Force | Out-Null }
    New-ItemProperty -Path $ps -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# True if the value exists and equals the expected value.
function Test-RegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value
    )
    $ps = ConvertTo-PsRegPath $Path
    $cur = (Get-ItemProperty -Path $ps -Name $Name -ErrorAction SilentlyContinue).$Name
    if ($null -eq $cur) { return $false }
    return ([int]$cur -eq [int]$Value)
}

# Apply a whole list of @{Path;Name;Value;Type} entries.
function Set-RegTweaks {
    param([Parameter(Mandatory)][array]$Tweaks)
    foreach ($t in $Tweaks) { Set-RegValue -Path $t.Path -Name $t.Name -Value $t.Value -Type $t.Type }
}

# Return the first entry that is NOT yet applied, or $null if all match.
function Get-MissingRegTweak {
    param([Parameter(Mandatory)][array]$Tweaks)
    foreach ($t in $Tweaks) {
        if (-not (Test-RegValue -Path $t.Path -Name $t.Name -Value $t.Value)) { return $t }
    }
    return $null
}

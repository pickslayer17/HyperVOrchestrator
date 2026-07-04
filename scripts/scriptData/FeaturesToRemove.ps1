# Optional Windows features removed via DISM. Consumed by 03-Remove-Features .ps1
# (remove) and .check.ps1 (verify absent). 'Hard' ones must succeed (the check treats
# their presence as not-done); IE is tolerant of being already absent.
$FeaturesToRemove = @(
    @{ Name = 'Windows-Defender'; Hard = $true }
    @{ Name = 'Internet-Explorer-Optional-amd64'; Hard = $false }
)

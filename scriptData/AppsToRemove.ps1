# UWP packages to strip (matched as wildcards). Consumed by 02-Remove-Bloat
# .ps1 (remove) and .check.ps1 (verify absent). Paint/Photos intentionally kept.

$AppsToRemove = @(
    'Clipchamp.Clipchamp'
    'Microsoft.BingWeather'
    'Microsoft.BingNews'
    'microsoft.windowscommunicationsapps'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.Todos'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.People'
    'Microsoft.WindowsMaps'
    'Microsoft.YourPhone'
    'MicrosoftCorporationII.MicrosoftFamily'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.MixedReality.Portal'
    'Microsoft.3DBuilder'
    'Microsoft.Microsoft3DViewer'
    'Microsoft.Print3D'
    'Microsoft.ZuneMusic'
    'Microsoft.ZuneVideo'
    'Microsoft.GamingApp'
    'Microsoft.XboxApp'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxSpeechToTextOverlay'
    'Microsoft.XboxIdentityProvider'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxGamingOverlay'
    'MicrosoftCorporationII.QuickAssist'
    'Microsoft.OutlookForWindows'
    'Microsoft.WindowsSoundRecorder'
    'MicrosoftTeams'
    'MSTeams'
    'Microsoft.WindowsStore'
    'Microsoft.StorePurchaseApp'
    'Microsoft.Windows.Widgets'
    'MicrosoftWindows.Client.WebExperience'
)

# Optional features removed via DISM. 'Hard' ones must succeed (the check treats
# their presence as not-done); IE is tolerant of being already absent.
$FeaturesToRemove = @(
    @{ Name = 'Windows-Defender'; Hard = $true }
    @{ Name = 'Internet-Explorer-Optional-amd64'; Hard = $false }
)

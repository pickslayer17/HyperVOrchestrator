Add-Type -Path "C:\Interop.UIA\lib\net45\Interop.UIAutomationClient.dll"
Add-Type -Path "C:\FlaUI.Core\lib\net48\FlaUI.Core.dll"
Add-Type -Path "C:\FlaUI\lib\net48\FlaUI.UIA3.dll"

$automation = New-Object FlaUI.UIA3.UIA3Automation
$cf = $automation.ConditionFactory

for ($i = 1; $i -le 200; $i++) {
    $ts = Get-Date -Format "HH:mm:ss"
    try {
        $automation = New-Object FlaUI.UIA3.UIA3Automation
        if (-not $automation) { throw "automation not created" }
        $desktop = $automation.GetDesktop()
        $propId = [FlaUI.Core.Identifiers.PropertyId]::Find([FlaUI.Core.AutomationType]::UIA3, 30005)
        $condition = New-Object FlaUI.Core.Conditions.PropertyCondition($propId, "New tab", [FlaUI.Core.Definitions.PropertyConditionFlags]::MatchSubstring)
        $edge = $desktop.FindFirstDescendant($condition)
        if (-not $edge) { throw "Edge window not found" }
        $maximize = $edge.FindFirstDescendant($cf.ByControlType([FlaUI.Core.Definitions.ControlType]::Button).And($cf.ByName("Maximize")))
        if (-not $maximize) {
            $restore = $edge.FindFirstDescendant($cf.ByControlType([FlaUI.Core.Definitions.ControlType]::Button).And($cf.ByName("Restore")))
            $restore.Click()
        } else {
            $maximize.Click()
        }
        $status = "OK - clicked"
    } catch {
        $status = "FAIL - $($_.Exception.Message)"
    }
    $line = "[$ts] $status"
    Write-Host $line
    Start-Sleep -Seconds 3
}
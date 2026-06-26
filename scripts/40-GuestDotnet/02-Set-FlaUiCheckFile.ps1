# drop flaui Program.cs (edge maximize smoke loop) + build

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$desktop     = "C:\Users\@@credentials.user@@\Desktop"
$projectName = "@@flaui.projectName@@"

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

$projectDir = "$desktop\$projectName"
$logPath = "$desktop\flaui_log.txt"

# literal here-string: PowerShell does not touch the C# $"..." inside
$program = @'
using System;
using System.Threading;
using FlaUI.Core;
using FlaUI.Core.AutomationElements;
using FlaUI.Core.Conditions;
using FlaUI.Core.Definitions;
using FlaUI.Core.Identifiers;
using FlaUI.UIA3;
var logPath = @"__LOGPATH__";
using var automation = new UIA3Automation();
var cf = automation.ConditionFactory;
for (int i = 0; i < 2000; i++)
{
    var ts = DateTime.Now.ToString("HH:mm:ss");
    try
    {
        var desktop = automation.GetDesktop();
        var propId = PropertyId.Find(AutomationType.UIA3, 30005);
        var condition = new PropertyCondition(propId, "New tab", PropertyConditionFlags.MatchSubstring);
        var edge = desktop.FindFirstDescendant(condition);
        if (edge == null) throw new Exception("Edge not found");
        var maximize = edge.FindFirstDescendant(
            cf.ByControlType(ControlType.Button).And(cf.ByName("Maximize")));
        if (maximize != null)
        {
            maximize.Click();
        }
        else
        {
            var restore = edge.FindFirstDescendant(
                cf.ByControlType(ControlType.Button).And(cf.ByName("Restore")));
            if (restore == null) throw new Exception("No Maximize or Restore button");
            restore.Click();
        }
        var line = $"[{ts}] OK - clicked";
        Console.WriteLine(line);
        File.AppendAllText(logPath, line + Environment.NewLine);
    }
    catch (Exception ex)
    {
        var line = $"[{ts}] FAIL - {ex.Message}";
        Console.WriteLine(line);
        File.AppendAllText(logPath, line + Environment.NewLine);
    }
    Thread.Sleep(3000);
}
'@

$program = $program.Replace("__LOGPATH__", $logPath)
Set-Content -Path "$projectDir\Program.cs" -Value $program

cd $projectDir
dotnet build

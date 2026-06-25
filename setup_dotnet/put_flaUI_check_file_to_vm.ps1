$cred = New-Object System.Management.Automation.PSCredential("TestUser", (ConvertTo-SecureString "Test1234!" -AsPlainText -Force))

Invoke-Command -VMName "TestRunner" -Credential $cred -ScriptBlock {
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    
    Set-Content -Path "C:\Users\TestUser\Desktop\FlaUICheck\Program.cs" -Value @'
using System;
using System.Threading;
using FlaUI.Core;
using FlaUI.Core.AutomationElements;
using FlaUI.Core.Conditions;
using FlaUI.Core.Definitions;
using FlaUI.Core.Identifiers;
using FlaUI.UIA3;
var logPath = @"C:\Users\TestUser\Desktop\flaui_log.txt";
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
    
    cd "C:\Users\TestUser\Desktop\FlaUICheck"
    dotnet build
}
$ScriptTarget = "VM"
# 02 - Положить FlaUI check-файл (Program.cs) в проект и собрать.
#      Program.cs гоняет цикл: ищет окно Edge и максимизирует/восстанавливает,
#      пишет лог. Это smoke-проверка UI Automation внутри ВМ.
#
# Перенесено из setup_dotnet/put_flaUI_check_file_to_vm.ps1.
# $ScriptTarget = "VM" -> оркестратор заворачивает в Invoke-Command -VMName сам.
#
# !!! ВНИМАНИЕ: C#-код Program.cs содержит свой $"...{}" (это C#-интерполяция,
# НЕ PowerShell). here-string ЛИТЕРАЛЬНЫЙ (@'...'@), поэтому C#-код не трогается.
# Путь лога подставляется заменой токена __LOGPATH__ уже внутри гостя.

$ErrorActionPreference = "Stop"

$desktop     = "C:\Users\@@credentials.user@@\Desktop"
$projectName = "@@flaui.projectName@@"

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

$projectDir = "$desktop\$projectName"
$logPath = "$desktop\flaui_log.txt"

# C#-код Program.cs. Литеральный here-string: PowerShell не трогает $"..." внутри.
# __LOGPATH__ — наш токен, заменяется на реальный путь лога ниже.
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

# Подставить реальный путь лога.
$program = $program.Replace("__LOGPATH__", $logPath)

Set-Content -Path "$projectDir\Program.cs" -Value $program

cd $projectDir
dotnet build

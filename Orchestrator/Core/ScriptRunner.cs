using System.Diagnostics;
using System.Text;
using Orchestrator.Helpers;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class ScriptRunner
{
    private readonly object _gate = new object();
    private Process? _current;

    public Result Run(string scriptText, Action<string> onLine)
    {
        var tempPath = FileHelper.WriteTempScript(scriptText);
        var output = new StringBuilder();

        var processStartInfo = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        processStartInfo.ArgumentList.Add("-NoProfile");
        processStartInfo.ArgumentList.Add("-ExecutionPolicy");
        processStartInfo.ArgumentList.Add("Bypass");
        processStartInfo.ArgumentList.Add("-File");
        processStartInfo.ArgumentList.Add(tempPath);

        var windowsDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
        var systemModules = Path.Combine(windowsDir, @"system32\WindowsPowerShell\v1.0\Modules");
        var programFilesModules = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"WindowsPowerShell\Modules");
        processStartInfo.Environment["PSModulePath"] = $"{programFilesModules};{systemModules}";

        var process = new Process { StartInfo = processStartInfo };

        process.OutputDataReceived += (sender, eventArgs) =>
        {
            if (eventArgs.Data is null)
                return;
            lock (_gate)
            {
                output.AppendLine(eventArgs.Data);
                onLine(eventArgs.Data);
            }
        };
        process.ErrorDataReceived += (sender, eventArgs) =>
        {
            if (eventArgs.Data is null)
                return;
            lock (_gate)
            {
                output.AppendLine(eventArgs.Data);
                onLine(eventArgs.Data);
            }
        };

        var exitCode = RunProcess(process, tempPath);

        var result = new Result
        {
            ExitCode = exitCode,
            Output = output.ToString(),
        };
        return result;
    }

    public void Cancel()
    {
        lock (_gate)
        {
            if (_current is not null)
                _current.Kill(entireProcessTree: true);
        }
    }

    private int RunProcess(Process process, string tempPath)
    {
        try
        {
            process.Start();
            lock (_gate)
                _current = process;

            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            process.WaitForExit();
            var result = process.ExitCode;
            return result;
        }
        finally
        {
            lock (_gate)
                _current = null;
            process.Dispose();
            FileHelper.DeleteTempScript(tempPath);
        }
    }
}

using System.Diagnostics;
using System.Text;
using Orchestrator.Helpers;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class ScriptRunner
{
    private readonly object _gate = new object();
    private readonly PowerShellHost _host;
    private Process? _current;

    public ScriptRunner(PowerShellHost host)
    {
        _host = host;
    }

    public Result Run(string scriptText, Action<string> onLine)
    {
        var tempPath = FileHelper.WriteTempScript(scriptText);
        var output = new StringBuilder();

        var process = _host.BuildProcess(tempPath);
        RegisterOutputAdded(process, output, onLine);

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

    private void RegisterOutputAdded(Process process, StringBuilder output, Action<string> onLine)
    {
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

using System.Diagnostics;
using System.Text;
using Orchestrator.Helpers;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class ScriptRunner
{
    private readonly object _gate = new object();
    private readonly PowerShellHost _host;
    private Process? _currentProcess;

    public ScriptRunner(PowerShellHost host)
    {
        _host = host;
    }

    public Result Run(string scriptText, Action<string> onLine)
    {
        var tempScriptPath = FileHelper.WriteTempScript(scriptText);
        var outputBuffer = new StringBuilder();

        var process = _host.BuildProcess(tempScriptPath);
        RegisterOutputHandlers(process, outputBuffer, onLine);

        var exitCode = RunProcess(process, tempScriptPath);

        var result = new Result
        {
            ExitCode = exitCode,
            Output = outputBuffer.ToString(),
        };
        return result;
    }

    public void Cancel()
    {
        lock (_gate)
        {
            if (_currentProcess is not null)
                _currentProcess.Kill(entireProcessTree: true);
        }
    }

    private void RegisterOutputHandlers(Process process, StringBuilder outputBuffer, Action<string> onLine)
    {
        process.OutputDataReceived += (sender, eventArgs) =>
        {
            if (eventArgs.Data is null)
                return;
            lock (_gate)
            {
                outputBuffer.AppendLine(eventArgs.Data);
                onLine(eventArgs.Data);
            }
        };
        process.ErrorDataReceived += (sender, eventArgs) =>
        {
            if (eventArgs.Data is null)
                return;
            lock (_gate)
            {
                outputBuffer.AppendLine(eventArgs.Data);
                onLine(eventArgs.Data);
            }
        };
    }

    private int RunProcess(Process process, string tempScriptPath)
    {
        try
        {
            process.Start();
            lock (_gate)
                _currentProcess = process;

            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            process.WaitForExit();
            var exitCode = process.ExitCode;
            return exitCode;
        }
        finally
        {
            lock (_gate)
                _currentProcess = null;
            process.Dispose();
            FileHelper.DeleteTempScript(tempScriptPath);
        }
    }
}

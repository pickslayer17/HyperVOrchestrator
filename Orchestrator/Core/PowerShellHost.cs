using System.Diagnostics;

namespace Orchestrator.Core;

internal sealed class PowerShellHost
{
    private const string Shell7 = "pwsh.exe";
    private const string Shell5 = "powershell.exe";

    private readonly string _executable;
    private readonly int _majorVersion;

    public PowerShellHost()
    {
        if (IsAvailable(Shell7))
        {
            _executable = Shell7;
            _majorVersion = QueryMajorVersion(Shell7);
        }
        else
        {
            _executable = Shell5;
            _majorVersion = QueryMajorVersion(Shell5);
        }
    }

    public int MajorVersion => _majorVersion;

    public Process BuildProcess(string tempPath)
    {
        if (_executable == Shell7)
            return Build7(tempPath);
        var result = Build5(tempPath);
        return result;
    }

    private Process Build7(string tempPath)
    {
        var processStartInfo = BaseStartInfo(tempPath);
        var process = new Process { StartInfo = processStartInfo };
        return process;
    }

    private Process Build5(string tempPath)
    {
        var processStartInfo = BaseStartInfo(tempPath);

        var windowsDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
        var systemModules = Path.Combine(windowsDir, @"system32\WindowsPowerShell\v1.0\Modules");
        var programFilesModules = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"WindowsPowerShell\Modules");
        processStartInfo.Environment["PSModulePath"] = $"{programFilesModules};{systemModules}";

        var process = new Process { StartInfo = processStartInfo };
        return process;
    }

    private ProcessStartInfo BaseStartInfo(string tempPath)
    {
        var processStartInfo = new ProcessStartInfo
        {
            FileName = _executable,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        processStartInfo.ArgumentList.Add("-NoProfile");
        processStartInfo.ArgumentList.Add("-ExecutionPolicy");
        processStartInfo.ArgumentList.Add("Bypass");
        processStartInfo.ArgumentList.Add("-File");
        processStartInfo.ArgumentList.Add(tempPath);
        return processStartInfo;
    }

    private static bool IsAvailable(string executable)
    {
        var processStartInfo = new ProcessStartInfo
        {
            FileName = executable,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        processStartInfo.ArgumentList.Add("-NoProfile");
        processStartInfo.ArgumentList.Add("-Command");
        processStartInfo.ArgumentList.Add("exit 0");

        try
        {
            var process = Process.Start(processStartInfo)!;
            process.WaitForExit();
            return true;
        }
        catch (System.ComponentModel.Win32Exception)
        {
            return false;
        }
    }

    private static int QueryMajorVersion(string executable)
    {
        var processStartInfo = new ProcessStartInfo
        {
            FileName = executable,
            RedirectStandardOutput = true,
            UseShellExecute = false,
        };
        processStartInfo.ArgumentList.Add("-NoProfile");
        processStartInfo.ArgumentList.Add("-Command");
        processStartInfo.ArgumentList.Add("$PSVersionTable.PSVersion.Major");

        var process = Process.Start(processStartInfo)!;
        var output = process.StandardOutput.ReadToEnd().Trim();
        process.WaitForExit();

        var result = int.Parse(output);
        return result;
    }
}

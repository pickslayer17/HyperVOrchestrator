using System.Diagnostics;

namespace Orchestrator.Helpers;

internal static class SystemHelper
{
    public static int PowerShellMajorVersion()
    {
        var processStartInfo = new ProcessStartInfo
        {
            FileName = "powershell.exe",
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

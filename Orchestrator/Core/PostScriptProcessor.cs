using System.Text.RegularExpressions;
using Orchestrator.Helpers;
using Orchestrator.Models;

namespace Orchestrator.Core;

internal sealed class PostScriptProcessor
{
    private const string ExitMarkerPattern = @"^<<exit::(-?\d+)>>$";

    public Action<string> WrapLineHandler(Action<string> onLine)
    {
        return line =>
        {
            if (IsExitMarker(line))
                return;
            onLine(line);
        };
    }

    public Result Process(Result result)
    {
        var lines = result.Output.Split(Environment.NewLine);
        var cleanLines = new List<string>();
        var exitCode = result.ExitCode;

        foreach (var line in lines)
        {
            var match = RegexHelper.Get(ExitMarkerPattern, line.Trim(), RegexOptions.None);
            if (match.Success)
                exitCode = int.Parse(match.Groups[1].Value);
            else
                cleanLines.Add(line);
        }

        var processed = new Result
        {
            ExitCode = exitCode,
            Output = string.Join(Environment.NewLine, cleanLines),
        };
        return processed;
    }

    private static bool IsExitMarker(string line)
    {
        var result = RegexHelper.Get(ExitMarkerPattern, line.Trim(), RegexOptions.None).Success;
        return result;
    }
}

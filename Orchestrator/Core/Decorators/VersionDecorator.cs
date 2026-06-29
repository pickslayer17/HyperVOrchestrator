using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core.Decorators;

internal sealed class VersionDecorator : IScriptDecorator
{
    private const string VersionPattern = @"<<ver::([^>]+)>>";

    private readonly int _majorVersion;

    public VersionDecorator(int majorVersion)
    {
        _majorVersion = majorVersion;
    }

    public string Format(string script)
    {
        var result = RegexHelper.Replace(VersionPattern, script, ResolveVersion);
        return result;
    }

    private string ResolveVersion(Match match)
    {
        var body = match.Groups[1].Value;
        var map = BuildMap(body);
        var wanted = _majorVersion.ToString();

        if (map.TryGetValue(wanted, out var value))
            return value;
        throw new InvalidOperationException($"No value for PowerShell major version {_majorVersion} in: {match.Value}");
    }

    private static Dictionary<string, string> BuildMap(string body)
    {
        var map = new Dictionary<string, string>();
        var pairs = body.Split(',');
        foreach (var pair in pairs)
        {
            var trimmedPair = pair.Trim();
            var parts = trimmedPair.Split('=');
            var key = parts[0].Trim();
            var value = parts[1].Trim();
            map[key] = value;
        }
        return map;
    }
}

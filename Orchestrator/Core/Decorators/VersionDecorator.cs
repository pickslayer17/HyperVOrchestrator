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
        var versionSpec = match.Groups[1].Value;
        var versionMap = ParseVersionSpec(versionSpec);
        var wantedVersion = _majorVersion.ToString();

        if (versionMap.TryGetValue(wantedVersion, out var value))
            return value;
        throw new InvalidOperationException($"No value for PowerShell major version {_majorVersion} in: {match.Value}");
    }

    private static Dictionary<string, string> ParseVersionSpec(string versionSpec)
    {
        var versionMap = new Dictionary<string, string>();
        var pairs = versionSpec.Split(',');
        foreach (var pair in pairs)
        {
            var trimmedPair = pair.Trim();
            var parts = trimmedPair.Split('=');
            var key = parts[0].Trim();
            var value = parts[1].Trim();
            versionMap[key] = value;
        }
        return versionMap;
    }
}

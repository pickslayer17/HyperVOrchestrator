using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core;

internal sealed class ResultParser
{
    private const string SetPattern = @"<<set::\s*([a-zA-Z0-9_.]+)\s*=\s*(.*?)\s*>>";

    private readonly StateKeeper _stateKeeper;

    public ResultParser(StateKeeper stateKeeper)
    {
        _stateKeeper = stateKeeper;
    }

    public void CaptureSets(string line)
    {
        var matches = RegexHelper.MatchesMany(SetPattern, line);
        foreach (Match match in matches)
        {
            var key = match.Groups[1].Value;
            var value = match.Groups[2].Value;
            _stateKeeper.Set(key, value);
        }
    }
}

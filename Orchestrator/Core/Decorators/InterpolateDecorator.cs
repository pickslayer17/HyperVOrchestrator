using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core.Decorators;

internal sealed class InterpolateDecorator : IScriptDecorator
{
    private const string PlaceholderPattern = @"@@([a-zA-Z0-9_.]+)@@";

    private readonly IReadOnlyDictionary<string, string> _configValues;
    private readonly StateKeeper _stateKeeper;

    public InterpolateDecorator(IReadOnlyDictionary<string, string> configValues, StateKeeper stateKeeper)
    {
        _configValues = configValues;
        _stateKeeper = stateKeeper;
    }

    public string Format(string script)
    {
        var result = RegexHelper.Replace(PlaceholderPattern, script, ResolvePlaceholder);
        return result;
    }

    private string ResolvePlaceholder(Match match)
    {
        var key = match.Groups[1].Value;
        if (_configValues.TryGetValue(key, out var configValue) && !string.IsNullOrEmpty(configValue))
            return configValue;
        if (_stateKeeper.TryGet(key, out var stateValue) && !string.IsNullOrEmpty(stateValue))
            return stateValue;
        throw new InvalidOperationException($"Placeholder @@{key}@@ is missing or empty in config and state");
    }
}

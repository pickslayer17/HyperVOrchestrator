using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core;

internal sealed record SystemVariables(bool IsTargetVm, bool IsRootPriviledges);

internal static class SystemVariablesReader
{
    private const string TargetPattern = @"^\s*\$ScriptTarget\s*=\s*[""']?(Host|VM)[""']?\s*$";
    private const string AnyTargetPattern = @"^\s*\$ScriptTarget\s*=\s*(.+)$";
    private const string RootPattern = @"^\s*\$RootPriviledges\s*=\s*\$(true|false)";

    public static SystemVariables Read(string script)
    {
        var targetMatch = RegexHelper.Get(TargetPattern, script, RegexOptions.Multiline | RegexOptions.IgnoreCase);
        var anyTargetMatch = RegexHelper.Get(AnyTargetPattern, script, RegexOptions.Multiline | RegexOptions.IgnoreCase);
        if (anyTargetMatch.Success && !targetMatch.Success)
            throw new InvalidOperationException($"$ScriptTarget has invalid value '{anyTargetMatch.Groups[1].Value.Trim()}', expected 'Host' or 'VM'. Script will NOT be executed.");
        var isTargetVm = targetMatch.Success && targetMatch.Groups[1].Value.Equals("VM", StringComparison.OrdinalIgnoreCase);

        var rootMatch = RegexHelper.Get(RootPattern, script, RegexOptions.Multiline | RegexOptions.IgnoreCase);
        var isRootPriviledges = rootMatch.Success && rootMatch.Groups[1].Value.Equals("true", StringComparison.OrdinalIgnoreCase);

        var result = new SystemVariables(isTargetVm, isRootPriviledges);
        return result;
    }
}

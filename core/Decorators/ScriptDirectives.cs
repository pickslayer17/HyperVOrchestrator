using System.Text.RegularExpressions;

namespace Orchestrator;

internal enum ScriptTarget
{
    Host,
    Vm,
}

internal static partial class ScriptDirectives
{
    [GeneratedRegex(@"^\s*\$ScriptTarget\s*=\s*[""']?(Host|VM)[""']?",
        RegexOptions.Multiline | RegexOptions.IgnoreCase)]
    private static partial Regex TargetVariable();

    public static ScriptTarget ParseTarget(string scriptText)
    {
        var m = TargetVariable().Match(scriptText);
        if (m.Success && m.Groups[1].Value.Equals("vm", StringComparison.OrdinalIgnoreCase))
            return ScriptTarget.Vm;
        return ScriptTarget.Host;
    }
}

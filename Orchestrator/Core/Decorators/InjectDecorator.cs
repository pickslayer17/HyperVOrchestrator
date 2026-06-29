using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core.Decorators;

internal sealed class InjectDecorator : IScriptDecorator
{
    private const string InjectPattern = @"<<inject::([^>]+)>>";

    private readonly string _repoRoot;

    public InjectDecorator(string repoRoot)
    {
        _repoRoot = repoRoot;
    }

    public string Format(string script)
    {
        var result = RegexHelper.Replace(InjectPattern, script, ResolveInject);
        return result;
    }

    private string ResolveInject(Match match)
    {
        var relative = match.Groups[1].Value.Trim();
        var fullPath = Path.Combine(_repoRoot, relative.Replace('/', Path.DirectorySeparatorChar));
        var content = FileHelper.ReadText(fullPath);
        return content;
    }
}

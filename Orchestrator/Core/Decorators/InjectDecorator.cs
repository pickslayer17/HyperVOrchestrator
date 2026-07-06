using System.Text.RegularExpressions;
using Orchestrator.Helpers;

namespace Orchestrator.Core.Decorators;

internal sealed class InjectDecorator : IScriptDecorator
{
    private const string InjectPattern = @"<<inject::([^>]+)>>";

    private readonly string _scriptsRoot;

    public InjectDecorator(string scriptsRoot)
    {
        _scriptsRoot = scriptsRoot;
    }

    public string Format(string script)
    {
        var result = RegexHelper.Replace(InjectPattern, script, ResolveInject);
        return result;
    }

    private string ResolveInject(Match match)
    {
        var relativePath = match.Groups[1].Value.Trim();
        var fullPath = Path.Combine(_scriptsRoot, relativePath.Replace('/', Path.DirectorySeparatorChar));
        var content = FileHelper.ReadText(fullPath);
        return content;
    }
}

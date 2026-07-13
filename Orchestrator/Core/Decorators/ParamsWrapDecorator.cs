namespace Orchestrator.Core.Decorators;

internal sealed class ParamsWrapDecorator
{
    public string Format(string script, IReadOnlyDictionary<string, string>? args)
    {
        if (args is null || args.Count == 0)
            return script;

        var arguments = string.Join(" ", args.Select(pair => $"-{pair.Key} '{Escape(pair.Value)}'"));
        var result = $"& {{\n{script}\n}} {arguments}";
        return result;
    }

    private static string Escape(string value)
    {
        var result = value.Replace("'", "''");
        return result;
    }
}

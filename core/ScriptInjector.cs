using System.Text.RegularExpressions;

namespace Orchestrator;

internal static partial class ScriptInjector
{
    [GeneratedRegex(@"<<inject:([^>]+)>>")]
    private static partial Regex Directive();

    public static string Inject(string scriptText, string repoRoot)
    {
        return Directive().Replace(scriptText, m =>
        {
            var rel = m.Groups[1].Value.Trim();
            var full = Path.Combine(repoRoot, rel.Replace('/', Path.DirectorySeparatorChar));

            if (!File.Exists(full))
                throw new InvalidOperationException($"inject target not found: {rel}");

            var content = File.ReadAllText(full);
            if (Directive().IsMatch(content))
                throw new InvalidOperationException($"nested <<inject:>> not allowed (in {rel})");

            return content;
        });
    }
}

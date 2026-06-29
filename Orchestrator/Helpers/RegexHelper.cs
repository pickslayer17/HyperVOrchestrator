using System.Text.RegularExpressions;

namespace Orchestrator.Helpers;

internal static class RegexHelper
{
    public static string Replace(string pattern, string text, MatchEvaluator evaluator)
    {
        var result = Regex.Replace(text, pattern, evaluator);
        return result;
    }

    public static bool Matches(string pattern, string text)
    {
        var result = Regex.IsMatch(text, pattern);
        return result;
    }

    public static Match Get(string pattern, string text, RegexOptions options)
    {
        var result = Regex.Match(text, pattern, options);
        return result;
    }

    public static MatchCollection MatchesMany(string pattern, string text)
    {
        var result = Regex.Matches(text, pattern);
        return result;
    }
}

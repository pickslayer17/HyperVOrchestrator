using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace Orchestrator;

internal static partial class ConfigInterpolator
{
    [GeneratedRegex(@"@@([a-zA-Z0-9_.]+)@@")]
    private static partial Regex Placeholder();

    public static string Interpolate(string scriptText, IReadOnlyDictionary<string, string> values)
    {
        return Placeholder().Replace(scriptText, m =>
        {
            var key = m.Groups[1].Value;
            if (values.TryGetValue(key, out var value))
                return value;
            throw new InvalidOperationException($"Unknown config placeholder: @@{key}@@");
        });
    }

    public static IReadOnlyDictionary<string, string> Flatten(AppConfig config)
    {

        var opts = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        using var doc = JsonDocument.Parse(JsonSerializer.Serialize(config, opts));

        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        Walk(doc.RootElement, "", map);
        return map;
    }

    private static void Walk(JsonElement el, string prefix, Dictionary<string, string> map)
    {
        switch (el.ValueKind)
        {
            case JsonValueKind.Object:
                foreach (var prop in el.EnumerateObject())
                {
                    var key = prefix == "" ? prop.Name : $"{prefix}.{prop.Name}";
                    Walk(prop.Value, key, map);
                }
                break;

            case JsonValueKind.Array:

                var items = new StringBuilder();
                var first = true;
                foreach (var item in el.EnumerateArray())
                {
                    if (!first) items.Append(',');
                    items.Append(item.ToString());
                    first = false;
                }
                map[prefix] = items.ToString();
                break;

            default:
                map[prefix] = el.ToString();
                break;
        }
    }
}

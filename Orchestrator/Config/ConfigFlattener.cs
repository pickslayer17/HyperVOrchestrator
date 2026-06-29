using System.Text;
using System.Text.Json;

namespace Orchestrator.Config;

internal static class ConfigFlattener
{
    public static IReadOnlyDictionary<string, string> Flatten(AppConfig config)
    {
        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var serialized = JsonSerializer.Serialize(config, options);
        using var document = JsonDocument.Parse(serialized);

        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        Walk(document.RootElement, "", map);
        return map;
    }

    private static void Walk(JsonElement element, string prefix, Dictionary<string, string> map)
    {
        if (element.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in element.EnumerateObject())
            {
                var key = prefix == "" ? property.Name : $"{prefix}.{property.Name}";
                Walk(property.Value, key, map);
            }
            return;
        }

        if (element.ValueKind == JsonValueKind.Array)
        {
            var items = new StringBuilder();
            var first = true;
            foreach (var item in element.EnumerateArray())
            {
                if (!first)
                    items.Append(',');
                items.Append(item.ToString());
                first = false;
            }
            map[prefix] = items.ToString();
            return;
        }

        map[prefix] = element.ToString();
    }
}

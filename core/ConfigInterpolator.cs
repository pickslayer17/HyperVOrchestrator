using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace Orchestrator;

// Подменяет плейсхолдеры @@dotted.path@@ в тексте скрипта значениями из конфига.
// Путь — точечный, как в JSON: @@vm.name@@, @@network.vmIp@@, @@paths.windowsIso@@.
// Скрипту всё равно, где он выполнится — он получает готовый текст с подставленными
// значениями (как и было в исходном проекте).
internal static partial class ConfigInterpolator
{
    [GeneratedRegex(@"@@([a-zA-Z0-9_.]+)@@")]
    private static partial Regex Placeholder();

    // Возвращает интерполированный текст. Если в тексте встретился плейсхолдер,
    // которого нет в карте, бросает — лучше упасть, чем выполнить скрипт с дырой.
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

    // Плоская карта "точечный путь -> строковое значение" из дерева конфига.
    // paths.* берём уже резолвленные (абсолютные) из AppConfig.
    public static IReadOnlyDictionary<string, string> Flatten(AppConfig config)
    {
        // Сериализуем в JSON и обходим дерево — так карта всегда совпадает
        // со структурой конфига, без ручного перечисления полей.
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
                // Массивы (напр. office.apps) -> через запятую. Редко нужно в скриптах,
                // но пусть будет, а не дыра.
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

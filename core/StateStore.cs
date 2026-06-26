using System.Text.Json;
using System.Text.RegularExpressions;

namespace Orchestrator;

// Слой РАНТАЙМ-СОСТОЯНИЯ. Значения, вычисленные во время выполнения шагов
// (напр. IP/индекс адаптера прокси), которых нет в статическом конфиге.
//
// Скрипт эмитит значение строкой на stdout:
//
//     Write-Host "::set state.proxyIp=192.168.50.1"
//
// Оркестратор ловит её, кладёт в карту интерполяции (следующий шаг увидит
// @@state.proxyIp@@ так же, как @@vm.name@@) и пишет в JSON-файл, чтобы
// значение пережило перезапуск оркестратора.
//
// Формат файла — плоский JSON: { "state.proxyIp": "192.168.50.1" }.
internal sealed partial class StateStore
{
    [GeneratedRegex(@"^\s*::set\s+([a-zA-Z0-9_.]+)\s*=\s*(.*?)\s*$")]
    private static partial Regex SetMarker();

    private readonly string _path; // пустой -> персиста нет, только in-memory
    private readonly Dictionary<string, string> _state;

    public StateStore(string path)
    {
        _path = path ?? "";
        _state = LoadFile();
    }

    // Накопленные рантайм-значения (для начальной загрузки в карту интерполяции).
    public IReadOnlyDictionary<string, string> Values => _state;

    // Применить пары из ::set: положить в персист и в живую карту интерполяции,
    // сохранить файл. live — та же карта, что раздаётся скриптам.
    public void Apply(IReadOnlyList<(string Key, string Value)> sets, IDictionary<string, string> live)
    {
        if (sets.Count == 0)
            return;

        foreach (var (key, value) in sets)
        {
            _state[key] = value;
            live[key] = value;
        }
        Save();
    }

    // Проверить ОДНУ строку вывода: ::set-маркер -> пара (key, value), иначе null.
    // Раннер зовёт это построчно по мере поступления вывода из powershell.
    public static (string Key, string Value)? MatchSet(string line)
    {
        var m = SetMarker().Match(line);
        return m.Success ? (m.Groups[1].Value, m.Groups[2].Value) : null;
    }

    private Dictionary<string, string> LoadFile()
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (string.IsNullOrEmpty(_path) || !File.Exists(_path))
            return map;
        try
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(_path));
            foreach (var prop in doc.RootElement.EnumerateObject())
                map[prop.Name] = prop.Value.ToString();
        }
        catch
        {
            // битый файл — начинаем с чистого состояния, не падаем.
        }
        return map;
    }

    private void Save()
    {
        if (string.IsNullOrEmpty(_path))
            return;
        Directory.CreateDirectory(Path.GetDirectoryName(_path)!);
        var json = JsonSerializer.Serialize(_state, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(_path, json);
    }
}

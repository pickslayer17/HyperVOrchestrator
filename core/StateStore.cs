using System.Text.Json;
using System.Text.RegularExpressions;

namespace Orchestrator;

internal sealed partial class StateStore
{
    [GeneratedRegex(@"^\s*::set\s+([a-zA-Z0-9_.]+)\s*=\s*(.*?)\s*$")]
    private static partial Regex SetMarker();

    private readonly string _path;
    private readonly Dictionary<string, string> _state;

    public StateStore(string path)
    {
        _path = path ?? "";
        _state = LoadFile();
    }

    public IReadOnlyDictionary<string, string> Values => _state;

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

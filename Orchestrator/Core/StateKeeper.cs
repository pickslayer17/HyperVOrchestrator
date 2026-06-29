using System.Text.Json;

namespace Orchestrator.Core;

internal sealed class StateKeeper
{
    private readonly string _path;
    private readonly Dictionary<string, string> _state;

    public StateKeeper(string path)
    {
        _path = path;
        _state = Load();
    }

    public bool TryGet(string key, out string value)
    {
        var found = _state.TryGetValue(key, out var stored);
        value = stored ?? "";
        return found;
    }

    public void Set(string key, string value)
    {
        _state[key] = value;
        Save();
    }

    private Dictionary<string, string> Load()
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (!File.Exists(_path))
            return map;

        var text = File.ReadAllText(_path);
        using var document = JsonDocument.Parse(text);
        foreach (var property in document.RootElement.EnumerateObject())
            map[property.Name] = property.Value.ToString();
        return map;
    }

    private void Save()
    {
        var directory = Path.GetDirectoryName(_path)!;
        Directory.CreateDirectory(directory);
        var options = new JsonSerializerOptions { WriteIndented = true };
        var json = JsonSerializer.Serialize(_state, options);
        File.WriteAllText(_path, json);
    }
}

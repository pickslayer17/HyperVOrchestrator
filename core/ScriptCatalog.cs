namespace Orchestrator;

internal sealed record ScriptStep
{
    public required string Name { get; init; }

    public required string Group { get; init; }

    public required string ScriptPath { get; init; }

    public string? CheckPath { get; init; }

    public string Id => $"{Group}/{Name}";
}

internal static class ScriptCatalog
{
    private const string CheckSuffix = ".check";

    public static IReadOnlyList<ScriptStep> Scan(string scriptsDir)
    {
        if (!Directory.Exists(scriptsDir))
            return [];

        var allPs1 = Directory.EnumerateFiles(scriptsDir, "*.ps1", SearchOption.AllDirectories)
                              .ToList();

        var checks = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var path in allPs1)
        {
            var baseName = Path.GetFileNameWithoutExtension(path);
            if (!baseName.EndsWith(CheckSuffix, StringComparison.OrdinalIgnoreCase))
                continue;
            var stepName = baseName[..^CheckSuffix.Length];
            var dir = Path.GetDirectoryName(path)!;
            checks[Key(dir, stepName)] = path;
        }

        var steps = new List<ScriptStep>();
        foreach (var path in allPs1)
        {
            var baseName = Path.GetFileNameWithoutExtension(path);
            if (baseName.EndsWith(CheckSuffix, StringComparison.OrdinalIgnoreCase))
                continue;

            var dir = Path.GetDirectoryName(path)!;
            checks.TryGetValue(Key(dir, baseName), out var checkPath);

            steps.Add(new ScriptStep
            {
                Name = baseName,
                Group = RelativeGroup(scriptsDir, dir),
                ScriptPath = path,
                CheckPath = checkPath,
            });
        }

        return steps
            .OrderBy(s => s.Group, StringComparer.OrdinalIgnoreCase)
            .ThenBy(s => s.Name, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string Key(string dir, string stepName) =>
        Path.Combine(dir, stepName);

    private static string RelativeGroup(string scriptsDir, string dir)
    {
        var rel = Path.GetRelativePath(scriptsDir, dir);
        return rel == "." ? "" : rel;
    }
}

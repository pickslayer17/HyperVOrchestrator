namespace Orchestrator;

// Один шаг = основной скрипт (foo.ps1) + опциональный check (foo.check.ps1).
internal sealed record ScriptStep
{
    // Имя шага = имя основного файла без .ps1, напр. "01-Build-Vhdx" или "test".
    public required string Name { get; init; }

    // Относительная папка внутри scripts/, напр. "CreateAndWinInstall" или "".
    // Используется для группировки в меню.
    public required string Group { get; init; }

    // Полный путь к основному скрипту ("сделать дело").
    public required string ScriptPath { get; init; }

    // Полный путь к check-скрипту ("можно ли запускать"), либо null если пары нет.
    public string? CheckPath { get; init; }
}

// Сканирует scripts/ рекурсивно и строит плоский список шагов для меню.
// Файлы вида foo.check.ps1 — это пары-проверки, отдельными пунктами не идут.
internal static class ScriptCatalog
{
    private const string CheckSuffix = ".check";

    public static IReadOnlyList<ScriptStep> Scan(string scriptsDir)
    {
        if (!Directory.Exists(scriptsDir))
            return [];

        var allPs1 = Directory.EnumerateFiles(scriptsDir, "*.ps1", SearchOption.AllDirectories)
                              .ToList();

        // Индекс check-скриптов: ключ = (папка + имя шага), значение = путь.
        var checks = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var path in allPs1)
        {
            var baseName = Path.GetFileNameWithoutExtension(path); // отрезает .ps1
            if (!baseName.EndsWith(CheckSuffix, StringComparison.OrdinalIgnoreCase))
                continue;
            var stepName = baseName[..^CheckSuffix.Length]; // убрать ".check"
            var dir = Path.GetDirectoryName(path)!;
            checks[Key(dir, stepName)] = path;
        }

        var steps = new List<ScriptStep>();
        foreach (var path in allPs1)
        {
            var baseName = Path.GetFileNameWithoutExtension(path); // отрезает .ps1
            if (baseName.EndsWith(CheckSuffix, StringComparison.OrdinalIgnoreCase))
                continue; // это check-пара, не самостоятельный шаг

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

        // Сортировка: сперва по группе, потом по имени файла (00-, 01-... дают порядок).
        return steps
            .OrderBy(s => s.Group, StringComparer.OrdinalIgnoreCase)
            .ThenBy(s => s.Name, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string Key(string dir, string stepName) =>
        Path.Combine(dir, stepName);

    // Путь папки относительно scripts/. Для файлов в корне scripts/ -> "".
    private static string RelativeGroup(string scriptsDir, string dir)
    {
        var rel = Path.GetRelativePath(scriptsDir, dir);
        return rel == "." ? "" : rel;
    }
}

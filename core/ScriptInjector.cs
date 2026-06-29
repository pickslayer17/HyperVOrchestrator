using System.Text.RegularExpressions;

namespace Orchestrator;

// Слой ИНЪЕКЦИИ. До интерполяции вставляет содержимое helper/data-файлов в текст
// скрипта по директиве:
//
//     <<inject:scriptHelpers/RegistryHelpers.ps1>>
//     <<inject:scriptData/RegistryTweaks.ps1>>
//
// Зачем именно так, а не интерполяцией: скрипты исполняются ВНУТРИ ВМ через
// Invoke-Command — файлов хелперов в госте нет, дотсорсить нечего. Поэтому
// движок склеивает [helper] + [data] + [тело] в один текст ещё на хосте.
//
// Почему ДО интерполяции: в самом хелпере/данных может встретиться @@vm.name@@ —
// его должен подхватить общий проход ConfigInterpolator уже после вставки.
//
// Путь в директиве — ОТНОСИТЕЛЬНО корня репо (как и всё в проекте). Один уровень:
// вставленный файл сам инъекции не разворачивает (нашли <<inject:>> внутри — это
// ошибка, чтобы не плодить скрытую рекурсию).
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

using System.Text.RegularExpressions;

namespace Orchestrator;

// Где исполняется скрипт.
internal enum ScriptTarget
{
    Host, // на хосте локально
    Vm,   // ВНУТРИ ВМ — оркестратор сам завернёт тело в Invoke-Command
}

// Слой ПАРСИНГА директив скрипта. Цель исполнения объявляется РЕАЛЬНОЙ
// переменной в начале файла (видна, является частью кода, не теряется как
// комментарий):
//
//     $ScriptTarget = "VM"     # или "Host"
//
// ВМ одна на весь процесс, поэтому имя в переменной не пишем — оно берётся
// из конфига (vm.name). Переменную читаем регуляркой, БЕЗ исполнения скрипта.
// Нет переменной -> Host (на хосте, безопасное поведение по умолчанию).
internal static partial class ScriptDirectives
{
    [GeneratedRegex(@"^\s*\$ScriptTarget\s*=\s*[""']?(Host|VM)[""']?",
        RegexOptions.Multiline | RegexOptions.IgnoreCase)]
    private static partial Regex TargetVariable();

    public static ScriptTarget ParseTarget(string scriptText)
    {
        var m = TargetVariable().Match(scriptText);
        if (m.Success && m.Groups[1].Value.Equals("vm", StringComparison.OrdinalIgnoreCase))
            return ScriptTarget.Vm;
        return ScriptTarget.Host;
    }
}

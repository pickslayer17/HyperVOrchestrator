using System.Text.RegularExpressions;

namespace Orchestrator;

// Где исполняется скрипт.
internal enum ScriptTarget
{
    Host, // на хосте локально (по умолчанию)
    Vm,   // ВНУТРИ ВМ — оркестратор сам завернёт тело в Invoke-Command
}

// Слой ПАРСИНГА директив скрипта. Директива — строка-комментарий в стиле
// #Requires, читается БЕЗ исполнения скрипта:
//
//     #:target vm
//
// Нет директивы (или "#:target host") -> Host. ВМ одна на весь процесс,
// поэтому имя в директиве не пишем — оно берётся из конфига (vm.name).
internal static partial class ScriptDirectives
{
    [GeneratedRegex(@"^\s*#:target\s+(vm|host)\b", RegexOptions.Multiline | RegexOptions.IgnoreCase)]
    private static partial Regex TargetDirective();

    public static ScriptTarget ParseTarget(string scriptText)
    {
        var m = TargetDirective().Match(scriptText);
        if (m.Success && m.Groups[1].Value.Equals("vm", StringComparison.OrdinalIgnoreCase))
            return ScriptTarget.Vm;
        return ScriptTarget.Host;
    }
}

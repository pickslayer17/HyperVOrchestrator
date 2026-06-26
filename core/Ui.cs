namespace Orchestrator;

// Слой ВЫВОДА: цвета, промпты, печать строк. Никакой логики выполнения/парсинга.
// Стрелочное меню живёт отдельно в Menu.cs (свой рендер).
internal static class Ui
{
    public static void Line(string text, ConsoleColor color)
    {
        var prev = Console.ForegroundColor;
        Console.ForegroundColor = color;
        Console.WriteLine(text);
        Console.ForegroundColor = prev;
    }

    public static void Plain(string text) => Console.WriteLine(text);
    public static void Blank() => Console.WriteLine();
    public static void Raw(string text) => Console.Write(text);

    // Промпт + чтение строки. Чистим whitespace и невидимые символы
    // (BOM / zero-width space), которые лезут при piped-вводе.
    public static string Prompt(string label)
    {
        Console.Write(label);
        return (Console.ReadLine() ?? "").Trim().Trim('﻿', '​').Trim();
    }
}

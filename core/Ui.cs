namespace Orchestrator;

// Слой ВЫВОДА. Всё, что печатается в консоль, живёт здесь — цвета, меню,
// промпты. Никакой логики выполнения/парсинга: только рисование.
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

    public static void Menu(IReadOnlyList<ScriptStep> steps, SessionStatus status)
    {
        Console.WriteLine();
        Console.WriteLine("  TestRunner orchestrator");
        Console.WriteLine("  =======================");
        Console.WriteLine();

        if (steps.Count == 0)
        {
            Line("  (no scripts found)", ConsoleColor.Red);
        }
        else
        {
            string? lastGroup = null;
            for (var i = 0; i < steps.Count; i++)
            {
                var step = steps[i];
                if (step.Group != lastGroup)
                {
                    var label = step.Group == "" ? "(root)" : step.Group;
                    Line($"  [{label}]", ConsoleColor.DarkGray);
                    lastGroup = step.Group;
                }
                Line($"  {i + 1,2}. {step.Name}", status.ColorFor(step.Id));
            }
        }

        Console.WriteLine();
        Console.WriteLine("  (q to quit)");
        Console.WriteLine();
    }
}

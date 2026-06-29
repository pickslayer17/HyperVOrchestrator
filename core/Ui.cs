namespace Orchestrator;

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

    public static void Clear()
    {
        try { Console.Clear(); }
        catch (IOException) { Console.WriteLine(new string('\n', 3)); }
    }

    public static string Prompt(string label)
    {
        Console.Write(label);
        return (Console.ReadLine() ?? "").Trim().Trim('﻿', '​').Trim();
    }
}

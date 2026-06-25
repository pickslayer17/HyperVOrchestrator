using System.Diagnostics;

namespace Orchestrator;

internal static class Program
{
    private static int Main()
    {
        var repoRoot = FindRepoRoot();
        var scriptsDir = Path.Combine(repoRoot, "scripts");

        while (true)
        {
            DrawMenu();
            Console.Write("Choose step: ");
            var input = CleanInput(Console.ReadLine());

            if (string.IsNullOrEmpty(input))
                continue;

            if (input is "q" or "Q" or "0")
            {
                Console.WriteLine("Bye.");
                return 0;
            }

            if (input == "1")
            {
                RunStep("test", scriptsDir);
            }
            else
            {
                WriteLine($"Unknown choice: {input}", ConsoleColor.Red);
            }

            Console.WriteLine();
            Console.WriteLine("Press Enter to return to menu...");
            Console.ReadLine();
        }
    }

    private static void DrawMenu()
    {
        Console.WriteLine();
        Console.WriteLine("  TestRunner orchestrator");
        Console.WriteLine("  =======================");
        Console.WriteLine();
        WriteLine("  1. test", ConsoleColor.Blue);
        Console.WriteLine();
        Console.WriteLine("  (q to quit)");
        Console.WriteLine();
    }

    // Шаг = два скрипта: scripts/<name>.ps1 (positive) и scripts/_<name>.ps1 (negative).
    // На этом срезе просто гоним оба по очереди и печатаем результат.
    private static void RunStep(string name, string scriptsDir)
    {
        var positive = Path.Combine(scriptsDir, $"{name}.ps1");
        var negative = Path.Combine(scriptsDir, $"_{name}.ps1");

        RunScript(negative);
        RunScript(positive);
    }

    // Будущий RunOnHost: запуск .ps1 на хосте через внешний powershell.exe.
    private static void RunScript(string scriptPath)
    {
        Console.WriteLine();
        WriteLine($"--- {Path.GetFileName(scriptPath)} ---", ConsoleColor.DarkGray);

        if (!File.Exists(scriptPath))
        {
            WriteLine($"[X] script not found: {scriptPath}", ConsoleColor.Red);
            return;
        }

        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\"",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };

        using var proc = Process.Start(psi)!;
        var stdout = proc.StandardOutput.ReadToEnd();
        var stderr = proc.StandardError.ReadToEnd();
        proc.WaitForExit();

        if (!string.IsNullOrWhiteSpace(stdout))
            Console.Write(stdout);
        if (!string.IsNullOrWhiteSpace(stderr))
            WriteLine(stderr.TrimEnd(), ConsoleColor.Red);

        if (proc.ExitCode == 0)
            WriteLine($"[OK] exit {proc.ExitCode}", ConsoleColor.Green);
        else
            WriteLine($"[X] exit {proc.ExitCode}", ConsoleColor.Red);
    }

    // Корень репо = ближайшая вверх по дереву папка, содержащая scripts/.
    // Не зависит от глубины bin/Debug/netX.
    private static string FindRepoRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null)
        {
            if (Directory.Exists(Path.Combine(dir.FullName, "scripts")))
                return dir.FullName;
            dir = dir.Parent;
        }
        throw new InvalidOperationException("Repo root not found (no 'scripts' folder above the exe).");
    }

    // Trim whitespace plus BOM (U+FEFF) / zero-width space (U+200B) that can
    // sneak in when input is piped (e.g. PowerShell here-strings).
    private static string? CleanInput(string? raw) =>
        raw?.Trim().Trim('﻿', '​').Trim();

    private static void WriteLine(string text, ConsoleColor color)
    {
        var prev = Console.ForegroundColor;
        Console.ForegroundColor = color;
        Console.WriteLine(text);
        Console.ForegroundColor = prev;
    }
}

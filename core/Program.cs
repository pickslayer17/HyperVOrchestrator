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
            var steps = ScriptCatalog.Scan(scriptsDir);
            DrawMenu(steps);

            Console.Write("Choose step: ");
            var input = CleanInput(Console.ReadLine());

            if (string.IsNullOrEmpty(input))
                continue;

            if (input is "q" or "Q" or "0")
            {
                Console.WriteLine("Bye.");
                return 0;
            }

            if (int.TryParse(input, out var choice) && choice >= 1 && choice <= steps.Count)
            {
                RunStep(steps[choice - 1]);
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

    private static void DrawMenu(IReadOnlyList<ScriptStep> steps)
    {
        Console.WriteLine();
        Console.WriteLine("  TestRunner orchestrator");
        Console.WriteLine("  =======================");
        Console.WriteLine();

        if (steps.Count == 0)
        {
            WriteLine("  (no scripts found)", ConsoleColor.Red);
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
                    WriteLine($"  [{label}]", ConsoleColor.DarkGray);
                    lastGroup = step.Group;
                }
                WriteLine($"  {i + 1,2}. {step.Name}", ConsoleColor.Blue);
            }
        }

        Console.WriteLine();
        Console.WriteLine("  (q to quit)");
        Console.WriteLine();
    }

    // Шаг = основной скрипт + опциональный .check.ps1.
    // Есть check -> гоним его первым; exit 0 => запускаем основной, иначе стоп.
    // Нет check -> "script without checks", сразу запускаем основной.
    private static void RunStep(ScriptStep step)
    {
        if (step.CheckPath is null)
        {
            WriteLine("script without checks", ConsoleColor.DarkGray);
        }
        else
        {
            var (checkExit, _) = Execute(step.CheckPath);
            if (checkExit != 0)
            {
                WriteLine($"[X] check failed (exit {checkExit}) — not running {step.Name}.", ConsoleColor.Red);
                return;
            }
        }

        RunScript(step.ScriptPath);
    }

    // Основной скрипт: "сделать дело". Репортит ✓/✗ по exit code.
    // Зародыш IStep.Do / будущего RunOnHost.
    private static void RunScript(string scriptPath)
    {
        var (exit, found) = Execute(scriptPath);
        if (!found)
            return;

        if (exit == 0)
            WriteLine($"[OK] exit {exit}", ConsoleColor.Green);
        else
            WriteLine($"[X] exit {exit}", ConsoleColor.Red);
    }

    // Общая механика: запуск .ps1 на хосте через внешний powershell.exe,
    // печать stdout/stderr. Возвращает exit code и был ли найден файл.
    private static (int exitCode, bool found) Execute(string scriptPath)
    {
        Console.WriteLine();
        WriteLine($"--- {Path.GetFileName(scriptPath)} ---", ConsoleColor.DarkGray);

        if (!File.Exists(scriptPath))
        {
            WriteLine($"[X] script not found: {scriptPath}", ConsoleColor.Red);
            return (-1, false);
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

        return (proc.ExitCode, true);
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

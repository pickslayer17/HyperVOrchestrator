using System.Diagnostics;

namespace Orchestrator;

internal static class Program
{
    // Результаты шагов в текущей сессии (по ScriptStep.Id).
    // В меню: зелёный — успех, красный — провал, синий — ещё не запускался.
    private static readonly HashSet<string> Succeeded = [];
    private static readonly HashSet<string> Failed = [];

    private static int Main()
    {
        var repoRoot = FindRepoRoot();
        var scriptsDir = Path.Combine(repoRoot, "scripts");
        var config = AppConfig.Load(repoRoot);
        var values = ConfigInterpolator.Flatten(config);

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
                var step = steps[choice - 1];
                if (RunStep(step, values))
                {
                    Succeeded.Add(step.Id);
                    Failed.Remove(step.Id);
                }
                else
                {
                    Failed.Add(step.Id);
                    Succeeded.Remove(step.Id);
                }
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
                var color =
                    Succeeded.Contains(step.Id) ? ConsoleColor.Green :
                    Failed.Contains(step.Id) ? ConsoleColor.Red :
                    ConsoleColor.Blue;
                WriteLine($"  {i + 1,2}. {step.Name}", color);
            }
        }

        Console.WriteLine();
        Console.WriteLine("  (q to quit)");
        Console.WriteLine();
    }

    // Шаг = основной скрипт + опциональный .check.ps1.
    // Есть check -> гоним его первым; exit 0 => запускаем основной, иначе стоп.
    // Нет check -> "script without checks", сразу запускаем основной.
    // Возвращает true, если основной скрипт отработал успешно (exit 0).
    private static bool RunStep(ScriptStep step, IReadOnlyDictionary<string, string> values)
    {
        if (step.CheckPath is null)
        {
            WriteLine("script without checks", ConsoleColor.DarkGray);
        }
        else
        {
            var (checkExit, _) = Execute(step.CheckPath, values);
            if (checkExit != 0)
            {
                WriteLine($"[X] check failed (exit {checkExit}) — not running {step.Name}.", ConsoleColor.Red);
                return false;
            }
        }

        return RunScript(step.ScriptPath, values);
    }

    // Основной скрипт: "сделать дело". Репортит ✓/✗ по exit code.
    // Возвращает true при exit 0. Зародыш IStep.Do / будущего RunOnHost.
    private static bool RunScript(string scriptPath, IReadOnlyDictionary<string, string> values)
    {
        var (exit, found) = Execute(scriptPath, values);
        if (!found)
            return false;

        if (exit == 0)
        {
            WriteLine($"[OK] exit {exit}", ConsoleColor.Green);
            return true;
        }

        WriteLine($"[X] exit {exit}", ConsoleColor.Red);
        return false;
    }

    // Общая механика: прочитать текст .ps1, подменить @@config.path@@ значениями
    // из конфига, выполнить готовый текст через powershell.exe. Скрипту всё равно,
    // где он выполнится — он получает уже интерполированный текст.
    private static (int exitCode, bool found) Execute(string scriptPath, IReadOnlyDictionary<string, string> values)
    {
        Console.WriteLine();
        WriteLine($"--- {Path.GetFileName(scriptPath)} ---", ConsoleColor.DarkGray);

        if (!File.Exists(scriptPath))
        {
            WriteLine($"[X] script not found: {scriptPath}", ConsoleColor.Red);
            return (-1, false);
        }

        string interpolated;
        try
        {
            interpolated = ConfigInterpolator.Interpolate(File.ReadAllText(scriptPath), values);
        }
        catch (InvalidOperationException ex)
        {
            WriteLine($"[X] {ex.Message}", ConsoleColor.Red);
            return (-1, false);
        }

        // Готовую строку скармливаем powershell через stdin (-Command -), без файлов.
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        psi.ArgumentList.Add("-NoProfile");
        psi.ArgumentList.Add("-ExecutionPolicy");
        psi.ArgumentList.Add("Bypass");
        psi.ArgumentList.Add("-Command");
        psi.ArgumentList.Add("-");

        using var proc = Process.Start(psi)!;
        proc.StandardInput.Write(interpolated);
        proc.StandardInput.Close();

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

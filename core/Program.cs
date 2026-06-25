namespace Orchestrator;

// Точка входа и ОРКЕСТРАЦИЯ. Вывод -> Ui, выполнение -> ScriptRunner,
// интерполяция -> ConfigInterpolator, рантайм-state -> StateStore,
// статус меню -> SessionStatus. Здесь только склейка и цикл меню.
internal static class Program
{
    private static int Main()
    {
        var repoRoot = FindRepoRoot();
        var scriptsDir = Path.Combine(repoRoot, "scripts");
        var config = AppConfig.Load(repoRoot);

        // Живая карта значений: статический конфиг + рантайм-state поверх.
        var values = new Dictionary<string, string>(ConfigInterpolator.Flatten(config), StringComparer.OrdinalIgnoreCase);
        var state = new StateStore(config.Paths.StateFile);
        foreach (var kv in state.Values)
            values[kv.Key] = kv.Value;

        var runner = new ScriptRunner(values);
        var status = new SessionStatus();

        while (true)
        {
            var steps = ScriptCatalog.Scan(scriptsDir);
            Ui.Menu(steps, status);

            var input = Ui.Prompt("Choose step: ");
            if (string.IsNullOrEmpty(input))
                continue;
            if (input is "q" or "Q" or "0")
            {
                Ui.Plain("Bye.");
                return 0;
            }

            if (int.TryParse(input, out var choice) && choice >= 1 && choice <= steps.Count)
            {
                var step = steps[choice - 1];
                if (RunStep(step, runner, state, values))
                    status.MarkOk(step.Id);
                else
                    status.MarkFailed(step.Id);
            }
            else
            {
                Ui.Line($"Unknown choice: {input}", ConsoleColor.Red);
            }

            Ui.Blank();
            Ui.Prompt("Press Enter to return to menu...");
        }
    }

    // Шаг = check (опционально) + основной скрипт.
    // Есть check -> гоним первым; exit 0 => запускаем основной, иначе стоп.
    // Возвращает true, если основной скрипт отработал успешно (exit 0).
    private static bool RunStep(ScriptStep step, ScriptRunner runner, StateStore state, IDictionary<string, string> values)
    {
        if (step.CheckPath is null)
        {
            Ui.Line("script without checks", ConsoleColor.DarkGray);
        }
        else
        {
            var check = Execute(step.CheckPath, runner, state, values);
            if (!check.Found || check.ExitCode != 0)
            {
                Ui.Line($"[X] check failed (exit {check.ExitCode}) — not running {step.Name}.", ConsoleColor.Red);
                return false;
            }
        }

        var result = Execute(step.ScriptPath, runner, state, values);
        if (!result.Found)
            return false;

        if (result.ExitCode == 0)
        {
            Ui.Line($"[OK] exit {result.ExitCode}", ConsoleColor.Green);
            return true;
        }

        Ui.Line($"[X] exit {result.ExitCode}", ConsoleColor.Red);
        return false;
    }

    // Запустить один .ps1: показать заголовок, отдать в runner, применить
    // ::set в state/карту, напечатать вывод. Печать живёт здесь, не в runner.
    private static RunResult Execute(string scriptPath, ScriptRunner runner, StateStore state, IDictionary<string, string> values)
    {
        Ui.Blank();
        Ui.Line($"--- {Path.GetFileName(scriptPath)} ---", ConsoleColor.DarkGray);

        var result = runner.Run(scriptPath);

        if (result.Error is not null)
        {
            Ui.Line($"[X] {result.Error}", ConsoleColor.Red);
            return result;
        }

        state.Apply(result.Sets, values);

        if (!string.IsNullOrWhiteSpace(result.Stdout))
            Ui.Raw(result.Stdout.EndsWith('\n') ? result.Stdout : result.Stdout + "\n");
        if (!string.IsNullOrWhiteSpace(result.Stderr))
            Ui.Line(result.Stderr.TrimEnd(), ConsoleColor.Red);
        foreach (var (key, value) in result.Sets)
            Ui.Line($"  state: {key} = {value}", ConsoleColor.DarkGray);

        return result;
    }

    // Корень репо = ближайшая вверх папка, содержащая scripts/. Не зависит от
    // глубины bin/Debug/netX.
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
}

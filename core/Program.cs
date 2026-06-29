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

        // Рендер unattend: шаблон с @@@@ -> рабочий xml тем же интерполятором.
        // Подстановку делает движок, а не скрипт; build-скрипт копирует готовый файл.
        RenderUnattend(config, values);

        var runner = new ScriptRunner(values, repoRoot);
        var status = new SessionStatus();

        // Ctrl+C прерывает ТЕКУЩИЙ шаг (убивает процесс + дерево) и возвращает в
        // меню, а не закрывает оркестратор. Выход — только через 'q'.
        Console.CancelKeyPress += (_, e) =>
        {
            e.Cancel = true;
            runner.Cancel();
        };

        // Сьюты = шаги, сгруппированные по папке, в порядке каталога (00-, 10-...).
        var suites = ScriptCatalog.Scan(scriptsDir)
            .GroupBy(s => s.Group)
            .Select(g => (g.Key, (IReadOnlyList<ScriptStep>)g.ToList()))
            .ToList();

        new Menu(suites, status, RunStepTracked).Run();
        return 0;

        // Выполнить один шаг + отметить статус. Падения уже ловятся внутри; здесь
        // ещё страховка от исключений. Возвращает успех (для стопа сьюта/RUN ALL).
        bool RunStepTracked(ScriptStep step)
        {
            bool ok;
            try
            {
                ok = RunStep(step, runner, state, values);
            }
            catch (Exception ex)
            {
                Ui.Line($"[X] step crashed: {ex.Message}", ConsoleColor.Red);
                ok = false;
            }
            if (ok) status.MarkOk(step.Id); else status.MarkFailed(step.Id);
            return ok;
        }
    }

    // Exit code check-скрипта «уже сделано»: основной НЕ запускаем, степ зелёный.
    private const int CheckAlreadyDone = 2;

    // Шаг = check (опционально) + основной скрипт. Трёхзначная семантика check:
    //   exit 0  -> можно/нужно делать: запускаем основной.
    //   exit 2  -> уже сделано: основной НЕ нужен, степ зелёный.
    //   иначе   -> нельзя/ошибка: стоп, красный.
    // Возвращает true при «уже сделано» или успехе основного (exit 0).
    private static bool RunStep(ScriptStep step, ScriptRunner runner, StateStore state, IDictionary<string, string> values)
    {
        if (step.CheckPath is null)
        {
            Ui.Line("script without checks", ConsoleColor.DarkGray);
        }
        else
        {
            var check = Execute(step.CheckPath, runner, state, values);
            if (check.Found && check.ExitCode == CheckAlreadyDone)
            {
                Ui.Line($"[OK] already done — skipping {step.Name}.", ConsoleColor.Green);
                return true;
            }
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

        // Вывод стримится сюда построчно во время работы скрипта: stdout как есть,
        // stderr — красным. Так длинный шаг (DISM) виден сразу, а не в конце.
        var result = runner.Run(
            scriptPath,
            onStdout: line => Ui.Plain(line),
            onStderr: line => Ui.Line(line, ConsoleColor.Red));

        if (result.Error is not null)
        {
            Ui.Line($"[X] {result.Error}", ConsoleColor.Red);
            return result;
        }

        state.Apply(result.Sets, values);
        foreach (var (key, value) in result.Sets)
            Ui.Line($"  state: {key} = {value}", ConsoleColor.DarkGray);

        return result;
    }

    // Читает шаблон unattend, интерполирует @@@@ значениями из конфига и пишет
    // рабочий xml в paths.unattendXml. Нет шаблона/выхода — тихо пропускаем.
    private static void RenderUnattend(AppConfig config, IReadOnlyDictionary<string, string> values)
    {
        var template = config.Paths.UnattendTemplate;
        var output = config.Paths.UnattendXml;
        if (string.IsNullOrEmpty(template) || string.IsNullOrEmpty(output) || !File.Exists(template))
            return;

        var rendered = ConfigInterpolator.Interpolate(File.ReadAllText(template), values);
        Directory.CreateDirectory(Path.GetDirectoryName(output)!);
        File.WriteAllText(output, rendered);
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

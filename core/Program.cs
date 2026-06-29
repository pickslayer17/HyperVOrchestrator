namespace Orchestrator;

internal static class Program
{
    private static int Main()
    {
        var repoRoot = FindRepoRoot();
        var scriptsDir = Path.Combine(repoRoot, "scripts");
        var config = AppConfig.Load(repoRoot);

        var values = new Dictionary<string, string>(ConfigInterpolator.Flatten(config), StringComparer.OrdinalIgnoreCase);
        var state = new StateStore(config.Paths.StateFile);
        foreach (var kv in state.Values)
            values[kv.Key] = kv.Value;

        RenderUnattend(config, values);

        var runner = new ScriptRunner(values, repoRoot);
        var status = new SessionStatus();

        Console.CancelKeyPress += (_, e) =>
        {
            e.Cancel = true;
            runner.Cancel();
        };

        var suites = ScriptCatalog.Scan(scriptsDir)
            .GroupBy(s => s.Group)
            .Select(g => (g.Key, (IReadOnlyList<ScriptStep>)g.ToList()))
            .ToList();

        new Menu(suites, status, RunStepTracked).Run();
        return 0;

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

    private const int CheckAlreadyDone = 2;

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

    private static RunResult Execute(string scriptPath, ScriptRunner runner, StateStore state, IDictionary<string, string> values)
    {
        Ui.Blank();
        Ui.Line($"--- {Path.GetFileName(scriptPath)} ---", ConsoleColor.DarkGray);

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

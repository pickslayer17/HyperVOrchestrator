using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class Orchestrator
{
    private const int CheckRunMain = 0;
    private const int CheckAlreadyDone = 2;

    private readonly AppConfig _config;
    private readonly string _scriptsRoot;
    private readonly RunScriptManager _runManager;
    private readonly ScriptModel _model;
    private readonly ConsoleModelViewer _viewer;
    private readonly Logger _logger;
    private HostInfo _hostInfo = new();

    public Orchestrator(AppConfig config, string scriptsRoot, string vmSuitesDir)
    {
        _config = config;
        _scriptsRoot = scriptsRoot;
        _runManager = new RunScriptManager(config, scriptsRoot);
        var factory = new ScriptModelFactory();
        _model = factory.Create(vmSuitesDir);
        _viewer = new ConsoleModelViewer(this, _model);
        _logger = new Logger();
    }

    public void Start()
    {
        RunInitialization();
        _viewer.Draw();
    }

    private void RunInitialization()
    {
        var initRunManager = new RunScriptManager(_config, _scriptsRoot);
        var initializer = new Initializer(initRunManager);
        _hostInfo = initializer.Run(Console.WriteLine);
    }

    public void Run(IScriptNode node)
    {
        if (node is Step step)
            RunStep(step);
        else if (node is Suite suite)
            RunSuite(suite);

        _model.Root.Recalculate();
        _viewer.ResumeAfterRun();
    }

    // Returns false as soon as any step fails, so the whole run stops there.
    private bool RunSuite(Suite suite)
    {
        foreach (var step in suite.Steps)
        {
            if (!RunStep(step))
                return false;
        }
        foreach (var childSuite in suite.ChildSuites)
        {
            if (!RunSuite(childSuite))
                return false;
        }
        return true;
    }

    private bool RunStep(Step step)
    {
        if (!step.HasCheck)
        {
            var okNoCheck = RunMain(step);
            if (okNoCheck) step.State = StepState.NoCheck;
            return okNoCheck;
        }

        _logger.SetContext(step + "/check");
        WriteLine($"[CHECK {step}]");
        var checkResult = _runManager.ExecuteFileScript(step.CheckPath, WriteLine);
        if (checkResult.ExitCode == CheckAlreadyDone)
        {
            WriteLine($"[CHECK RESULT: already done — skipping main]");
            step.State = StepState.AlreadyDone;
            return true;
        }
        if (checkResult.ExitCode != CheckRunMain)
        {
            WriteLine($"[CHECK RESULT: failed (exit {checkResult.ExitCode}) — main not run]");
            step.State = StepState.Failed;
            return false;
        }

        WriteLine($"[CHECK RESULT: needs work — running main]");
        var ok = RunMain(step);
        return ok;
    }

    private bool RunMain(Step step)
    {
        _logger.SetContext(step + "/main");
        WriteLine($"[STEP {step}]");
        var result = _runManager.ExecuteFileScript(step.ScriptPath, WriteLine);
        if (result.ExitCode == 0)
        {
            step.State = StepState.Passed;
            return true;
        }
        step.State = StepState.Failed;
        return false;
    }

    private void WriteLine(string line)
    {
        _logger.Write(line);
        _viewer.WriteOutput(line);
    }
}

using Orchestrator.Config;
using Orchestrator.Core;
using Orchestrator.Models;

namespace Orchestrator.App;

internal sealed class Orchestrator
{
    private const int CheckRunMain = 0;
    private const int CheckAlreadyDone = 2;

    private readonly RunScriptManager _runManager;
    private readonly ScriptModel _model;
    private readonly ConsoleModelViewer _viewer;
    private readonly Logger _logger;

    public Orchestrator(AppConfig config, string repoRoot, string scriptsDir)
    {
        _runManager = new RunScriptManager(config, repoRoot);
        var factory = new ScriptModelFactory();
        _model = factory.Create(scriptsDir);
        _viewer = new ConsoleModelViewer(this, _model);
        _logger = new Logger(repoRoot);
    }

    public void Start()
    {
        _viewer.Draw();
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

    private void RunSuite(Suite suite)
    {
        foreach (var step in suite.Steps)
            RunStep(step);
        foreach (var childSuite in suite.ChildSuites)
            RunSuite(childSuite);
    }

    private void RunStep(Step step)
    {
        if (!step.HasCheck)
        {
            RunMain(step);
            step.State = StepState.NoCheck;
            return;
        }

        _logger.SetContext(step + "/check");
        var checkResult = _runManager.ExecuteFileScript(step.CheckPath, WriteLine);
        if (checkResult.ExitCode == CheckAlreadyDone)
        {
            step.State = StepState.AlreadyDone;
            return;
        }
        if (checkResult.ExitCode != CheckRunMain)
        {
            step.State = StepState.Failed;
            return;
        }

        RunMain(step);
    }

    private void RunMain(Step step)
    {
        _logger.SetContext(step + "/main");
        var result = _runManager.ExecuteFileScript(step.ScriptPath, WriteLine);
        if (result.ExitCode == 0)
            step.State = StepState.Passed;
        else
            step.State = StepState.Failed;
    }

    private void WriteLine(string line)
    {
        _logger.Write(line);
        _viewer.WriteOutput(line);
    }
}

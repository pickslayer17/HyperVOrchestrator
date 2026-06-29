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

    public Orchestrator(AppConfig config, string repoRoot, string scriptsDir)
    {
        _runManager = new RunScriptManager(config, repoRoot);
        var factory = new ScriptModelFactory();
        _model = factory.Create(scriptsDir);
        _viewer = new ConsoleModelViewer(this, _model);
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

        RecalculateStates(_model.Root);
        _viewer.Draw();
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
        var result = _runManager.ExecuteFileScript(step.ScriptPath, WriteLine);
        if (result.ExitCode == 0)
            step.State = StepState.Passed;
        else
            step.State = StepState.Failed;
    }

    private void RecalculateStates(Suite suite)
    {
        foreach (var childSuite in suite.ChildSuites)
            RecalculateStates(childSuite);

        var allDone = true;
        var anyFailed = false;
        var anyRun = false;

        foreach (var step in suite.Steps)
        {
            if (step.State == StepState.NotRun)
                allDone = false;
            if (step.State == StepState.Failed)
                anyFailed = true;
            if (step.State != StepState.NotRun)
                anyRun = true;
        }
        foreach (var childSuite in suite.ChildSuites)
        {
            if (childSuite.State == StepState.NotRun)
                allDone = false;
            if (childSuite.State == StepState.Failed)
                anyFailed = true;
            if (childSuite.State != StepState.NotRun)
                anyRun = true;
        }

        suite.State = ResolveSuiteState(allDone, anyFailed, anyRun);
    }

    private StepState ResolveSuiteState(bool allDone, bool anyFailed, bool anyRun)
    {
        if (anyFailed)
            return StepState.Failed;
        if (!anyRun)
            return StepState.NotRun;
        if (allDone)
            return StepState.Passed;
        return StepState.NotRun;
    }

    private void WriteLine(string line)
    {
        _viewer.WriteOutput(line);
    }
}

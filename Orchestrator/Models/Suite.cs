namespace Orchestrator.Models;

internal sealed class Suite : IScriptNode
{
    public string Name { get; set; } = "";
    public Suite? Parent { get; set; }
    public List<Suite> ChildSuites { get; set; } = new List<Suite>();
    public List<Step> Steps { get; set; } = new List<Step>();
    public StepState State { get; set; } = StepState.NotRun;

    public void Recalculate()
    {
        foreach (var childSuite in ChildSuites)
            childSuite.Recalculate();

        var allDone = true;
        var anyFailed = false;
        var anyRun = false;

        foreach (var step in Steps)
        {
            if (step.State == StepState.NotRun)
                allDone = false;
            if (step.State == StepState.Failed)
                anyFailed = true;
            if (step.State != StepState.NotRun)
                anyRun = true;
        }
        foreach (var childSuite in ChildSuites)
        {
            if (childSuite.State == StepState.NotRun)
                allDone = false;
            if (childSuite.State == StepState.Failed)
                anyFailed = true;
            if (childSuite.State != StepState.NotRun)
                anyRun = true;
        }

        State = ResolveState(allDone, anyFailed, anyRun);
    }

    private static StepState ResolveState(bool allDone, bool anyFailed, bool anyRun)
    {
        if (anyFailed)
            return StepState.Failed;
        if (!anyRun)
            return StepState.NotRun;
        if (allDone)
            return StepState.Passed;
        return StepState.NotRun;
    }
}

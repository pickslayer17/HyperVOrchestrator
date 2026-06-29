namespace Orchestrator.Models;

internal sealed class Suite : IScriptNode
{
    public string Name { get; set; } = "";
    public Suite? Parent { get; set; }
    public List<Suite> ChildSuites { get; set; } = new List<Suite>();
    public List<Step> Steps { get; set; } = new List<Step>();
    public StepState State { get; set; } = StepState.NotRun;
}

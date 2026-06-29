namespace Orchestrator.Models;

internal sealed class Step : IScriptNode
{
    public string Name { get; set; } = "";
    public string ScriptPath { get; set; } = "";
    public string CheckPath { get; set; } = "";
    public bool HasCheck { get; set; }
    public StepState State { get; set; } = StepState.NotRun;
    public Suite? Parent { get; set; }
}

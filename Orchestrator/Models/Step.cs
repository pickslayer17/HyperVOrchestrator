namespace Orchestrator.Models;

internal sealed class Step : IScriptNode
{
    public string Name { get; set; } = "";
    public string ScriptPath { get; set; } = "";
    public string CheckPath { get; set; } = "";
    public bool HasCheck { get; set; }
    public StepState State { get; set; } = StepState.NotRun;
    public Suite? Parent { get; set; }

    public override string ToString()
    {
        var path = Name;
        var parent = Parent;
        while (parent is not null)
        {
            path = parent.Name + "/" + path;
            parent = parent.Parent;
        }
        var result = path;
        return result;
    }
}

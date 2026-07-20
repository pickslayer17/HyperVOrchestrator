namespace Orchestrator.FSModels;

public sealed class AgentFSModel
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public bool Running { get; set; }
}

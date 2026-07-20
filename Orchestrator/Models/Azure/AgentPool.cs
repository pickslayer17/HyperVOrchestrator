namespace Orchestrator.Models.Azure;

public class AgentPool
{
    public string Name;
    public List<Agent> Agents = new();
}

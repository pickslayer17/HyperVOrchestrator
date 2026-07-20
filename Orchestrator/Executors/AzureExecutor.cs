using System.Text.Json;
using Orchestrator.Core;
using Orchestrator.FSModels;

namespace Orchestrator.Executors;

public class AzureExecutor : BaseExecutor
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public AzureExecutor() : base(ExecutorTarget.Host)
    {
    }

    public List<AgentFSModel> GetPoolAgents(string poolName)
    {
        var output = Run("GetPoolAgents.ps1", new Dictionary<string, string> { ["PoolName"] = poolName });
        return JsonSerializer.Deserialize<List<AgentFSModel>>(output, JsonOptions) ?? new List<AgentFSModel>();
    }

    public AgentFSModel GetAgentInfo(string agentName)
    {
        var output = Run("GetAgentInfo.ps1", new Dictionary<string, string> { ["AgentName"] = agentName });
        return JsonSerializer.Deserialize<AgentFSModel>(output, JsonOptions) ?? new AgentFSModel();
    }

    public void RemoveAgent(string agentName)
    {
        Run("RemoveAgent.ps1", new Dictionary<string, string> { ["AgentName"] = agentName });
    }

    public void TurnOnOffAgent(string agentName, bool turnOff = true)
    {
        Run("TurnOnOffAgent.ps1", new Dictionary<string, string>
        {
            ["AgentName"] = agentName,
            ["TurnOff"] = turnOff.ToString(),
        });
    }

    private string Run(string scriptFile, IReadOnlyDictionary<string, string>? args = null)
    {
        return RunScript("AzureExecutor", scriptFile, args);
    }
}

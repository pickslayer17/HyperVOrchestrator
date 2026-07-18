using System.Text.Json;
using Orchestrator.Core;
using Orchestrator.FSModels;

namespace Orchestrator.Executors;

public class PythonExecutor : BaseExecutor
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    public PythonExecutor() : base(ExecutorTarget.Host)
    {
    }

    public ConnectionsFSModel GetAllConnections()
    {
        var output = Run("GetAllConnections.ps1");
        return JsonSerializer.Deserialize<ConnectionsFSModel>(output, JsonOptions) ?? new ConnectionsFSModel();
    }

    public bool IsAlive()
    {
        var output = Run("IsAlive.ps1");
        return output.Trim().Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public void Start()
    {
        Run("Start.ps1");
    }

    public void StartProxy(string ip, int port)
    {
        Run("StartProxy.ps1", new Dictionary<string, string>
        {
            ["Ip"] = ip,
            ["Port"] = port.ToString(),
        });
    }

    public void StartDns(string ip, int port)
    {
        Run("StartDns.ps1", new Dictionary<string, string>
        {
            ["Ip"] = ip,
            ["Port"] = port.ToString(),
        });
    }

    private string Run(string scriptFile, IReadOnlyDictionary<string, string>? args = null)
    {
        return RunScript("PythonExecutor", scriptFile, args);
    }
}

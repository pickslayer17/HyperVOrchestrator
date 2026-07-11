using System.Text.Json;
using Orchestrator.Core;
using Orchestrator.FSModels;

namespace Orchestrator.Executors;

public class PythonExecutor
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    internal RunScriptManager? RunManager;

    public bool GetProxyAlive()
    {
        var output = Run("GetProxyAlive.ps1");
        return output.Trim().Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public ConnectionsFSModel GetAllConnections()
    {
        var output = Run("GetAllConnections.ps1");
        return JsonSerializer.Deserialize<ConnectionsFSModel>(output, JsonOptions) ?? new ConnectionsFSModel();
    }

    public bool IsAlive()
    {
        //script
        return true;
    }

    public void Start()
    {
        //script
    }

    public void StartProxy(string ip, int port)
    {
        //script to python
    }

    public void StartForward(string bindIp, int listenPort, string targetIp, int targetPort)
    {
        //script to python
    }

    private string Run(string scriptFile)
    {
        RunManager!.StateKeeper.ExecutorTarget = "Host";
        var path = Path.Combine(Program.RepoRoot, "scripts", "_system", "PythonExecutor", scriptFile);
        return RunManager.ExecuteFileScript(path, _ => { }).Output;
    }
}

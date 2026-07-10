using Orchestrator.Executors;

namespace Orchestrator.Models.NetWorkModels;

public class PythonServer
{
    public PythonExecutor Python = new();
    public bool Alive { get; set; }
    public Dictionary<string, int> FwdIpdsAndPorts = new();
}

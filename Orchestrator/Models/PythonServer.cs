using Orchestrator.Executors;

namespace Orchestrator.Models;

public class PythonServer
{
    public PythonExecutor Python = new();
    public bool Alive { get; set; }
}

using Orchestrator.Executors;

namespace Orchestrator.Models;

public class VM
{
    public string Name;
    public bool Running;
    public string ProxyAddress;
    public NetInterface NatNetInterface;

    public NetExecutor NetExecutor = new();
}

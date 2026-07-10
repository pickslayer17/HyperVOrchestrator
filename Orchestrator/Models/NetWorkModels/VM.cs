using Orchestrator.Executors;

namespace Orchestrator.Models.NetWorkModels;

public class VM
{
    public string Name;
    public bool Running;
    public string ProxyAddress;
    public NetInterface NatNetInterface;

    public NetExecutor NetExecutor = new();
}

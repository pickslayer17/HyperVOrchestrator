using Orchestrator.Executors;

namespace Orchestrator.Models.NetWorkModels;

public class Host
{
    public string SwitchName;
    public List<VM> VMs = new();
    public NetExecutor NetExecutor;
    public HyperVExecutor HyperVExecutor;
    public PythonServer PythonServer = new();

    public NetInterface GlobalNetInterface;
    public NetInterface NatNetInterface;

    public Net NatNet;
}

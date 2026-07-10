using Orchestrator.Executors;

namespace Orchestrator.Models;

public class Host
{
    public string SwitchName;
    public List<VM> VMs = new();
    public NetExecutor NetExecutor = new();
    public PythonServer PythonServer = new();

    public Dictionary<string, int> FwdIpdsAndPorts = new();
    public NetInterface GlobalNetInterface;
    public NetInterface NatNetInterface;

    public Net NatNet;
}

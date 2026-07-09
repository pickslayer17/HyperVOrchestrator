using ConsoleApp1.Executors;

namespace ConsoleApp1.NetworkModel;

public class Host
{
    public List<VM> VMs = new();
    public PythonExecutor PythonExecutor = new();
    public NetExecutor NetExecutor = new();

    public Dictionary<string, int> FwdIpdsAndPorts = new();
    public NetInterface GlobalNetInterface;
    public NetInterface NatNetInterface;

    public Net NatNet;
}

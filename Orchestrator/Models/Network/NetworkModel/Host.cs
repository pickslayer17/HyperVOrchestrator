using ConsoleApp1.Executors;

namespace ConsoleApp1.NetworkModel;

public class Host
{
    public List<VM> VMs;
    public PythonExecutor PythonExecutor;
    public NetExecutor NetExecutor;

    public Dictionary<string, int> FwdIpdsAndPorts;
    public NetInterface GlobalNetInterface;
    public NetInterface NatNetInterface;
    
    public Net NatNet;
}

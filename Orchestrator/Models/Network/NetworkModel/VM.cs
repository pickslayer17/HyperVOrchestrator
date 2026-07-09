using ConsoleApp1.Executors;

namespace ConsoleApp1.NetworkModel;

public class VM
{
    public string Name;
    public string ProxyAddress;
    public NetInterface NatNetInterface;

    public NetExecutor NetExecutor = new();
}
